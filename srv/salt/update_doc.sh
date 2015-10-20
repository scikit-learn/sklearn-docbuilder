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
rev=$(git rev-parse --short HEAD)

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
if [[ "$1" = "clean" ]];
then
  make optipng
fi

test -f _build/html/stable/index.html

echo "Copying documentation to scikit-learn.github.io/dev/"
if [ -d $HOME/scikit-learn.github.io ]
then
  cd $HOME/scikit-learn.github.io
else
  cd $HOME
  git clone git@github.com:scikit-learn/scikit-learn.github.io.git
  cd scikit-learn.github.io
fi
git checkout master
git reset --hard origin/master
git rm -rf dev/ && rm -rf dev/
cp -R $HOME/scikit-learn/doc/_build/html/stable dev
git add -f dev/
git commit -m "Rebuild dev docs at master=$rev" dev
git push
