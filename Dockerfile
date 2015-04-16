FROM ubuntu:14.04
MAINTAINER Sylvain Bellemare <sbellem@gmail.com>
RUN apt-get update
RUN apt-get upgrade -y

RUN apt-get install -y build-essential python python-dev python-pip 
RUN apt-get install -y git python-git

RUN DEBIAN_FRONTEND=noninteractive apt-get install -y make optipng vim

# Required for building a more recent matplotlib from source
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y libfreetype6-dev libpng12-dev pkg-config

# Latex packages for math expressions in sphinx
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y latex209-base texlive-latex-extra dvipng

# Linear Algebra routines
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y libatlas-dev libatlas3gf-base

# for scipy
RUN apt-get install -y libblas-dev liblapack-dev gfortran


RUN pip install virtualenv            

RUN useradd -ms /bin/bash sklearn

USER sklearn
WORKDIR /home/sklearn

RUN mkdir public_html

RUN git clone https://github.com/scikit-learn/scikit-learn.git

RUN virtualenv venv

RUN venv/bin/pip install --upgrade pip    
RUN venv/bin/pip install sphinx coverage nose ipython matplotlib scipy
