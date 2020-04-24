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
    %s [-h] <-i IMG | IMG_DIR> [-i ...] <-r ROI_DIR> [-r ...] [-o OUTDIR]

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
    %s -i sub1-ses1.nii -i sub1-ses2.nii -i sub1-ses3.nii -r atlas/rois
    %s -i proj/subs1 -i proj/subs2 -r atlas/power -r atlas/dosenbach\n" \
    "$0" "$0";
}

exit_error(){
    printf "$@";
    usage;
    exit 1;
}

## Check FSL is installed and fslmeants executable
fslmeants &>/dev/null \
    || printf "ERROR: fslmeants is not executable or not found in PATH.
Check FSL installation" >&2

## Argument parser
while getopts "hi:r:o:" OPT; do
    case "$OTP" in
        -i) [ -e "$OPTARG" ] \
                || exit_error"ERROR: %s could not be found.\n" "$OPTARG";
            INPUTS+=("$OPTARG");;
        -r) [ -d "$OPTARG" ] \
                || exit_error "ERROR: %s is not a directory.\n" "$OPTARG";
            [ -e "$OPTARG" ] \
                || exit_error "ERROR: %s could not be found.\n" "$OPTARG";
            ROIS+=("$OPTARG");;
        -o) [ -d "$OPTARG" ] \
                || exit_error "ERROR: %s is not a directory.\n" "$OPTARG";
            [ -e "$OPTARG" ] \
                || exit_error "ERROR: %s could not be found.\n" "$OPTARG";
            OUTDIR="$OPTARG";;
        -h) usage; exit;;
        :) exit_error "Missing argument for -%s.\n" "$OPTARG";;
        ?) exit_error "Illegal option: %s.\n" "$OPTARG";;
    esac
done

## Main

TimeSeries(){
    fslmeants -i "$1" -o "$2" -m "$3" --transpose
}

CheckForNii(){
    EXT="${1#*.}"
    [ "$EXT" != "nii" ] && [ "$EXT" != "nii.gz" ] \
        && printf "ERROR: %s is not a NIfTI image" "$1" >&2 \
        && continue
}

for INPUT in "${INPUTS[@]}"; do
    [ -f "$INPUT" ] && CheckForNii "$INPUT" && FILES+="$INPUT" && continue;
    for FILE in "${INPUT}/*"; do
    [ -f "$FILE" ] && FILES+="$FILE" && continue;
    printf "ERROR: %s is not a file or a directory


for ROI_DIR in "${ROIS[@]}"; do

        for ROI in "${ROI_DIR}/*"; do
            CheckForNii "$ROI";
            fslmeants \
                -i "$IMG" \
                -o "${SUBDIR}/${BN_IMG}_${BN_ROI}.txt" \
                -m "$ROI" \
                --transpose;
            done
        done
    done



IMG_EXT="${IMG#*.}"
BN_IMG=$(basename "$IMG" "$IMG_EXT")
SUBDIR="${OUTDIR:-$(pwd)}/${IMG}_TS"
