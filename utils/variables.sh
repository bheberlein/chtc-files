#!/usr/bin/bash

resolve_variables () {
  
  # Session basename
  NAME=$1
  # Collection date (YYYYMMDD)
  ISODATE=$2
  # Flightline index
  LINE=$3
  
  # Imaging session name
  SESSION=${NAME}_${ISODATE}
  # Flightline basename
  FLIGHTLINE=${SESSION}_${LINE}
  # Project name (if given)
  [[ -n "${4+x}" ]] && PROJECT=$4
  
  echo ">>> Flightline: $FLIGHTLINE" >&2
  
  if [[ -n "${PROJECT+x}" ]]; then
    echo ">>> Project given: ${PROJECT}" >&2
  else
    echo ">>> No project given." >&2
  fi
}
