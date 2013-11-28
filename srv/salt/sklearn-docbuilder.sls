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

sklearn:
    user.present:
        - shell: /bin/bash
        - home: /home/sklearn

/home/sklearn/venv:
    virtualenv.managed:
        - python: /usr/bin/python
        - system_site_packages: True
        - distribute: True
        - user: sklearn
        - require:
            - user: sklearn
            - pkg: python-virtualenv

