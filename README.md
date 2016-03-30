sklearn-docbuilder
==================

Script to configure a cloud server to build the documentation and example
gallery and update the [sklearn dev website](http://scikit-learn.org/dev).

This script is only meant to be used by scikit-learn project maintainers with
github and sourceforge write access.


Usage
-----

First install the script dependencies (preferably in a virtualenv):

    pip install -r requirements.txt

The following tools will be installed locally (NumPy, SciPy and scikit-learn
are **not** required locally, they will only be installed on the cloud server):

- Apache Libcloud is used to check the status and start a Rackspace cloud
  server dedicated to monitoring the master branch of the project and building
  the example gallery and the sphinx documentation.

- SaltStack (via the salt-ssh client) is used to automate the configuration of
  the server.

- Paramiko is a Python implementation of the SSH protocol used by SaltStack.

- Yaml is used to parse and generate SaltStack configuration files.

Ask one of the scikit-learn maintainers for the `docbuilder_rsa` private
key next to the `docbuilder_rsa.pub` public key in this folder.

Also ask for the Rackspace cloud credentials   and put them as enviroment
variables (possibly in your `~/.bashrc` file):

    export SKLEARN_RACKSPACE_NAME="sklearn"
    export SKLEARN_RACKSPACE_KEY="XXXXXXXXX"
    
Once you have the credentials, run the following script to check that the
Rackspace cloud server is running, start it if this not the case and fetch the
connection parameters (the IP address stored in `./etc/salt/roster`):

    python docbuilder.py

You can check that the server can by contacted by salt commands such
as:

    salt-ssh -c ./etc/salt docbuilder test.ping

To install all the scikit-learn build dependencies and install the cron job
use:

    salt-ssh -c ./etc/salt docbuilder state.highstate

If the server was freshly provisioned, the first execution of `state.highstate`
can take several minutes. Subsequent calls will be much faster. To display
debug info use:

    salt-ssh -c ./etc/salt docbuilder state.highstate -l debug


Changing the server configuration
---------------------------------

The Salt Stack configuration for the server and the script run by the cron job
to build the documentation once the server is ready can be found in the
[srv/salt](
https://github.com/scikit-learn/sklearn-docbuilder/tree/master/srv/salt)
subfolder.

To re-apply a configuration change in the configuration re-rerun:

    python docbuilder.py  # to fetch the IP of the docbuilder server
    salt-ssh -c ./etc/salt docbuilder state.highstate


Fixing execution errors in docbuilder.py
----------------------------------------

API change for Apache Libcloud are documented here:

    https://ci.apache.org/projects/libcloud/docs/upgrade_notes.html


Connecting to the server via SSH
--------------------------------

Run:

    python docbuilder.py

to fetch the IP address of the running server in `etc/salt/roster`. The output
of the command should display the ssh command, such as:

    ssh -i docbuilder_rsa root@<ip_address>


Changing the ssh keys
---------------------

If you suspect that the private keys have been compromised you can generate
a new keypair with:

    ssh-keygen -f docbuilder_rsa -N ''

Then commit the new public key and push it to github and send the private key by
email to the other scikit-learn maintainers and ask one of them to update the
authorized public key of the `sklearndocbuild` user profile on sourceforge.net.


Accessing the Rackspace Cloud management console
------------------------------------------------

Use rackspace credentials to list the running servers and terminate them if
needed at:

    https://mycloud.rackspace.com/a/sklearn/


Thanks
------

We would like to thank Rackspace for supporting the scikit-learn project by
giving a free Rackspace Cloud account.
