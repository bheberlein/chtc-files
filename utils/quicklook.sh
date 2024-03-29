#!/usr/bin/bash

make_quicklook () {
  gdalbuildvrt -b $1 -b $2 -b $3 -srcnodata 0 -vrtnodata -0 $4.vrt $FLIGHTLINE/${FLIGHTLINE}_Refl
  gdal_translate -a_nodata -0 -scale -ot Byte $4.vrt $4.tif
  gdal_translate -a_nodata -0 -scale -ot Byte $4.vrt $4.png
}

generate_quicklooks () {
  QUICKLOOK=${1}_QuickLooks
  mkdir $QUICKLOOK
  # Generate standard quicklook images
  make_quicklook 74 46 21 $QUICKLOOK/${1}_TrueColorVIS
  make_quicklook 236 316 406 $QUICKLOOK/${1}_FalseColorSWIR
  make_quicklook 330 380 460 $QUICKLOOK/${1}_DestripedSWIR
  # Pack quicklooks into .TAR.GZ archive
  tar -czvf $QUICKLOOK.tar.gz $QUICKLOOK/*
  # Clean up
  rm -r $QUICKLOOK
}
