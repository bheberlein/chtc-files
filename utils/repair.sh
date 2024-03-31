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

# Renumber flightlines from sessions mislabeled with zero-based indexing
renumber () {
  echo "Renumbering flightlines for session: $1"
  DATA_DIRECTORY=$STAGING/data/raw/$1
  # Iterate over flightlines in reverse sorted order
  for f in $(ls $DATA_DIRECTORY/*.tar.gz | sort -r); do
    # Parse flightline basename
    ARCHIVE=${f##*/}
    FLIGHTLINE=${ARCHIVE%%.*}
    # Increment line number
    printf -v LINE '%02d' $(echo "${FLIGHTLINE##*_} + 1" | bc -l)
    # Corrected flightline basename
    RENAMED=${SESSION}_$LINE
    
    echo "  $FLIGHTLINE  ->  $RENAMED"
    
    TEMPORARY_DIRECTORY=$DATA_DIRECTORY/$RENAMED
    mkdir -p $TEMPORARY_DIRECTORY
    tar -xzf $f -C $TEMPORARY_DIRECTORY
    
    for g in $TEMPORARY_DIRECTORY/${FLIGHTLINE}_*; do
      mv $g ${g/$FLIGHTLINE/$RENAMED}
    done
    
    cd $TEMPORARY_DIRECTORY
    tar -czf $TEMPORARY_DIRECTORY.tar.gz *.{hyspex,hdr,txt}
    mv $f ${f}.mislabeled
    cd - > /dev/null
    rm -r $TEMPORARY_DIRECTORY
  done
}
