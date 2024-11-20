#!/usr/bin/bash

conda_install () {
  system=$(uname -s)
  architecture=$(uname -m)
  conda_dir=~/conda/conda
  conda_repo=https://repo.anaconda.com/miniconda
  conda_installer=$conda_repo/Miniconda3-latest-${system}-${architecture}.sh
  wget $conda_installer -O conda.sh
  sh conda.sh -b -p $conda_dir
  rm conda.sh
  $conda_dir/condabin/conda init
}

conda_build () {
  # Create conda environment from YAML definition file
  conda env create -f $2
  # Clean up unnecessary files
  conda clean -afy
  # Install `conda-pack` in the base environment
  conda activate base
  conda install -c conda-forge conda-pack
  conda pack -n $1 -o $1.tar.gz
}

conda_setup () {
  # Resolve environment package & directory
  [[ -z "${ENVDIR+x}" ]] && ENVDIR=$ENVNAME
  [[ -z "${ENVTAR+x}" ]] && ENVTAR=$ENVNAME.tar.gz
  # Resolve environment source directory
  [[ -z "${SOURCE_DIR+x}"  ]] && SOURCE_DIR=$STAGING/source/environment
  # Copy over Miniconda/Python environment
  cp $SOURCE_DIR/$ENVTAR ./
  # Unpack environment files
  mkdir $ENVDIR
  tar -xzf $ENVTAR -C $ENVDIR
  rm $ENVTAR
  # Update system path
  export PATH=$(pwd)/$ENVDIR:$(pwd)/$ENVDIR/lib:$(pwd)/$ENVDIR/share:$PATH
  # Activate the conda environment
  . $ENVDIR/bin/activate
}

conda_reboot () {
  # Deactivate conda environment
  . $ENVDIR/bin/deactivate
  # Remove environment files
  rm -r $ENVDIR
  # Reset PATH environment variable
  PATH=$(getconf PATH)
  # Reinitialize conda environment
  conda_setup
}
