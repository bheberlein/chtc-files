#!/usr/bin/bash

# :---------- DEFINE VARIABLES ----------: #

# User
CHTC_USER=$(id -u -n)
# File storage
USER_STAGING=/staging/$CHTC_USER
GROUP_STAGING=/staging/groups/townsend_hyspex
STAGING=$GROUP_STAGING
# Resource directories
SOURCE_DIR=$STAGING/source/environment
PACKAGE_DIR=$STAGING/source/packages
# Python environment
ENVNAME=htconda
ENVDIR=$ENVNAME
# Packages
ENVTAR=$ENVNAME-new.tar.gz
HYPROTAR=hypro_1.0.1dev2.tar.gz

# :--------- SET UP ENVIRONMENT ---------: #

# Set up Conda/Python environment
source utils/conda.sh
conda_setup

# Get Python major & minor version number
PYTHON_VERSION=$(python -c 'import sys; print(".".join(map(str, sys.version_info[:2])))')
# Until HyPro is properly installed in the Conda environment, we need to add it to `conda.pth`
echo $(pwd)/hypro/src > $ENVDIR/lib/python${PYTHON_VERSION}/site-packages/conda.pth

# :---------- PROCESSING SETUP ----------: #

# Resolve job variables (NAME, ISODATE, LINE, SESSION, FLIGHTLINE)
source utils/variables.sh
resolve_variables "$@"

# Copy over HyPro source files & unpack
cp $PACKAGE_DIR/$HYPROTAR .
mkdir hypro
source utils/archive.sh
unpack $HYPROTAR -C hypro

# NOTE: Currently, code is structured as
#  hypro/
#  +-- data/
#  +-- src/
#      +-- hypro/

# Set up directories for raw & processed data
mkdir data output

# Look for raw data inputs
RAW_INPUT=$(find $STAGING/data/raw/$SESSION -name "$FLIGHTLINE.*" -print -quit)
if [ ! -f ${RAW_INPUT} ]; then echo "Raw inputs not found!"; exit 1; fi
# Copy over input data
cp $RAW_INPUT data/ && unpack data/"${RAW_INPUT##*/}" -C data

# Resolve processing configuration file
source utils/config.sh
resolve_config
# Copy over JSON configuration file (strip out leading directories if present)
cp $CONFIG_DIR/$CONFIG data/"${CONFIG##*/}"

# :----------- RUN PROCESSING -----------: #

# Run HyPro reflectance processing
python hypro/src/hypro/workflow/main.py data/$CONFIG

# :----------- PACK UP OUTPUTS ----------: #

mkdir $FLIGHTLINE
mkdir $FLIGHTLINE/{VNIR,SWIR}

# Processing log
mv output/*.log $FLIGHTLINE/

# Merged reflectance imagery & ancillary datasets
mv output/$FLIGHTLINE/merge/* $FLIGHTLINE/
# # Remove single-sensor datasets
# rm $FLIGHTLINE/${FLIGHTLINE}_{VNIR,SWIR}_*
# Ancillary datasets
mv $FLIGHTLINE/ancillary/* $FLIGHTLINE/
rm -d $FLIGHTLINE/ancillary

# BASICALLY EVERYTHING EXCEPT AvgRdn, DataMask, DEM, GLT, ProcessedNavData, Singleband

# # Raw radiance imagery & calibration coefficients
# mv output/$FLIGHTLINE/*/${FLIGHTLINE}_*_{Raw,Resampled}Rdn{,.hdr} $FLIGHTLINE/
# mv output/$FLIGHTLINE/*/${FLIGHTLINE}_*_RadioCaliCoeff{,.hdr} $FLIGHTLINE/
# # Saturation quality control metrics
# mv output/$FLIGHTLINE/*/${FLIGHTLINE}_*_Saturation{Mask,PercentBands,PercentValue}{,.hdr} $FLIGHTLINE/
# Smile effect data
mv output/$FLIGHTLINE/*/${FLIGHTLINE}_*_SmileEffect{,AtAtmFeatures}{,.hdr} $FLIGHTLINE/
# Water vapor model
mv output/$FLIGHTLINE/*/${FLIGHTLINE}_*_WVCModel.json $FLIGHTLINE/
# Unmerged image geometries
mv output/$FLIGHTLINE/*/*_{,Corrected}IGM{,.hdr} $FLIGHTLINE/
# Scan angles & path length
mv output/$FLIGHTLINE/*/*_RawSCA{,.hdr} $FLIGHTLINE/
mv output/$FLIGHTLINE/*/*_RawPathLength{,.hdr} $FLIGHTLINE/
# Classification map
mv output/$FLIGHTLINE/*/${FLIGHTLINE}_*_PreClass{,.hdr} $FLIGHTLINE/
# Merged & unmerged image spatial footprints
mv output/$FLIGHTLINE/*/*_DataFootprint*.{dbf,prj,sh[px]} $FLIGHTLINE/
# Coregistration tie points
mv output/$FLIGHTLINE/*/*_*CoRegPoints.{csv,png} $FLIGHTLINE/
mv output/$FLIGHTLINE/*/*_*CoRegShiftDistribution.png $FLIGHTLINE/
# Plots & figures
mv output/$FLIGHTLINE/*/*.png $FLIGHTLINE/

# # Move single-sensor products to their own directories
# # (these were placed in the `merge` directory for some reason)
# for f in $FLIGHTLINE/${FLIGHTLINE}_{VNIR,SWIR}_*; do
#   mv $f $FLIGHTLINE/${f:(${#FLIGHTLINE}+1)*2:4}
# done

# mv output/$FLIGHTLINE/*/${FLIGHTLINE}_MergedPathLength{,.hdr} $FLIGHTLINE/ancillary
# mv output/$FLIGHTLINE/*/${FLIGHTLINE}_MergedSCA{,.hdr} $FLIGHTLINE/ancillary
# mv output/$FLIGHTLINE/*/${FLIGHTLINE}_WVC{,.hdr} $FLIGHTLINE/ancillary
# mv output/$FLIGHTLINE/*/${FLIGHTLINE}_VIS{,.hdr} $FLIGHTLINE/ancillary

# Pack outputs into .TAR.GZ archive
tar -czf ${FLIGHTLINE}_processed.tar.gz $FLIGHTLINE/*

# Move outputs back to CHTC staging (NOTE: No need to remove after)
mkdir -p $STAGING/data/processed/$SESSION
mv ${FLIGHTLINE}_processed.tar.gz $STAGING/data/processed/$SESSION/
# mv $FLIGHTLINE $STAGING/data/processed/$SESSION/

# :----------- MAKE QUICKLOOKS ----------: #

# Generate quicklook images
source utils/quicklook.sh
generate_quicklooks $FLIGHTLINE

# Move quicklooks back to CHTC staging (NOTE: No need to remove after)
mkdir -p $STAGING/data/quicklook/$SESSION
mv ${QUICKLOOK}.tar.gz $STAGING/data/quicklook/$SESSION/

# -------------- CLEAN UP -------------- #

rm -r $ENVDIR
rm -r hypro data output
rm -r $FLIGHTLINE

exit
