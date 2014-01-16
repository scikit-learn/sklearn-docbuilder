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
            - make

sklearn:
    user.present:
        - shell: /bin/bash
        - home: /home/sklearn

/home/sklearn/.ssh:
    file.directory:
        - user: sklearn
        - group: sklearn
        - mode: 755
        - makedirs: True
        - require:
            - user: sklearn

/home/sklearn/.ssh/id_rsa:
    file.managed:
        - user: sklearn
        - group: sklearn
        - mode: 600
        - source: salt://docbuilder_rsa
        - require:
            - file: /home/sklearn/.ssh

/home/sklearn/.ssh/id_rsa.pub:
    file.managed:
        - user: sklearn
        - group: sklearn
        - source: salt://docbuilder_rsa.pub
        - require:
            - file: /home/sklearn/.ssh

/home/sklearn/venv:
    virtualenv.managed:
        - python: /usr/bin/python
        - system_site_packages: True
        - distribute: True
        - user: sklearn
        - require:
            - user: sklearn
            - pkg: python-virtualenv
    pip.installed:
        - names:
            - sphinx
            - coverage
            - nose
            - ipython
        - bin_env: /home/sklearn/venv
        - user: sklearn

sklearn-git-repo:
    git.latest:
        - name: https://github.com/scikit-learn/scikit-learn.git
        - rev: master
        - target: /home/sklearn/scikit-learn/
        - user: sklearn
        - require:
            - user: sklearn

build-sklearn:
    cmd.run:
        - name: /home/sklearn/venv/bin/python setup.py develop
        - cwd: /home/sklearn/scikit-learn/
        - user: sklearn
        - require:
            - git: sklearn-git-repo

build-doc:
    cmd.run:
        - name: source /home/sklearn/venv/bin/activate && make html
        - cwd: /home/sklearn/scikit-learn/doc
        - user: sklearn
        - require:
            - cmd: build-sklearn
