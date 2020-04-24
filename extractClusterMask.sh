#!/bin/sh

######################################################################
# Shell script for extracting the corresponding submasks of every
# one of the indexed images. It implements FSL.
# © 2020 Sofía Fernández, M.Sc. | so1.618e@gmail.com
######################################################################

## Functions for help, usage, and errors.
usage(){
    printf "Usage: %s [-h] <-i IMAGE> <-n NUMBER>\n" "$0";
}

help_msj(){
    usage;
    printf "
    -i\tPath to the Cluster Index image.
    \t\tThe clusters must be assigned a unique number (from 1 to N).
    \t\tThis can be the output of fsl's cluster.
    -n\tNumber of clusters to extract.
    -h\tDisplay this help and exit.\n"
}

exit_error(){
   usage;
   exit 1;
}

## Argument parser
while getopts "hi:n:" OPT; do
    case "$OPT" in
        h) help_msj;
            exit;;
        i) [ -f $OPTARG ] \
                || printf "ERROR: %s is not a file.\n" "$OPTARG" >&2 \
                && exit_error;
            [ -e $OPTARG ] \
                || printf "ERROR: Could not find %s.\n" "$OPTARG" >&2 \
                && exit_error;
            IMAGE=$OPTARG;;
        n) [ $NUM =~ '^[0-9]+$' ] \
                || printf "ERROR: %s must be a positive whole number.\n" \
                    "$OPTARG" >&2 \
                && exit_error;
            [ $NUM -eq "0" ] \
                && printf "ERROR: %s must be greater than zero.\n" \
                    "$OPTARG" >&2 \
                && exit_error;
                NUM=$OPTARG;;
        :) printf "Missing argument for -%s.\n" "$OPTARG" >&2;
            exit_error;;
        ?) printf "Illegal option: %s.\n" "$OPTARG" >&2;
            exit_error;;
    esac
done

## Main

# Derivated variables
EXT=${IMAGE#*.};
BNAME=$(basename "$IMAGE" "$EXT");
OUTDIR="${BNAME}_masks";

# Create directory for outputs with same name as the input IMAGE
mkdir "$OUTDIR";

# Loop through the number of clusters requested in NUM.
# Implementation of fslmaths extracting the indexed cluster.

for INDEX in {1.."$NUM"}; do
    OUTPUT="${OUTDIR}/${BNAME}_$INDEX"
    fslmaths \
        -dt int \
        -thr "$INDEX" \
        -uthr "$INDEX" \
        -bin \
        "$OUTPUT";
    done
