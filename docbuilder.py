import os
import sys, getopt
import yaml

from libcloud.compute.providers import get_driver
from libcloud.compute.deployment import SSHKeyDeployment


SKLEARN_RACKSPACE_NAME = os.environ.get("SKLEARN_RACKSPACE_NAME")
SKLEARN_RACKSPACE_KEY = os.environ.get("SKLEARN_RACKSPACE_KEY")
IMAGE_NAME = 'Ubuntu 12.04 LTS'
NODE_NAME = 'docbuilder'
DEFAULT_NODE_SIZE = 2048
PUB_KEY_PATH = 'docbuilder_rsa.pub'

def print_usage(machine_sizes):
    print 'USAGE: python docbuilder.py [machine_size]'
    print 'Regarding `machine_size` (optional):'
    print 'Please select one of the following:'
    print machine_sizes

def gen_salt_roster(host_ip=None):
    salt_roster = """
        %s:
            host: %s
            user: root
            priv: docbuilder_rsa
    """ % (NODE_NAME, host_ip[0])
    output_stream = open("etc/salt/roster", "w")
    yaml.dump(yaml.load(salt_roster), output_stream, default_flow_style=False)
    output_stream.close()

def r_status(server_state):
    if server_state == 0:
        status = "READY"
    else:
        status = "BUSY- (waiting for active status)"
    return status

def wait_for_active_status(server_status, connect):
    # Wait for active server status
    wait_id = 0
    wait_li = ['.  ', '.. ', '...']
    while server_status != 0:
        s_node_list = connect.list_nodes()
        s_node = [n for n in s_node_list if n.name == NODE_NAME][0]
        server_status = s_node.state
        wait_id = (wait_id + 1) % len(wait_li)
        if server_status == 0:
            state_str = "\nREADY"
        else:
            state_str = "BUSY- (waiting for active status)"
        sys.stdout.write("\r%s%s" %
                         (state_str, wait_li[wait_id]))
        sys.stdout.flush()

    sys.stdout.write("\n\nServer is now active\n\n")
    return server_status


def main(argv):
    # Make a connection through the rackspace driver to the sklearn space
    conn_sklearn = get_driver('rackspace')(SKLEARN_RACKSPACE_NAME,
                                           SKLEARN_RACKSPACE_KEY)

    # Obtain list of nodes
    s_node_list = conn_sklearn.list_nodes()
    # Obtain list of machine sizes
    machine_sizes = [n.ram for n in conn_sklearn.list_sizes()]
    selected_ram = 0
    server_status = 3 # assume busy

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
    if not any(n.name == NODE_NAME for n in s_node_list):
        print 'The docbuilder node does not exist yet - creating node...'
        print '  -  Configuring node size'
        if selected_ram == 0:
            print '    --   No node size provided: using default size of 2GB'
            s_node_size = [i for i in conn_sklearn.list_sizes() if i.ram == DEFAULT_NODE_SIZE][0]
        else:
            print '    --   Node size set to: ', selected_ram
            s_node_size = [i for i in conn_sklearn.list_sizes() if i.ram == selected_ram][0]
        print '  -   Configuring the builder image to ', IMAGE_NAME
        s_node_image = [i for i in conn_sklearn.list_images() if i.name == IMAGE_NAME][0]
        # Create a new node if non exists
        with open(PUB_KEY_PATH) as fp:
            pub_key_content = fp.read()
        step = SSHKeyDeployment(pub_key_content)
        print "  -  Starting node deployment - This may take a few minutes"
        print "     WARNING: Please do not interrupt the process"
        s_node = conn_sklearn.deploy_node(name=NODE_NAME, image=s_node_image,
                                          size=s_node_size, deploy=step)
        print '  -   Node created: ', NODE_NAME
    else:
        s_node = [n for n in s_node_list if n.name == NODE_NAME][0]
        print 'Node \'', NODE_NAME, '\' found'
        print '  -   Gathering information'


    print 80 * '-'
    print s_node
    print 80 * '-'

    gen_salt_roster(host_ip=s_node.public_ip)

    salt_master = open("etc/salt/master", "w")
    salt_master.write("root_dir: %s" % os.getcwd())

    print '\nChecking if the server is active'
    server_status = wait_for_active_status(server_status, conn_sklearn)

if __name__ == "__main__":
   main(sys.argv[1:])




