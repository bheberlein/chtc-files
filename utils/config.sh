#!/usr/bin/bash

function resolve_config() {
  # Specify configuration file directory
  CONFIG_DIR=$STAGING/config
  # If no configuration file is specified,
  #  try to resolve automatically
  if [ -z ${CONFIG+x} ]; then

    # A session-level config file has the same basename as the session
    #  & is located in a session subdirectory
    SESSION_CONFIG=$SESSION/${SESSION}_Config.json

    # A season-level config file basename just has the minimal site name & year
    # NOTE: Site name is stripped of trailing dash-separated numbers
    SEASON_CONFIG=${NAME%%-[0-9]}_${ISODATE:0:4}_Config.json

    # First look for session-level config
    if [[ -f $CONFIG_DIR/${SESSION_CONFIG} ]]; then
      CONFIG=${SESSION_CONFIG}
    # If not found, look for season-level config
    elif [[ -f $CONFIG_DIR/${SEASON_CONFIG} ]]; then
      CONFIG=${SEASON_CONFIG}
    # If a separate project basename is given, use that
    elif [[ -n "${PROJECT+x}" ]]; then
      CONFIG=${PROJECT}_Config.json
    else
      echo "ERROR: No configuration file found!" 1>&2
      return 1
    fi
  elif [[ ! -f $CONFIG_DIR/$CONFIG ]]; then
    echo "ERROR: Configuration does not exist!" 1>&2
    return 1
  fi

  echo "Using processing configuration: $CONFIG_DIR/$CONFIG"
  return 0
}
