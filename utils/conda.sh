#!/usr/bin/bash

function conda_setup() {

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

function conda_reboot () {
  . $ENVDIR/bin/deactivate
  rm -r $ENVDIR
  cp $STAGING/source/environment/$ENVNAME.tar.gz ./
  mkdir $ENVDIR
}
