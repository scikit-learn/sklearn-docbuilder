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

# Upload a bash script that builds the doc and upload the doc on
# http://scikit-learn.org/dev 
/home/sklearn/update_doc.sh:
    file.managed:
        - user: sklearn
        - group: sklearn
        - source: salt://update_doc.sh
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
