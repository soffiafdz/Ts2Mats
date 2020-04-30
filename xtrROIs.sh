#!/bin/bash

######################################################################
# Shell script for extracting the corresponding submasks of every
# one of the indexed images. It implements FSL.
# © 2020 Sofía Fernández, M.Sc. | so1.618e@gmail.com
######################################################################

usage(){
  printf "Usage: %s [-h] -i <Image> -n <NUMBER>\n" "$0"
}

help_msj(){
  usage
  printf "
COMPULSORY ARGUMENTS
-i\tPath to the Cluster Index Image.
\t\tThe clusters must be assigned a unique number (from 1 to N).
\t\tThis can be the output of fsl's cluster.
-n\tNumber of clusters to extract.
\tThe clusters will be extracted serially from 1 to N.
OPTIONAL ARGUMENTS
-o\tOut directory. Directory name unto which save the outputs.
\t\tIt ought to be an existent directory.
-m\tMin N. From what number to start extracting.
\t\tThis argument can be used for extracting only a specific range of clusters:
\t\t(from M to N).
-h\tDisplay this help and exit.\n"
  exit
}

err(){
  echo "[$(date +'%Y-%m-%dT%H:%M:%S%z')]:" >&2
  printf "$*" >&2
  exit 1
}

main(){
  ## If no arguments, show help and exit.
  [ $# -eq 0 ] && help_msj

  ## Check FSL is installed and fslmaths executable.
  fslmaths -h &>/dev/null \
    || err "fslmaths is not found in PATH. Check FSL installation.\n"

  ## Argument parser.
  while getopts "hi:n:" arg; do
    case "$arg" in
      i)
        [ -f "$OPTARG" ] || err "%s is not a file.\n" "$OPTARG"
        [ -e "$OPTARG" ] || err "%s not found.\n" "$OPTARG"
        img="$OPTARG"
        ;;
      n)
        [ "$OPTARG" -gt 0 ] 2>/dev/null \
          || err "%s must be natural number (>0).\n" "$OPTARG"
        num="$OPTARG"
        ;;
      m)
        [ "$OPTARG" -gt 0 ] 2>/dev/null \
          || err "%s must be natural number (>0).\n" "$OPTARG"
        min="$OPTARG"
        ;;
      o) outdir="$OPTARG";;
      h) help_msj;;
      :) err "Missing argument for -%s.\n" "$OPTARG";;
      ?) err "Illegal option: %s.\n" "$OPTARG";;
    esac
  done

  # Check for compulsory variables.
  [ -z "$img" ] || [ -z "$num" ] && err "Missing compulsory argument(s)\n"

  # Derivated variables.
  ext=${img#*.}
  bn=$(basename "$img" ".$ext")
  # Set outdir to default if not set and create it.
  : ${outdir:="${bn}_masks"}
  mkdir "$outdir"

  # Loop through the number of clusters requested in NUM.
  # Check for valid range

  # Implementati n of fslmaths extracting the indexed cluster.

  for ((i=1 ; i<1+"$num" ; i++)); do
    out=$(printf "%s/%s_%03d"
    "${outdir}/${bn}_$i"
    fslmaths -dt int "$img" -thr "$i" -uthr "$i" -bin "$out"
  done
}

main "$@"
