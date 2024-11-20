function share () {
  chmod $2 "$3" && chgrp $1 "$3"
}
