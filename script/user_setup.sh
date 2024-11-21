#!/usr/bin/bash

# Configure aliases
cat files/shell/.bash_aliases >> ~/.bash_aliases
cat files/shell/.bashrc >> ~/.bashrc
# Source aliases for current session
. ~/.bash_aliases

# Install Miniconda
. utils/conda.sh
conda_install

mkdir ~/logs
