boost () {
  # Get prior resource requests for the job
  local disk_requested memory_requested
  read -r disk_requested memory_requested <<< $(condor_q $1 -af RequestDisk RequestMemory)
  echo "Current disk request: ${disk_requested}"
  echo "Current memory request: ${memory_requested}"
  # Get boosting factors
  local disk_boost memory_boost
  disk_boost=${2:-1.5}
  memory_boost=${3:-disk_boost}
  # Calculated updated resource requests
  local disk_updated memory_updated updated_request
  updated_request=""
  if (( $(echo "$disk_boost > 1" | bc -l) )); then
    disk_updated=$(echo "($disk_requested * $disk_boost)/1" | bc)
    updated_request+=" RequestDisk $disk_updated"
  fi
  if (( $(echo "$memory_boost > 1" | bc -l) )); then
    memory_updated=$(echo "($memory_requested * $memory_boost)/1" | bc)
    updated_request+=" RequestMemory $memory_updated"
  fi
  if [ -z "$updated_request" ]; then
    echo "ERROR: At least one resource request must be boosted!"
    exit 1
  fi
  echo "condor_qedit $1 $(echo $updated_request | xargs)"
  # Edit job resource requests & release
  condor_qedit ${1}$updated_request && condor_release $1
}
