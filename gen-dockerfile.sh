#!/bin/bash

# Default Values
if [ -v GENDOCKER_IMAGE ]; then
    image=$GENDOCKER_IMAGE
else
    image="ubuntu:latest"
fi

if [ -v GENDOCKER_TIMEZONE ]; then
    timezone=$GENDOCKER_TIMEZONE
else
    timezone="UTC"
fi

# Dockerfile Build Functions
init() {
    echo "# $dockerfile auto generated on $(date)" >$dockerfile
}

append_line() {
    echo "$1" >>$dockerfile
}

append_section() {
    append_line "$1"
    echo "" >>$dockerfile
}

from() {
    append_section "$(cat <<EOF
FROM $image
EOF
)"
}

tz_data() {
    append_section "$(cat <<EOF
# Fixes tzdata hang
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=$timezone
EOF
)"
}

apt_get_build() {
    echo ""
}

git_clone() {
    echo ""
}

setup_scripts() {
    echo ""
}

cmake_build() {
    echo ""
}

setup_gui() {
    echo ""
}

# Arg Parsing
print_usage() {
    echo "Usage: $0 [OPTIONS] [NAME]"
    echo "Options:"
    echo "  -h, --help               Display this help message"
    echo "  -i, --image [STRING]     default value ($image)"
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
        -i|--image)
            image="$1"
            shift
            ;;
        -t|--timezone)
            timezone="$1"
            shift
            ;;
        -*)
            echo "Error: Unknown option: $1" >&2
            usage
            exit 1
            ;;
        *)
            positional_args+=("$s")
            ;;
    esac
done 

# Check positional args
if [[ ${#positional_args[@]} -gt 0 ]]; then
    name=${positional_args[0]}
fi

dockerfile="Dockerfile"
if [ ! -z $name ]; then
    dockerfile+=".$name"
fi

init
from
tz_data
