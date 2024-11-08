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
HYPROTAR=hypro_1.0.1dev4.tar.gz

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

# TEMPORARY FIX: Repair mislabeled input data archives
source utils/repair.sh
repair

# Resolve processing configuration file
source utils/config.sh
resolve_config
# Copy over JSON configuration file (strip out leading directories if present)
cp $CONFIG_DIR/$CONFIG data/"${CONFIG##*/}"

# If grid rotation is passed in as an environment variable, update the configuration file
if [ -n "${GRID_ROTATION+x}" ]; then
  echo "Updating processing grid rotation: $GRID_ROTATION"
  mv data/"${CONFIG##*/}" data/"${CONFIG##*/}.tmp"
  jq -r --arg GRID_ROTATION "$GRID_ROTATION" '.Geometric_Correction.rotation = $GRID_ROTATION' data/"${CONFIG##*/}.tmp" > data/"${CONFIG##*/}"
  rm data/"${CONFIG##*/}.tmp"
fi

# :----------- RUN PROCESSING -----------: #

# Run HyPro reflectance processing
if python hypro/src/hypro/workflow/main.py data/"${CONFIG##*/}"; then
  echo "SUCCESS: Processing completed with normal exit code."
else
  echo "FAILED: Processing completed with abnormal exit code."
  # If Python exits with an error, copy all files back to Staging & exit
  mv output/* $STAGING/data/processed/$SESSION
  exit 1
fi

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

  # Smile effect model
  mv $SENSOR_DIRECTORY/${FLIGHTLINE}_${SENSOR}_*_FOVx2_SmileEffect{,AtAtmFeatures}{,.hdr} $FLIGHTLINE/$SENSOR
  # Water vapor model
  mv $SENSOR_DIRECTORY/${FLIGHTLINE}_${SENSOR}_*_FOVx2_WVCModel.json $FLIGHTLINE/$SENSOR
  # Plots & figures
  mv $SENSOR_DIRECTORY/${FLIGHTLINE}_${SENSOR}_*_FOVx2_*.png $FLIGHTLINE/$SENSOR

  # Data footprint
  mv $SENSOR_DIRECTORY/${FLIGHTLINE}_${SENSOR}_*_FOVx2_DataFootprint{,CoReg}.{dbf,prj,sh[px]} $FLIGHTLINE/$SENSOR

  # Raw sensor products
  if [ $KEEP_RAW = 1 ]; then
    mv $SENSOR_DIRECTORY/${FLIGHTLINE}_${SENSOR}_*_FOVx2_IGM{,.hdr} $FLIGHTLINE/$SENSOR
    mv $SENSOR_DIRECTORY/${FLIGHTLINE}_${SENSOR}_*_FOVx2_PreClass{,.hdr} $FLIGHTLINE/$SENSOR
    mv $SENSOR_DIRECTORY/${FLIGHTLINE}_${SENSOR}_*_FOVx2_ProcessedNavData.txt $FLIGHTLINE/$SENSOR
    mv $SENSOR_DIRECTORY/${FLIGHTLINE}_${SENSOR}_*_FOVx2_RadioCaliCoeff{,.hdr} $FLIGHTLINE/$SENSOR
    mv $SENSOR_DIRECTORY/${FLIGHTLINE}_${SENSOR}_*_FOVx2_Raw{Rdn,PathLength,SCA}{,.hdr,.aux.xml} $FLIGHTLINE/$SENSOR
  fi

  # Coregistration files
  # NOTE: Use subshell to localize `shopt`
  (
    shopt -s nullglob
    for f in $SENSOR_DIRECTORY/${FLIGHTLINE}_${SENSOR}_*_FOVx2_*CoRegPoints.{csv,png} \
             $SENSOR_DIRECTORY/${FLIGHTLINE}_${SENSOR}_*_FOVx2_*{,Corrected}{IGM,RawSCA}{,.hdr,.aux.xml} \
             $SENSOR_DIRECTORY/${FLIGHTLINE}_${SENSOR}_*_FOVx2_CoregistrationShifts{,.hdr}; do
      mv $f $FLIGHTLINE/$SENSOR
    done
  )
done

# Pack outputs into .TAR.GZ archive
tar -czf ${FLIGHTLINE}_Processed.tar.gz $FLIGHTLINE/*

# Move outputs back to CHTC staging (NOTE: No need to remove after)
PROCESSED_DIRECTORY=$STAGING/data/processed/$SESSION
mkdir -p $PROCESSED_DIRECTORY
mv ${FLIGHTLINE}_Processed.tar.gz $PROCESSED_DIRECTORY/

# :----------- MAKE QUICKLOOKS ----------: #

# Generate quicklook images
source utils/quicklook.sh
generate_quicklooks $FLIGHTLINE

# Move quicklooks back to CHTC staging (NOTE: No need to remove after)
QUICKLOOK_DIRECTORY=$STAGING/data/quicklook/$SESSION
mkdir -p $QUICKLOOK_DIRECTORY
mv ${QUICKLOOK}.tar.gz $QUICKLOOK_DIRECTORY/

# :--------- MANAGE PERMISSIONS ---------: #

# Set group write permissions (important if using group storage allocation on Staging)
chmod 770 $PROCESSED_DIRECTORY
chmod 770 $QUICKLOOK_DIRECTORY
chmod 660 $PROCESSED_DIRECTORY/${FLIGHTLINE}_Processed.tar.gz
chmod 660 $QUICKLOOK_DIRECTORY/${QUICKLOOK}.tar.gz

# -------------- CLEAN UP -------------- #

rm -r $ENVDIR
rm -r hypro data output
rm -r $FLIGHTLINE

echo "REMAINING FILES:"
echo $(ls -R)

exit 0

