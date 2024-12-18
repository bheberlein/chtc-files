#!/usr/bin/bash

# Update Bash configuration
cat files/shell/.bashrc >> ~/.bashrc

# Install Miniconda
. utils/conda.sh
conda_install

# Import HTCondor utilities
. utils/htcondor.sh

mkdir ~/logs
