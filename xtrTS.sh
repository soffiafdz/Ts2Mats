#!/bin/bash

######################################################################
# Shell script for extracting the mean timeseries from all the ROIs
# inside one or several directories from a single fMRI run image or a
# directory of images.
# It implements FSL's fslmeants.
# © 2020 Sofía Fernández, M.Sc. | so1.618e@gmail.com
######################################################################

## Functions for help and errors.
usage(){
  printf "Usage:
%s [-h] -i <IMG | IMG_DIR> [-i ...] -r <ROI_DIR> [-r ...] [-o OUTDIR]

COMPULSORY ARGUMENTS
-i\tPath to Image to from where to extract the TS data.
\t\tIt can be a file or a directory.
-m\tPath to the directory containing the ROIs to use.
\t\tThis must be a directory.

OPTIONAL ARGUMENTS
-o\tOutput path for the outcomes.
\t\tOptional. If used, it has to be an existent directory.
\t\tWhen unset, outputs will be saved in the working directory.
-h\tDisplay this help and exit.

This script can parse several arguments of the same time;
but every instance must be preceded by the flag.
The output will be directory for every image containing

Examples:
\t%s -i sub1-ses1.nii -i sub1-ses2.nii -i sub1-ses3.nii -r atlas/rois
\t%s -i proj/subs1 -i proj/subs2 -r atlas/power -r atlas/dosenbach\n" \
    "$0" "$0";
  exit
}

log(){
  printf "[%s]: " "$(date +'%Y-%m-%dT%H:%M:%S%z')"
  printf "$@"
}

err(){
  printf "[%s]: " "$(date +'%Y-%m-%dT%H:%M:%S%z')" >&2
  printf "$@" >&2
  exit 1
}

check_nii(){
 local ext="${1#*.}"
  [[ "$ext" != "nii" ]] && [[ "$ext" != "nii.gz" ]] \
    && printf "%s is not a NIfTI image\n" "$1" \
    && continue
}

bname(){
    local filename="${1##*/}"
    local name="${filename%%.*}"
    echo "$name"
}

main(){
## If no argments, print help and exit.
[[ $# -eq 0 ]] && usage

## Check FSL is installed and fslmeants executable.
which fslmeants &>/dev/null \
  || err "fslmeants is not executable. Check FSL installation.\n"

## Argument parser.
while getopts "hi:r:o:" arg; do
  case "$arg" in
    i) [[ -e "$OPTARG" ]] || err "%s not found.\n" "$OPTARG"
      inputs+=("$OPTARG");;
    r) [[ -d "$OPTARG" ]] || err "%s is not a directory.\n" "$OPTARG"
      [[ -e "$OPTARG" ]] || err "%s not found.\n" "$OPTARG"
      roidirs+=("$OPTARG");;
    o) [[ -d "$OPTARG" ]] || err "%s is not a directory.\n" "$OPTARG"
      [[ -e "$OPTARG" ]] || err "%s not found.\n" "$OPTARG"
      outdir="$OPTARG";;
    h) usage; exit;;
    :) err "Missing argument for -%s.\n" "$OPTARG";;
    ?) err "Illegal option: %s.\n" "$OPTARG";;
  esac
done

## Check for all compulsory arguments
[ "${#inputs[@]}" -eq 0 ] || [ "${#roidirs[@]}" -eq 0 ] \
  && err "Missing compulsory arguments.\n"

## Sort in values into directories and files.
for input in "${inputs[@]}"; do
  [[ -f "$input" ]] && infiles+=("$input") && continue
  [[ -d "$input" ]] && indirs+=("$input") && continue
  printf "%s is not a valid file or directory.\n" "$input"
done

## If no in values left, exit with error.
[[ ${#infiles[@]} -eq 0 ]] && [[ ${#indirs[@]} -eq 0 ]] \
  && err "Not valid inputs.\n"

## Set OUTDIR to working directory if not set.
: ${outdir:=$(pwd)}

## Main loop through inputs and rois; extract timeseries and concatenate them.
for roidir in "${roidirs[@]}"; do
  [ -d "$roidir" ] || err "%s not an existing directory" "$roidir"
  log "**Starting with %s**\n" "$roidir"
  bn_roidir="$(bname "$roidir")"
  ## Files section
  for file in "${infiles[@]}"; do
    check_nii "$file"
    img="$file"
    bn_img="$(bname "$file")"
    tsdir=$(printf "%s/%s_%s_TS\n" "$outdir" "$bn_roidir" "$bn_img")
    mkdir -p "$tsdir"
    # Loop through all ROIs in directory
    log "**Starting with %s**\n" "$bn_img"
    # Set a counter
    i=1
    for roi in "${roidir}"/*; do
      check_nii "$roi"
      bn_roi="$(bname "$roi")"
      outname=$(printf "%s/%03d_%s_%s.1D\n" \
        "$tsdir" $i "$bn_img" "$bn_roi")
      fslmeants \
        -i "$img" \
        -o "$outname" \
        -m "$roi" \
        --transpose \
      && log "Extracted TS from %s of %s\n" "${bn_roi}" "${bn_img}"
      (( i++ ))
    done
    # Concatenate all ROIs timeseries into same file.
    cat "$tsdir"/* \
      >> "${outdir}/${bn_roidir}_${bn_img}".mat \
    && log "Created TS matrix.\n"
    log "**Finished with %s**\n" "$bn_img"
  done
  ## Directories section
  for dir in "${indirs[@]}"; do
    bn_dir="${dir##*/}"
    log "**Starting with %s**\n" "$bn_dir"
    # Loop through the contents to omit directories and check for NIfTIs.
    for content in "${dir}"/*; do
      [[ -d "$content" ]] \
        && log "%s in %s is a directory. Ommiting it.\n" "$content" "$dir" \
        && continue
      [[ -f "$content" ]] && check_nii "$content"
      img="$content"
      bn_img="$(bname "$img")"
      log "**Starting with %s**\n" "$bn_img"
      tsdir=$(printf "%s/%s_%s_%s_TS\n" \
        "$outdir" "$bn_roidir" "$bn_dir" "$bn_img")
      mkdir -p "$tsdir"
      #Same as above. This time, Directory basename is suffix in name.
      i=1
      for roi in "${roidir}"/*; do
        check_nii "$roi"
        bn_roi="$(bname "$roi")"
        outname=$(printf \
          "%s/%03d_%s_%s.1D\n" "$tsdir" "$i" "$bn_img" "$bn_roi")
        fslmeants \
          -i "$img" \
          -o "$outname" \
          -m "$roi" \
          --transpose \
        && log "Extracted TS from %s of %s in %s\n" "${bn_roi}" "${bn_img}" "${bn_dir}"
        (( i++ ))
      done
      # Concatenate all ROIs timeseries into same file.
      cat "$tsdir"/* \
        >> "${outdir}/${bn_roidir}_${bn_dir}_${bn_img}".mat \
      && log "Appended to TS matrix\n"
      log "**Finished with %s**\n" "$bn_img"
    done
    log "**Finished with %s**\n" "$bn_dir"
  done
  log "**Finished with %s**\n" "$roidir"
done
}

main "$@"
