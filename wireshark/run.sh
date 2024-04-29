#!/bin/bash

IMAGE="wireshark"
ENTRY_CMD="wireshark"

# For using GUI
xhost +local:docker
USE_GUI="-e DISPLAY=$DISPLAY -v /tmp/.X11-unix:/tmp/.X11-unix"

# Temp dir
if [ ! -v TEMPDIR ]; then
    TEMPDIR=/tmp/$IMAGE
fi

if [ ! -d $TEMPDIR ]; then
   mkdir -p $TEMPDIR 
fi

# Arg Parsing
print_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo "Options:"
    echo "  -h, --help               Display this help message"
    echo "  -p, --pcaps              Mount directory to /pcaps in docker container"
    echo "      --dry-run            Print command, but don't run"
}

usage() {
    print_usage | column -t -s ","
}

while [[ $# -gt 0 ]]; do
    s=$1
    shift
    case $s in
        -h|--help)
            usage
            exit 1
            ;;
        -p|--pcaps)
            pcaps=$1
            shift
            ;;
        --dry-run)
            dryrun=True
            ;;
        -*)
            echo "Error: Unknown option: $1" >&2
            usage
            exit 1
            ;;
        *)
            echo "Error: Unknown positional arg: $1" >&2
            usage
            exit 1
            ;;
    esac
done 

# Create temp dir for this run
TEMP=$(mktemp -p $TEMPDIR -d)

VOL="-v $TEMP:/host"
if [ -v pcaps ]; then
    if [ -d $pcaps ]; then
        VOL+=" -v $pcaps:/pcaps"
    fi
fi

CMD="docker run --rm $USE_GUI $VOL $IMAGE $ENTRY_CMD"

if [ -v dryrun ]; then
    echo $CMD
else
    $CMD
fi
