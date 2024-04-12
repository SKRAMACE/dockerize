#!/bin/bash

init() {
    echo "# $dockerfile auto generated on $(date)" >$dockerfile
}

append_line() {
    echo "$1" >>$dockerfile
}

append_section() {
    append_line $1
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
}

git_clone() {
}

setup_scripts() {
}

cmake_build() {
}

setup_gui() {
}

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

# Function to display usage information
print_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo "Options:"
    echo "  -h, --help               Display this help message"
    echo "  -i, --image [STRING]     default value ($image)"
    echo "  -b, --option2 value      Set option2 to 'value'"
    echo "  -c, --option3 value      Set option3 to 'value'"
}

usage() {
    print_usage | column -t -s ","
    exit 1
}

while [[ $# -gt 0 ]]; do
    s=$1
    shift 1
    case $s in
        -h|--help)
            usage
            ;;
        -i|--image)
            image="$1"
            shift 1
            ;;
        *)
            echo "Error: Unknown option: $1" >&2
            usage
            ;;
    esac
done 

from
tz_data
