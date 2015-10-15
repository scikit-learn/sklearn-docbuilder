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
            - python-pip
            - python-coverage
            - python-nose
            - ipython
            - make
            - optipng

            # Required for building a more recent matplotlib from source
            - libfreetype6-dev
            - libpng12-dev

            # Latex packages for math expressions in sphinx
            - latex209-base
            - texlive-latex-extra
            - dvipng

            # Linear Algebra routines
            - libatlas-dev
            - libatlas3gf-base

sklearn:
    user.present:
        - shell: /bin/bash
        - home: /home/sklearn

/home/sklearn/public_html:
    file.directory:
        - user: sklearn
        - group: sklearn
        - mode: 755
        - makedirs: True
        - require:
            - user: sklearn

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

/home/sklearn/.ssh/config:
    file.managed:
        - user: sklearn
        - group: sklearn
        - source: salt://ssh_config
        - require:
            - user: sklearn
            - file: /home/sklearn/.ssh


# Install a recent version of virtualenv with pip
# before creating the virtual environment itself.
# This is required as the version of virtualenv shipped
# by the python-virtualenv package is too old and
# has a bug that prevents it to upgrade setuptools to
# a version recent-enough for matplotlib to install
# correctly
# Note that we use a `cmd.run` state instead of a
# `pip.installed` state to work around a bug in salt:
# https://github.com/saltstack/salt/issues/21845
install-virtualenv:
    cmd.run:
        - name: pip install -q virtualenv
        - unless: test -f /home/sklearn/venv


/home/sklearn/venv:
    virtualenv.managed:
        - python: /usr/bin/python
        - system_site_packages: True
        - user: sklearn
        - require:
            - user: sklearn
            - cmd: install-virtualenv
    pip.installed:
        - names:
            - sphinx == 1.2.3
            - coverage
            - nose
            - ipython
            - matplotlib
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


# Upload a bash script that builds the doc and upload the doc on
# http://scikit-learn.org/dev 
/home/sklearn/update_doc.sh:
    file.managed:
        - user: sklearn
        - group: sklearn
        - source: salt://update_doc.sh
        - require:
            - user: sklearn


# Upload git configuration to be able to commit to the
# scikit-learn.github.io repo
/home/sklearn/.gitconfig:
    file.managed:
        - user: sklearn
        - group: sklearn
        - source: salt://gitconfig
        - require:
            - user: sklearn


# Register the execution of the script in a cron job
update-doc-cron-job:
  cron.present:
    - name: bash /home/sklearn/update_doc.sh
                 > /home/sklearn/public_html/update_doc.log 2>&1
    - user: sklearn
    - minute: 2
    - hour: '*/1'
    - require:
        - git: sklearn-git-repo
        - file: /home/sklearn/update_doc.sh
        - file: /home/sklearn/public_html
        - file: /home/sklearn/.gitconfig


# Once in a while build the doc from a clean folder
update-doc-clean-cron-job:
  cron.present:
    - name: bash /home/sklearn/update_doc.sh clean
                 > /home/sklearn/public_html/update_doc_clean.log 2>&1
    - user: sklearn
    - minute: 32
    - hour: 2
    - require:
        - git: sklearn-git-repo
        - file: /home/sklearn/update_doc.sh
        - file: /home/sklearn/public_html
        - file: /home/sklearn/.gitconfig
        - file: /home/sklearn/.ssh/config
        - file: /home/sklearn/.ssh/id_rsa
