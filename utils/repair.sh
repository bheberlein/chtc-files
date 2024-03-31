repair () {
  # Check for mislabeled files
  local files
  files=$(find data -type f -name "*_VNIR_1800_SN00480_*")
  # Repair mislabeled input data archives
  if [ ! $(wc -l <<< "$files") -eq 0 ]; then
    echo "Repairing input data archive for $FLIGHTLINE"
    echo "Found mislabeled raw data files:"
    for f in $files; do
      echo $f
      mv $f ${f/VNIR_1800_SN00480/VNIR_1800_SN00840}
    done
    cd data
    echo "Packaging repaired archive..."
    tar -czf $FLIGHTLINE.tar.gz *.{hyspex,hdr,txt}
    echo "Replacing corrupted archive..."
    mv $RAW_INPUT ${RAW_INPUT}.corrupted
    mv $FLIGHTLINE.tar.gz $STAGING/data/raw/$SESSION && rm ${RAW_INPUT}.corrupted
    echo "Done!"
    cd ../
  else
    echo "Input data archive OK!"
  fi
}
