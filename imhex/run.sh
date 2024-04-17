#!/bin/bash

IMAGE="imhex"
CONTAINER="imhex"
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

metainfo_dir="/usr/share/imhex/metainfo"
if [ ! -d $metainfo_dir ]; then
    echo "Initializing metainfo directory ($metainfo_dir)"
    sudo mkdir -p $metainfo
fi

metainfo_xml=(\
    $metainfo_dir/net.werwolv.imhex.appdata.xml \
    $metainfo_dir/net.werwolv.imhex.metainfo.xml \
)
for m in ${metainfo_xml[@]}; do
    if [ -f $m ]; then
        continue
    fi

    echo "Copying: $m"
    # Copy internal metainfo to the host machine
    VOL="-v $metainfo_dir:/host-metainfo"
    metainfo_dir_internal="/usr/share/metainfo"
    src=$metainfo_dir_internal/$(basename $m)
    docker run --rm  $VOL $IMAGE cp $src /host-metainfo/
done

# Create temp dir for this run
VOL="-v /usr/local/imhex:/host"
VOL+=" -v /usr/share/imhex:/usr/share/imhex"
VOL+=" -v /usr/local/share/imhex:/usr/local/share/imhex"
VOL+=" -v /usr/share/licenses/imhex:/usr/share/licenses/imhex"
VOL+=" -v $metainfo_dir:/usr/share/metainfo"

if docker ps -a --format '{{.Names}}' | grep -q "^$CONTAINER$"; then
    CMD="docker start $CONTAINER"
else
    CMD="docker run --name $CONTAINER $USE_GUI $VOL $IMAGE $ENTRY_CMD"
fi

if [ -v dryrun ]; then
    echo $CMD
else
    $CMD
fi
