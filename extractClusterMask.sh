#!/bin/bash

########################################
# Shell script for extracting the
# corresponding submasks of every
# one of the indexed images.
# It implements FSL.
########################################

usage()
{
    echo "Usage: $0 [-i IMAGE] [-n NUMBER]" 1>&2
}

help()
{
    echo ""
    usage
    echo -e "\t-i Path to the Cluster Index image."
    echo -e "\t\t The clusters must be assigned a unique number (from 1 to N)."
    echo -e "\t\t This can be the output of fsl's cluster."
    echo -e "\t-n Number of clusters to extract."
}

exit_error()
{
   usage
   exit 1
}

while getopts "hi:n:" arg; do
    case "$arg" in
        h) help
            exit
            ;;
        i) IMAGE=$OPTARG
            [[ -f $OPTARG ]] \
                || printf "ERROR: %s is not a file\n" "$OPTARG" >&2 \
                && exit_error
            [[ -e $OPTARG ]] \
                || printf "ERROR: Could not find %s\n" "$OPTARG" >&2 \
                && exit_error
            ;;
        n) NUM=$OPTARG
            [[ $NUM =~ '^[0-9]+$' ]] \
                || printf "ERROR: %s must be a positive whole number\n" \
                    "$OPTARG" >&2 \
                && exit_error
            [[ $NUM -eq "0" ]] \
                && printf "ERROR: %s must be greater than zero\n" \
                    "$OPTARG" >&2 \
                && exit_error
            ;;
        :) printf "Missing argument for -%s\n" "$OPTARG" >&2
            exit_error
            ;;
        ?) printf "Illegal option: -%s\n" "$OPTARG" >&2
            exit_error
            ;;
    esac
done

