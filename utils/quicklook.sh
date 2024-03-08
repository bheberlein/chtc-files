#!/usr/bin/bash

function make_quicklook () {
  gdalbuildvrt -b $1 -b $2 -b $3 -srcnodata 0 -vrtnodata -0 $4.vrt $FLIGHTLINE/${FLIGHTLINE}_Refl
  gdal_translate -a_nodata -0 -scale -ot Byte $4.vrt $4.tif
  gdal_translate -a_nodata -0 -scale -ot Byte $4.vrt $4.png
}
