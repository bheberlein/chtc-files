boost () {
  # Get prior resource requests for the job
  local disk_requested memory_requested
  read -r disk_requested memory_requested <<< $(condor_q $1 -af RequestDisk RequestMemory)
  # Get boosting factors
  local disk_boost memory_boost
  disk_boost=${2:-1.5}
  memory_boost=${3:-disk_boost}
  # Calculated updated resource requests
  local disk_updated memory_updated updated_request
  updated_request=""
  if (( $(echo "$disk_boost > 1" | bc -l) )); then
    disk_updated=$(echo "($disk_requested * $boost_factor)/1" | bc)
    updated_request+=" RequestDisk $disk_updated"
  fi
  if (( $(echo "$memory_boost > 1" | bc -l) )); then
    memory_updated=$(echo "($memory_requested * $boost_factor)/1" | bc)
    updated_request+=" RequestMemory $memory_updated"
  fi
  # Edit job resource requests
  condor_qedit $1 $(echo $updated_request | xargs)
  # Release the job
  condor_release $1
}
