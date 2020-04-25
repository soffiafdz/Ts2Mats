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
    %s -i sub1-ses1.nii -i sub1-ses2.nii -i sub1-ses3.nii -r atlas/rois
    %s -i proj/subs1 -i proj/subs2 -r atlas/power -r atlas/dosenbach\n" \
    "$0" "$0";
    exit
}

err(){
    echo "[$(date +'%Y-%m-%dT%H:%M:%S%z')]:" >&2
    printf $* >&2
    exit 1;
}

## If no argments, print help and exit
[[ $# -eq 0 ]] && usage && exit

## Check FSL is installed and fslmeants executable
fslmeants &>/dev/null \
    || err "ERROR: fslmeants is not executable or not found in PATH.
Check FSL installation"

## Argument parser
while getopts "hi:r:o:" arg; do
    case "$arg" in
        -i) [ -e "$OPTARG" ] \
                || err "%s not found.\n" "$OPTARG";
            INPUTS+=("$OPTARG");;
        -r) [ -d "$OPTARG" ] \
                || err "%s is not a directory.\n" "$OPTARG";
            [ -e "$OPTARG" ] \
                || err "%s not found.\n" "$OPTARG";
            ROIS+=("$OPTARG");;
        -o) [ -d "$OPTARG" ] \
                || err "%s is not a directory.\n" "$OPTARG";
            [ -e "$OPTARG" ] \
                || err "%s not found.\n" "$OPTARG";
            OUTDIR="$OPTARG";;
        -h) usage; exit;;
        :) err "Missing argument for -%s.\n" "$OPTARG";;
        ?) err "Illegal option: %s.\n" "$OPTARG";;
    esac
done

## Functions
Get_Extension(){

CheckForNii(){
    EXT="${1#*.}"
    [ "$EXT" != "nii" ] && [ "$EXT" != "nii.gz" ] \
        && printf "ERROR: %s is not a NIfTI image\n" "$1" \
        && continue
}



## Main

# Set OUTDIR to working directory if not set
${OUTDIR:=`pwd`}

# Sort IN values into Directories and Files
for INPUT in "${INPUTS[@]}"; do
    [ ! -e "$INPUT" ] && printf "ERROR: %s not found." "$INPUT" && continue;
    [ -f "$INPUT" ] && IN_FILES+="$INPUT" && continue;
    [ -d "$INPUT" ] && IN_DIRS+="$INPUT" && continue;
    printf "ERROR: %s is not a valid file or directory." "$INPUT"
done


for ROI_DIR in "${ROIS[@]}"; do

        for ROI in "${ROI_DIR}/*"; do
            CheckForNii "$ROI";
            fslmeants \
                -i "$IMAGE" \
                -o "${OUTDIR}/${BN_IMG}_${BN_ROI}.txt" \
                -m "$ROI" \
                --transpose;
            done
        done
    done



IMG_EXT="${IMG#*.}"
BN_IMG=$(basename "$IMG" "$IMG_EXT")
SUBDIR="${OUTDIR:-$(pwd)}/${IMG}_TS"
