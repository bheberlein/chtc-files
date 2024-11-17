ENVNAME=xeno
MODTRAN_DIR=/usr/local/MODTRAN6.0

DATA_DIRECTORY=/data1/bheberlein/isofit
OUTPUT_DIRECTORY=$DATA_DIRECTORY/tmp
BASENAME=FLIGHT-2_20240424_02_SWIR_384_SN3142_FOVx2_raw
PREFIX=$DATA_DIRECTORY/$BASENAME
INPUTS=${PREFIX}_RawRadiance ${PREFIX}_ObsLocation ${PREFIX}_ObsParameter

SURFACE_FILE=git/isofit/examples/20171108_Pasadena/configs/ang20171108t184227_surface.json

conda activate $ENVNAME

# IMPORTANT: Export MODTRAN environment variables
export MODTRAN_LIC_SERVER=localhost:13
export MODTRAN_DATA=$MODTRAN_DIR/DATA

isofit apply_oe $INPUTS $OUTPUT_DIRECTORY hyspex --modtran_path $MODTRAN_DIR --surface_path $SURFACE_FILE
