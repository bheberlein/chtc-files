status () {
  condor_q $@ -pr ~/htcondor/usage.cpf

boost () {
  # Get prior resource requests for the job
  local disk_requested memory_requested
  read -r disk_requested memory_requested <<< $(condor_q $1 -af RequestDisk RequestMemory)
  # Get boosting factor
  local boost_factor
  boost_factor=${2:-1.5}
  # Calculated updated resource requests
  local disk_updated memory_updated
  disk_updated=$(echo "($disk_requested * $boost_factor)/1" | bc)
  memory_updated=$(echo "($memory_requested * $boost_factor)/1" | bc)
  # Edit job resource requests
  condor_qedit $1 RequestDisk $disk_updated RequestMemory $memory_updated
  # Release the job
  condor_release $1
}
