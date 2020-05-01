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
-m\tCreate matrices with the TimeSeries.
\t\tIf marked this flag, all the ROI's Timeseries extracted will
\t\tbe concatenated in a matrix for each subject.
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
while getopts "hmi:r:o:" arg; do
  case "$arg" in
    i) [[ -e "$OPTARG" ]] || err "%s not found.\n" "$OPTARG"
      inputs+=("$OPTARG")
      ;;
    r) [[ -d "$OPTARG" ]] || err "%s is not a directory.\n" "$OPTARG"
      [[ -e "$OPTARG" ]] || err "%s not found.\n" "$OPTARG"
      roidirs+=("$OPTARG")
      ;;
    o) [[ -d "$OPTARG" ]] || err "%s is not a directory.\n" "$OPTARG"
      [[ -e "$OPTARG" ]] || err "%s not found.\n" "$OPTARG"
      outdir="$OPTARG"
      ;;
    m) mats=1 ;;
    h) usage; exit ;;
    :) err "Missing argument for -%s.\n" "$OPTARG" ;;
    ?) err "Illegal option: %s.\n" "$OPTARG" ;;
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
  # ExiSting directory error check
  [ -d "$roidir" ] || err "%s not an existing directory\n" "$roidir"

  # If several roidirs save basename for naming.
  [ ${#roidirs[@]} -gt 1 ] \
    && bn_roidir="_$(bname "$roidir")" \
    $$ log "Starting with %s\n" "$roidir"

  # Save all files that are NIfTI into an array
  for file in "${roidir}"/*; do
    check_nii "$file"
    rois+=("$file")
  done
  unset file

  # If no valid ROI, exit with error.
  [ ${#rois[@]} -eq 0 ] && err "No valid NIfTI in %s\n" "$roidir"

  # Number of rois
  numrois=${#rois[@]}

  ## Files section ##
  for file in "${infiles[@]}"; do
    # Check for NIfTI, save name and create timeseries directory.
    check_nii "$file"
    img="$file"
    bn_img="$(bname "$file")"
    tsdir=$(printf "%s/%s%s_TS\n" "$outdir" "$bn_img" "$bn_roidir")
    mkdir -p "$tsdir"

    # Loop through all ROIs in directory
    log "Starting with %s\n" "$bn_img"

    i=1 #Set counter
    for roi in "${rois[@]}"; do
      bn_roi="$(bname "$roi")"
      outname=$(printf "%s/%0${#numrois}d_%s_%s.1D\n" \
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
    [ $mats ] \
      && cat "$tsdir"/* \
        >> "${outdir}/${bn_roidir}_${bn_img}".mat \
      && log "Created TS matrix.\n"

    log "Finished with %s\n" "$bn_img"
  done

  ## Directories section ##
  for dir in "${indirs[@]}"; do
    # If several dirs save basename for naming.
    [ ${#indirs[@]} -gt 1 ] \
      && bn_dir="$(bname "$dir")_" \
      && log "Starting with %s\n" "$bn_dir"

    # Loop through the contents to omit directories and check for NIfTIs.
    for content in "${dir}"/*; do
      # Omit if directory
      [[ -d "$content" ]] \
        && log "%s in %s is a directory. Ommiting it.\n" "$content" "$dir" \
        && continue

      # Check for NIfTI, save name and create timeseries directory.
      [[ -f "$content" ]] && check_nii "$content"
      img="$content"
      bn_img="$(bname "$img")"
      log "Starting with %s\n" "$bn_img"
      tsdir=$(printf "%s/%s%s%s_TS\n" \
        "$outdir" "$bn_dir" "$bn_img" "$bn_roidir")
      mkdir -p "$tsdir"

      #Same as above. This time, Directory basename is suffix in name.
      i=1
      for roi in "${roidir}"/*; do
        check_nii "$roi"
        bn_roi="$(bname "$roi")"
        outname=$(printf \
          "%s/%0${#numrois}d_%s_%s.1D\n" "$tsdir" "$i" "$bn_img" "$bn_roi")
        fslmeants \
          -i "$img" \
          -o "$outname" \
          -m "$roi" \
          --transpose \
        && log "Extracted TS from %s of %s\n" \
          "${bn_roi}" "${bn_img}"
        (( i++ ))
      done

      # Concatenate all ROIs timeseries into same file.
      [ $mats ] \
        && cat "$tsdir"/* \
          >> "${outdir}/${bn_dir}${bn_img}${bn_roidir}".mat \
        && log "Created TS matrix for %s.\n" "${bn_img}"

      log "Finished with %s\n" "$bn_img"
    done
    [ ${#indirs[@]} -gt 1 ] && log "Finished with %s\n" "$bn_dir"
  done
  [ ${#roidirs[@]} -gt 1 ] && log "Finished with %s\n" "$roidir"
done
}

main "$@"
