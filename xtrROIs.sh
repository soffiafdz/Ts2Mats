#!/bin/sh

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
  OPTIONAL ARGUMENTS
  -h\tDisplay this help and exit.\n"
  exit
}

err(){
  echo "[$(date +'%Y-%m-%dT%H:%M:%S%z')]:" >&2
  printf $* >&2
  exit 1
}

main(){
  ## If no arguments, show help and exit
  [[ $# -eq 0 ]] && help_msj

## Check FSL is installed and fslmaths executable
fslmaths &>/dev/null \
  || err "fslmaths is not found in PATH. Check FSL installation"

## Argument parser
while getopts "hi:n:" arg; do
  case "$arg" in
    h) help_msj;;
    :) err "Missing argument for -%s.\n" "$OPTARG";;
    ?) err "Illegal option: %s.\n" "$OPTARG";;
    i)
      [[ -f "$OPTARG" ]] || err "%s is not a file.\n" "$OPTARG"
      [[ -e "$OPTARG" ]] || err "%s not found.\n" "$OPTARG"
      img="$OPTARG"
      ;;
    n)
      [[ "$OPTARG" -gt 0 ]] 2>/dev/null \
        || err "%s must be natural number (>0).\n" "$OPTARG"
      num=$OPTARG
      ;;
  esac
done

# Derivated variables
ext=${Image#*.};
bn=$(basename "$img" "$ext");
outdir="${bn}_masks";

# Create directory for outputs with same name as the input image
mkdir "$outdir";

# Loop through the number of clusters requested in NUM.
# Implementation of fslmaths extracting the indexed cluster.

for idx in {1.."$num"}; do
  out="${outdir}/${bn}_$idx"
  fslmaths -dt int "$img" -thr "$idx" -uthr "$idx" -bin "$out";
done
}

main "$@"
