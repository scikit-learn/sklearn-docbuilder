from __future__ import print_function
import os
import sys
import getopt
import yaml

from libcloud.compute.providers import get_driver
from libcloud.compute.deployment import SSHKeyDeployment

# Environment variables to lookup rackspace credentials
SKLEARN_RACKSPACE_NAME = "SKLEARN_RACKSPACE_NAME"
SKLEARN_RACKSPACE_KEY = "SKLEARN_RACKSPACE_KEY"
RACKSPACE_DRIVER = "rackspace"
REGION = "ord"

IMAGE_NAME = 'Ubuntu 12.04 LTS (Precise Pangolin) (PVHVM)'
NODE_NAME = 'docbuilder'
DEFAULT_NODE_SIZE = 2048
PUBLIC_KEY_PATH = 'docbuilder_rsa.pub'
PRIVATE_KEY_PATH = 'docbuilder_rsa'
TIMEOUT = 5000

MASTER_TEMPLATE = """\
root_dir: {root_dir}

fileserver_backend:
  - roots

file_roots:
  base:
    - {root_dir}/srv/salt
"""


def print_usage(machine_sizes):
    print('USAGE: python docbuilder.py [machine_size]')
    print('Regarding `machine_size` (optional):')
    print('Please select one of the following:')
    print(machine_sizes)


def gen_salt_roster(host_ips=None):
    # XXX: cannot connect to host with the IPv6 public address
    ipv4 = [ip for ip in host_ips if not ":" in ip][0]
    salt_roster = """\
%s:
    host: %s
    user: root
    priv: %s
""" % (NODE_NAME, ipv4, PRIVATE_KEY_PATH)
    output_stream = open("etc/salt/roster", "w")
    yaml.dump(yaml.load(salt_roster), output_stream, default_flow_style=False)
    output_stream.close()
    return ipv4


def wait_for_active_status(server_status, connect):
    # Wait for active server status
    wait_id = 0
    wait_li = ['.  ', '.. ', '...']
    while server_status != 0:
        existing_nodes = connect.list_nodes()
        s_node = [n for n in existing_nodes if n.name == NODE_NAME][0]
        server_status = s_node.state
        wait_id = (wait_id + 1) % len(wait_li)
        if server_status == 0:
            state_str = "READY"
        else:
            state_str = "BUSY - (waiting for active status)"
        sys.stdout.write("\r%s%s" %
                         (state_str, wait_li[wait_id]))
        sys.stdout.flush()

    sys.stdout.write("\nServer is now active\n")
    return server_status


def main(argv):
    # Make a connection through the rackspace driver to the sklearn space

    name = os.environ.get(SKLEARN_RACKSPACE_NAME)
    key = os.environ.get(SKLEARN_RACKSPACE_KEY)
    if name is None or key is None:
        raise RuntimeError(
            "Please set credentials as enviroment variables "
            " {} and {}".format(SKLEARN_RACKSPACE_NAME, SKLEARN_RACKSPACE_KEY))
    conn_sklearn = get_driver(RACKSPACE_DRIVER)(name, key, region=REGION)

    # Obtain list of nodes
    existing_nodes = conn_sklearn.list_nodes()
    node_list = "\n".join("  - " + n.name for n in existing_nodes)
    print("Found %d existing node(s) with names:\n%s" % (
        len(existing_nodes), node_list))

    # Obtain list of machine sizes
    machine_sizes = [n.ram for n in conn_sklearn.list_sizes()]
    selected_ram = None
    server_status = 3  # assume busy

    try:
        opts, args = getopt.getopt(argv, "h")
        for opt, arg in opts:
            if opt == '-h':
                print_usage(machine_sizes)
                sys.exit()
        if args:
            if int(args[0]) not in machine_sizes:
                print_usage(machine_sizes)
                sys.exit()
            else:
                selected_ram = int(args[0])
    except getopt.GetoptError:
        print_usage(machine_sizes)
        sys.exit(2)

    # Check if our desired node already exists
    if not any(n.name == NODE_NAME for n in existing_nodes):
        print('The docbuilder node does not exist yet - creating node...')
        print('  -  Configuring node size')
        if selected_ram is None:
            print('    --   No node size provided: using default size of 2GB')
            size = [i for i in conn_sklearn.list_sizes()
                      if i.ram == DEFAULT_NODE_SIZE][0]
        else:
            print('    --   Node size set to: ', selected_ram)
            size = [i for i in conn_sklearn.list_sizes()
                      if i.ram >= selected_ram][0]

        print('  -   Configuring the builder image to', IMAGE_NAME)
        images = conn_sklearn.list_images()
        matching_images = [i for i in images if i.name == IMAGE_NAME]
        if len(matching_images) == 0:
            image_names = "\n".join(sorted(i.name for i in images))
            raise RuntimeError("Could not find image with name %s,"
                               " available images:\n%s"
                               % (IMAGE_NAME, image_names))
        s_node_image = matching_images[0]

        # Create a new node if non exists
        with open(PUBLIC_KEY_PATH) as fp:
            pub_key_content = fp.read()
        step = SSHKeyDeployment(pub_key_content)
        print("Starting node deployment - This may take a few minutes")
        print("WARNING: Please do not interrupt the process")
        node = conn_sklearn.deploy_node(name=NODE_NAME, image=s_node_image,
                                        size=size, deploy=step,
                                        timeout=TIMEOUT, ssh_timeout=TIMEOUT)
        print('Node successfully provisioned: ', NODE_NAME)
    else:
        node = [n for n in existing_nodes if n.name == NODE_NAME][0]
        print("Node '%s' found" % NODE_NAME)
        print('Gathering connection information')

    if not os.path.exists('etc/salt'):
        os.makedirs('etc/salt')

    print("Storing connection information to etc/salt/roster")
    ip = gen_salt_roster(host_ips=node.public_ips)

    print("Configuring etc/salt/master")
    salt_master = open("etc/salt/master", "w")
    here = os.getcwd()
    salt_master.write(MASTER_TEMPLATE.format(root_dir=here))

    print('Checking if the server is active:')
    server_status = wait_for_active_status(server_status, conn_sklearn)

    # Making sure the private key has the right permissions to be useable by
    # paramiko
    os.chmod('docbuilder_rsa', 0o600)

    print("SSH connection command:")
    print("  ssh -i %s root@%s" % (PRIVATE_KEY_PATH, ip))

    # TODO: find a way to launch the state.highstate command via salt-ssh
    print("You can now configure the server with (can take several minutes):")
    print("  salt-ssh -i -c ./etc/salt docbuilder state.highstate")


if __name__ == "__main__":
    main(sys.argv[1:])
