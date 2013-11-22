sklearn-docbuilder
==================

Script to configure a cloud server to build the documentation and plots and
update the sklearn website.

This script is only meant to be used by scikit-learn project maintainers with
github and sourceforge write access.


Usage
-----

- Install Apache Libcloud, SaltStack 0.17.2 or later and paramiko
  (preferably in a virtualenv):

    pip install salt paramiko apache-libcloud

  Apache Libcloud is used to check the status and start a Rackspace cloud
  server dedicated to monitoring the master branch of the project and building
  the figures and the sphinx documentation.

  SaltStack (via the salt-ssh client) is used to automate the configuration of
  the server.

  Paramiko is an Python implementation of the SSH protocol used by SaltStack.

- Ask one of the scikit-learn developers for the `docbuilder_rsa` private key
  next to the `docbuilder_rsa.pub` public key in this folder.

- Then run:

    python docbuilder.py


You can check that the server is up by running interactive salt commands such
as:

    salt-ssh -c ./salt "*" test.ping


Changing the ssh keys
---------------------

If you suspect that the private keys have been compromised you can generate
a new keypair with:

    ssh-keygen -f docbuilder_rsa -N ''

Then commit the new public and push it to github and send the private key by
email to the other scikit-learn maintainers.


Thanks
------

We would like to thank Rackspace for supporting the scikit-learn project by
giving a free Rackspace Cloud account.
