unpack () {
  # Determine whether the archive is GZIP-compressed
  # NOTE: File name needs to be the first argument supplied
  local TAREXT="${1%%.*}";
  if [[ "$TAREXT" = ".tar.gz" ]]; then
    local TARFLAGS="-xzf";
  else
    local TARFLAGS="-xf";
  fi
  # Unpack the archive
  tar $TARFLAGS $@ && rm $1
}

extract_remove () {
  (
    # Skip if no files found
    shopt -s nullglob
    # Find, extract & remove archives
    for f in *.tar.gz; do
      echo $f;
      unpack $f;
    done
  )
}
