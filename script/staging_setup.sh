#!/usr/bin/bash

USER=$(id -u -n)
GROUP=townsend_airborne

# Farnsworth mount point on Krusty
FARNSWORTH=/mnt/farnsworth/Enspec
# Shared space on CHTC Staging
STAGING=/staging/groups/$GROUP
# CHTC Transfer server
TRANSFER=transfer.chtc.wisc.edu
# SCP remote path to Staging
REMOTE=$USER@$TRANSFER:$STAGING

# Create directory structure
mkdir -p $STAGING/{config,joblist}
mkdir -p $STAGING/data/{atmosphere,basemap,geometry,processed,quicklook,raw,surface}
mkdir -p $STAGING/source/{environment,packages}

# # Copy atmospheric lookup tables
# cp -r atmosphere ...
# scp -r $FARNSWORTH/library/atmosphere/libradtran/midlatitude_summer $USER@$TRANSFER:$STAGING/data/atmosphere/midlatitude_summer

# # Copy Python environment
...
# # Copy HyPro package
...

DEM_DIRECTORY=$FARNSWORTH/library/sites/SurfaceModels/hyspex_dems
DATA_DIRECTORY=$FARNSWORTH/users/bheberlein/processing/fen-new/data/FEN-SYENE-RD_20180629/FEN-SYENE-RD_20180629_01

scp -r $DEM_DIRECTORY/* $REMOTE/data/surface/
scp -r $DEM_DIRECTORY/Dane_County_WI_DEM $REMOTE/data/surface/
scp -r $DEM_DIRECTORY/Menominee $REMOTE/data/surface/

scp $FARNSWORTH/users/bheberlein/hypro_1.0.1dev*.tar.gz $REMOTE/source/packages
scp $FARNSWORTH/users/bheberlein/chtc/htconda-new.tar.gz $REMOTE/source/environment

scp -r $DATA_DIRECTORY $REMOTE/data/test
