#!/usr/bin/bash

# User
CHTC_USER=alkhaled
# File storage
USER_STAGING=/staging/$CHTC_USER
STAGING=/staging/groups/townsend_hyspex
# Python environment
ENVNAME=htconda
ENVDIR=$ENVNAME
# Packages
ENVTAR=$ENVNAME-new.tar.gz
HYPROTAR=hypro_1.0.1dev2.tar.gz
# Options
if [ -z ${COMPRESSED_INPUTS+x} ]; then
  COMPRESSED_INPUTS=1;
fi

# Resource directories
# SOURCE_DIR=$USER_STAGING/packages
# PACKAGE_DIR=$USER_STAGING/packages
SOURCE_DIR=$STAGING/source/environment
PACKAGE_DIR=$STAGING/source/packages

# Set up Conda/Python environment
source utils/conda.sh
conda_setup

# PYTHON_VERSION=$(python -c 'import sys; print(sys.version_info[:])')

# Until HyPro is properly installed in the Conda environment, we need to add it to `conda.pth`
echo $(pwd)/hypro/src > $ENVDIR/lib/python3.9/site-packages/conda.pth

source utils/variables.sh
resolve_variables "$@"

mkdir ./hypro

cp $PACKAGE_DIR/$HYPROTAR ./
tar -xzf $HYPROTAR -C ./hypro

# NOTE: Currently, code is structured as
#  hypro/
#  +-- data/
#  +-- src/
#      +-- hypro/

# Set up directories for raw & processed data
mkdir ./data
mkdir ./output

if [[ $COMPRESSED_INPUTS == 1 ]]; then
  TAREXT=".tar.gz";
  TARFLAGS="-xzf";
else
  TAREXT=".tar";
  TARFLAGS="-xf";
fi

RAW_INPUT=${FLIGHTLINE}${TAREXT}

# Copy raw HySpex data
cp $STAGING/data/raw/$SESSION/$RAW_INPUT data/
# Unpack
tar $TARFLAGS data/$RAW_INPUT -C data/ && rm data/$RAW_INPUT

source utils/config.sh
resolve_config


# Copy configuration .JSON file (strip out leading directories if present)
cp $CONFIG_DIR/$CONFIG data/"${CONFIG##*/}"

# Run HyPro processing
python hypro/src/hypro/workflow/main.py data/$CONFIG


# ------------------- #
#   PACK UP OUTPUTS
# ------------------- #

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

# # If directory already exists containing processed data, remove it
# if [ -d $STAGING/data/processed/$SESSION/$FLIGHTLINE ]; then
#   rm -r $STAGING/data/processed/$SESSION/$FLIGHTLINE
# fi

# Move outputs back to CHTC staging (NOTE: No need to remove after)
mkdir -p $STAGING/data/processed/$SESSION
mv ${FLIGHTLINE}_processed.tar.gz $STAGING/data/processed/$SESSION/
# mv $FLIGHTLINE $STAGING/data/processed/$SESSION/


# ------------------- #
#   MAKE QUICKLOOKS
# ------------------- #


QUICKLOOK=${FLIGHTLINE}_quicklooks

mkdir $QUICKLOOK

source utils/quicklook.sh
make_quicklook 74 46 21 $QUICKLOOK/${FLIGHTLINE}_TrueColorVIS
make_quicklook 236 316 406 $QUICKLOOK/${FLIGHTLINE}_FalseColorSWIR
make_quicklook 330 380 460 $QUICKLOOK/${FLIGHTLINE}_DestripedSWIR

# Pack quicklooks into .TAR.GZ archive
tar -czvf $QUICKLOOK.tar.gz $QUICKLOOK/*

# Move quicklooks back to CHTC staging (NOTE: No need to remove after)
mkdir -p $STAGING/data/quicklook/$SESSION
mv ${QUICKLOOK}.tar.gz $STAGING/data/quicklook/$SESSION/


# ------------------- #
#      CLEAN UP
# ------------------- #

rm -r $ENVDIR
rm $HYPROTAR
rm -r hypro

rm -r data
rm -r output
rm -r $FLIGHTLINE
rm -r $QUICKLOOK

exit
