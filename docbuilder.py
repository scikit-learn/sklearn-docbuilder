import os
from libcloud.compute.providers import get_driver

# TODO from os env
SKLEARN_RACKSPACE_NAME = os.environ.get("SKLEARN_RACKSPACE_NAME")
SKLEARN_RACKSPACE_KEY = os.environ.get("SKLEARN_RACKSPACE_KEY")
IMAGE_NAME = 'Ubuntu 12.04 LTS'
NODE_NAME = 'docbuilder'

# Make a connection through the rackspace driver to the sklearn space
conn_sklearn = get_driver('rackspace')(SKLEARN_RACKSPACE_NAME, SKLEARN_RACKSPACE_KEY)

# Obtain list of nodes
s_node_list = conn_sklearn.list_nodes()

# Check if our desired node already exists
if not any(n.name == NODE_NAME for n in s_node_list):
    # Obtain node size - smallest one for now
    s_node_size = conn_sklearn.list_sizes()[0]
    # Choose the correct image for the builder
    s_node_image = [i for i in conn_sklearn.list_images() if i.name == IMAGE_NAME][0]
    # Create a new node if non exists
    s_node = conn_sklearn.create_node(name=NODE_NAME, image=s_node_image, size=s_node_size)
else:
    s_node = [n for n in s_node_list if n.name == NODE_NAME][0]

print s_node
print s_node.public_ip
print s_node.state
