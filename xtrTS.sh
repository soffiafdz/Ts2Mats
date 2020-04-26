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

\t-i\tPath to Image to from where to extract the TS data.
\t\t\tIt can be a file or a directory.
\t-m\tPath to the directory containing the ROIs to use.
\t\t\tThis must be a directory.
\t-o\tOutput path for the outcomes.
\t\t\tOptional. If used, it has to be an existent directory.
\t\t\tWhen unset, outputs will be saved in the working directory.
\t-h\tDisplay this help and exit.

This script can parse several arguments of the same time;
but every instance must be preceded by the flag.
The output will be directory for every image containing

Examples:
\t%s -i sub1-ses1.nii -i sub1-ses2.nii -i sub1-ses3.nii -r atlas/rois
\t%s -i proj/subs1 -i proj/subs2 -r atlas/power -r atlas/dosenbach\n" \
    "$0" "$0";
  exit
}

err(){
  echo "[$(date +'%Y-%m-%dT%H:%M:%S%z')]:" >&2
  printf $* >&2
  exit 1;
}

check_nii(){
 local ext="${1#*.}"
  [[ "$ext" != "nii" ]] && [[ "$ext" != "nii.gz" ]] \
    && printf "%s is not a NIfTI image\n" "$1" \
    && continue
}

main(){
## If no argments, print help and exit.
[[ $# -eq 0 ]] && usage

## Check FSL is installed and fslmeants executable.
fslmeants &>/dev/null \
  || err "fslmeants is not executable. Check FSL installation.\n"

## Argument parser.
while getopts "hi:r:o:" arg; do
  case "$arg" in
    -i) [[ -e "$OPTARG" ]] || err "%s not found.\n" "$OPTARG"
      inputs+=("$OPTARG");;
    -r) [[ -d "$OPTARG" ]] || err "%s is not a directory.\n" "$OPTARG"
      [[ -e "$OPTARG" ]] || err "%s not found.\n" "$OPTARG"
      roidirs+=("$OPTARG");;
    -o) [[ -d "$OPTARG" ]] || err "%s is not a directory.\n" "$OPTARG"
      [[ -e "$OPTARG" ]] || err "%s not found.\n" "$OPTARG"
      outdir="$OPTARG";;
    -h) usage; exit;;
    :) err "Missing argument for -%s.\n" "$OPTARG";;
    ?) err "Illegal option: %s.\n" "$OPTARG";;
  esac
done

## Sort in values into directories and files.
for input in "${inputs[@]}"; do
  [[ -f "$input" ]] && infiles+="$input" && continue
  [[ -d "$input" ]] && indirs+="$input" && continue
  printf "%s is not a valid file or directory.\n" "$input"
done

## If no in values left, exit with error.
[[ ${#infiles} -eq 0 ]] && [[ ${#indirs} -eq 0 ]] && err "Not valid inputs\n"

## Set OUTDIR to working directory if not set.
${outdir:=`pwd`}

## Main loop through inputs and rois; extract timeseries and concatenate them.
for roidir in "${roidirs[@]}"; do
  ## Files section
  for file in "${infiles[@]}"; do
    check_nii "$file"
    img="$file"
    bn_img="${img##*/}"
    # Loop through all ROIs in directory
    for roi in "${roidir}/*"; do
      check_nii "$roi"
      bn_roi="${roi##*/}"
      fslmeants \
        -i "$img" \
        -o "${outdir}/${bn_img}_${bn_roi}.1D" \
        -m "$roi" \
        --transpose
    done
    # Concatenate all ROIs timeseries into same file.
    cat "${outdir}/${bn_img}"*.1D \
      >> "${outdir}/${bn_dir}_${bn_img}".mat
  done
  ## Directories section
  for dir in "${indirs[@]}"; do
    bn_dir="${dir##*/}"
    # Loop through the contents to omit directories and check for NIfTIs.
    for content in "${dir}/*"; do
      [[ -d "$content" ]] \
        && printf "%s in %s is a directory. Ommiting it.\n" "$content" "$dir" \
        && continue
      [[ -f "$content" ]] && check_nii "$content"
      img="$content"
      bn_img="${img##*/}"
      #Same as above. This time, Directory basename is suffix in name.
      for roi in "${roidir}/*"; do
        check_nii "$roi"
        bn_roi="${roi##*/}"
        fslmeants \
          -i "$img" \
          -o "${outdir}/${bn_dir}_${bn_img}_${bn_roi}.1D" \
          -m "$roi" \
          --transpose
      done
      cat "${outdir}/${bn_dir}_${bn_img}"*.1D \
        >> "${outdir}/${bn_dir}_${bn_img}".mat
    done
  done
done
}

main "$@"
