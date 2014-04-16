#!/usr/bin/env bash
# Incremental update and upload of the dev documentation.
# This script is meant to be run regularly in a cron job

# Early return on error
set -e

# Timestamp the log
echo `date`

# Activate the virtualenv for Python libraries
echo "Activating virtualenv"
source $HOME/venv/bin/activate
cd $HOME/scikit-learn

# Clean update of the source folder
echo "Fetching source from github"
git fetch origin
git reset --hard origin/master

# Compile source code
echo "Building scikit-learn"
if [[ "$1" = "clean" ]];
then
  make clean
fi

python setup.py develop

# Compile doc and run example to populate the gallery
echo "Building examples and documentation"
cd doc
if [[ "$1" = "clean" ]];
then
  make clean
fi
sphinx-build -b html -d _build/doctrees . _build/html/stable

# Upload to sourceforge using rsync
if [ -f _build/html/stable/index.html ];
then
  echo "Uploading to documentation http://scikit-learn.org/dev"
  rsync -e 'ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no'\
        -rltvz --delete _build/html/stable/ \
        sklearndocbuild,scikit-learn@web.sourceforge.net:htdocs/dev/
  echo "http://scikit-learn.org/dev successfully updated!"
else
  echo "Failed to generate the documentation."
  exit 1
fi
