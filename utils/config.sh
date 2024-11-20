#!/usr/bin/bash

resolve_config () {
  # Specify configuration file directory
  CONFIG_DIR=$STAGING/config
  # If no configuration file is specified,
  #  try to resolve automatically
  if [ -z ${CONFIG+x} ]; then
    
    # A flightline-level config file is located in a session subdirectory
    #  & uses the full flightline basename, i.e. SITE-NAME_YYYYMMDD/SITE-NAME_YYYYMMDD_XX_Config.json
    FLIGHTLINE_CONFIG=$SESSION/${FLIGHTLINE}_Config.json
    
    # A session-level config file has the same basename as the session, i.e. SITE-NAME_YYYYMMDD_Config.json
    SESSION_CONFIG=${SESSION}_Config.json
    
    # A season-level config file basename just has the minimal site name & year, i.e. SITE-NAME_YYYY_Config.json
    # NOTE: Site name is stripped of trailing dash-separated numbers
    SEASON_CONFIG=${NAME%%-[0-9]}_${ISODATE:0:4}_Config.json
    
    # A project-level config file basename is just the project name, i.e. PROJECT_Config.json
    PROJECT_CONFIG=${PROJECT}_Config.json
    
    # If a project basename is given, check for a project-level configuration file
    if [[ ( -n "${PROJECT+x}" ) && ( -f $CONFIG_DIR/${PROJECT_CONFIG} ) ]]; then
      CONFIG=$PROJECT_CONFIG;
    
    # Otherwise (or if not found), look for flightline-level config
    elif [[ -f $CONFIG_DIR/${FLIGHTLINE_CONFIG} ]]; then
      CONFIG=$FLIGHTLINE_CONFIG;
    
    # If not found, look for session-level config
    elif [[ -f $CONFIG_DIR/${SESSION_CONFIG} ]]; then
      CONFIG=$SESSION_CONFIG;
    
    # If not found, look for season-level config
    elif [[ -f $CONFIG_DIR/${SEASON_CONFIG} ]]; then
      CONFIG=$SEASON_CONFIG;
    
    else
      echo "ERROR: No configuration file found!" 1>&2
      return 1
    fi
  
  elif [[ ! -f $CONFIG_DIR/$CONFIG ]]; then
    echo "ERROR: Specified configuration file does not exist! ($CONFIG_DIR/$CONFIG)" 1>&2
    return 1
  fi
  
  echo "Using processing configuration: $CONFIG_DIR/$CONFIG"
  return 0
}
