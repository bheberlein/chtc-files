#!/usr/bin/bash

# :---------- DEFINE VARIABLES ----------: #

# User
CHTC_USER=$(id -u -n)
GROUP=townsend_group
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

# Whether to keep raw (unprojected) products
KEEP_RAW=1
# Whether to keep radiance products
KEEP_RDN=1

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

# Look for raw data inputs (NOTE: Takes the first matching file)
RAW_INPUT=$(find $STAGING/data/raw/$SESSION -name "$FLIGHTLINE.*" -print -quit)
if [ ! -f ${RAW_INPUT} ]; then echo "Raw inputs not found!"; exit 1; fi
# Copy over input data
cp $RAW_INPUT data/ && unpack data/"${RAW_INPUT##*/}" -C data

# Resolve processing configuration file
# NOTE: Takes the first file found from
#  1. PROJECT_Config.json
#  2. SITE_YYYYMMDD/SITE_YYYYMMDD_XX_Config.json
#  3. SITE_YYYYMMDD_Config.json
#  4. SITE_YYYY_Config.json
source utils/config.sh
resolve_config || exit 1
# Copy over JSON configuration file (strip out leading directories if present)
cp $CONFIG_DIR/$CONFIG data/"${CONFIG##*/}"

# :----------- RUN PROCESSING -----------: #

# Run HyPro reflectance processing
python hypro/src/hypro/workflow/main.py data/"${CONFIG##*/}"

# :----------- PACK UP OUTPUTS ----------: #

# Remove atmospheric database files
rm -r output/$FLIGHTLINE/atm
# Remove single-sensor products from merged directory
rm output/$FLIGHTLINE/merge/${FLIGHTLINE}_{VNIR,SWIR}_*
# Remove temporary files from orthorectification
rm output/${FLIGHTLINE}/{vnir,swir}/OrthorectifiedImageData{,.hdr,.aux.xml}

mkdir $FLIGHTLINE

# Processing log
mv output/*.log $FLIGHTLINE/
# Merged orthorectified imagery & ancillary datasets
mv output/$FLIGHTLINE/merge/* $FLIGHTLINE/

if [ $KEEP_RDN = 0 ]; then
  rm $FLIGHTLINE/${FLIGHTLINE}_MergedRadiance{,.hdr}
fi

# Single-sensor products
for SENSOR in VNIR SWIR; do
  mkdir $FLIGHTLINE/$SENSOR
  SENSOR_DIRECTORY=output/$FLIGHTLINE/${SENSOR,,}
  
  # Filepath prefix
  PREFIX=$SENSOR_DIRECTORY/${FLIGHTLINE}_${SENSOR}_*_FOVx2
  
  # Smile effect model
  mv ${PREFIX}_SmileEffect{,AtAtmFeatures}{,.hdr} $FLIGHTLINE/$SENSOR
  # Water vapor model
  mv ${PREFIX}_WVCModel.json $FLIGHTLINE/$SENSOR
  # Plots & figures
  mv ${PREFIX}_*.png $FLIGHTLINE/$SENSOR
  
  # Data footprint
  mv ${PREFIX}_DataFootprint{,CoReg}.{dbf,prj,sh[px]} $FLIGHTLINE/$SENSOR
  
  # Raw sensor products
  if [ $KEEP_RAW = 1 ]; then
    mv ${PREFIX}_IGM{,.hdr} $FLIGHTLINE/$SENSOR
    mv ${PREFIX}_PreClass{,.hdr} $FLIGHTLINE/$SENSOR
    mv ${PREFIX}_ProcessedNavData.txt $FLIGHTLINE/$SENSOR
    mv ${PREFIX}_RadioCaliCoeff{,.hdr} $FLIGHTLINE/$SENSOR
    mv ${PREFIX}_Raw{Rdn,PathLength,SCA}{,.hdr,.aux.xml} $FLIGHTLINE/$SENSOR
  fi
  
  # Coregistration files
  # NOTE: Use subshell to localize `shopt`
  (
    shopt -s nullglob
    for f in ${PREFIX}_*CoRegPoints.{csv,png} \
             ${PREFIX}_*{,Corrected}{IGM,RawSCA}{,.hdr,.aux.xml} \
             ${PREFIX}_CoregistrationShifts{,.hdr}; do
      mv $f $FLIGHTLINE/$SENSOR
    done
  )
done

# Pack outputs into .TAR.GZ archive
OUTPUT_ARCHIVE=${FLIGHTLINE}_Processed.tar.gz
tar -czf $OUTPUT_ARCHIVE $FLIGHTLINE/*

# Move outputs back to CHTC staging (NOTE: No need to remove after)
PROCESSED_DIRECTORY=$STAGING/data/processed/$SESSION
mkdir -p $PROCESSED_DIRECTORY
mv $OUTPUT_ARCHIVE $PROCESSED_DIRECTORY/
# mv $FLIGHTLINE $PROCESSED_DIRECTORY/

# :----------- MAKE QUICKLOOKS ----------: #

# Generate quicklook images
source utils/quicklook.sh
generate_quicklooks $FLIGHTLINE

# Move quicklooks back to CHTC staging (NOTE: No need to remove after)
QUICKLOOK_DIRECTORY=$STAGING/data/quicklook/$SESSION
mkdir -p $QUICKLOOK_DIRECTORY
QUICKLOOK_ARCHIVE=${QUICKLOOK}.tar.gz
mv $QUICKLOOK_ARCHIVE $QUICKLOOK_DIRECTORY/

# :--------- MANAGE PERMISSIONS ---------: #

# Set group write permissions (important if using group storage allocation on Staging)
source utils/permissions.sh
share $GROUP 770 $PROCESSED_DIRECTORY
share $GROUP 770 $QUICKLOOK_DIRECTORY
share $GROUP 660 $PROCESSED_DIRECTORY/$OUTPUT_ARCHIVE
share $GROUP 660 $QUICKLOOK_DIRECTORY/$QUICKLOOK_ARCHIVE

# :--------- MANAGE PERMISSIONS ---------: #

function share () {
  chmod $2 "$3" && chgrp $1 "$3"
}

# Set group write permissions (important if using group storage allocation on Staging)
share $GROUP 770 $PROCESSED_DIRECTORY
share $GROUP 770 $QUICKLOOK_DIRECTORY
share $GROUP 660 $PROCESSED_DIRECTORY/${FLIGHTLINE}_Processed.tar.gz
share $GROUP 660 $QUICKLOOK_DIRECTORY/${QUICKLOOK}.tar.gz

# -------------- CLEAN UP -------------- #

rm -r $ENVDIR
rm -r hypro data output
rm -r $FLIGHTLINE

echo "REMAINING FILES:"
echo $(ls -R)

exit 0
