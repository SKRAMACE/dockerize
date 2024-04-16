#!/bin/bash

IMAGE="imhex"
ENTRY_CMD="imhex"

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
TEMP=$(mktemp -d -p $TEMPDIR)
VOL="-v $TEMP:/host"
VOL+=" -v /usr/share/imhex:/usr/share/imhex"
VOL+=" -v /usr/local/share/imhex:/usr/local/share/imhex"
VOL+=" -v /usr/share/licenses/imhex:/usr/share/licenses/imhex"
VOL+=" -v /usr/share/imhex/metainfo:/usr/share/metainfo"

CMD="docker run -it --rm  $USE_GUI $VOL $IMAGE $ENTRY_CMD"
if [ -v dryrun ]; then
    echo $CMD
else
    $CMD
fi
