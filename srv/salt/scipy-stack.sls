scipy-stack-packages:
    pkg:
        - installed
        - names:
            # Salt optional stuff
            - git
            - vim
            - python-git
            - python-numpy
            - python-scipy
            - python-matplotlib
            - python-pip
            - python-coverage
            - python-virtualenv
            - python-nose
            - ipython

/home/ubuntu/venvs:
    file.directory:
        - makedirs: True
        - user: ubuntu


/home/ubuntu/venvs/venv2:
    virtualenv.managed:
        - python: python
        - system_site_packages: True
        - ignore_installed: True
        - distribute: True
        - runas: ubuntu
        - require:
            - file: /home/ubuntu/venvs
            - pkg: python-virtualenv

