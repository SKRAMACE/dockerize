#!/bin/bash

# Import conf file
if [ -v GENDOCKER_CONF ]; then
    conf=$GENDOCKER_CONF
else
    conf=.gendocker
fi

if [ -e $conf ]; then
    . $conf
fi

# Default Values
if [ -v GENDOCKER_IMAGE ]; then
    gendocker_image=$GENDOCKER_IMAGE
elif [ ! -v gendocker_image ]; then
    gendocker_image="ubuntu:latest"
fi

if [ -v GENDOCKER_TIMEZONE ]; then
    timezone=$GENDOCKER_TIMEZONE
elif [ ! -v timezone ]; then
    timezone="UTC"
fi

if [ -v GENDOCKER_USE_GUI ]; then
    gendocker_use_gui=$GENDOCKER_IMAGE
elif [ ! -v gendocker_use_gui ]; then
    gendocker_use_gui="False"
fi

set_outfile() {
    outfile=$1
}

# Dockerfile Build Functions
autogen() {
    echo "# $outfile auto generated on $(date)" >$outfile
}

append_line() {
    echo "$1" >>$outfile
}

append_file() {
    local file=$1
    if [ -e $file ]; then
        append_line "# Concatenated from \"$file\" file"
        cat $file >>$outfile
        empty_line
    fi
}

empty_line() {
    echo "" >>$outfile
}

append_section() {
    append_line "$1"
    empty_line
}


from() {
    append_section "$(cat <<EOF
FROM $gendocker_image
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

pre_build() {
    append_line "# Update apt-get cache"
    append_line "RUN apt-get update -y && \\"
    append_line "    apt-get upgrade -y"
    empty_line

    cmd_len=${#pre_build_apt_get[@]}
    if [[ $cmd_len -gt 0 ]]; then
        append_line "# Install build tools"
        append_line "RUN apt-get install -y \\"
        for ((i = 0; i < cmd_len; i++)); do
            line="    ${pre_build_apt_get[i]}"
            if ((i < cmd_len - 1)); then
                line+=" \\"
            fi
            append_line "$line"
        done
        empty_line
    fi

    if [ -v git_repo ]; then
        if [ ! -v git_repo_target_dir ]; then
            git_repo_target_dir="/opt/$gendocker_name"
        fi

        append_line "# Clone git repo"
        append_line "RUN git clone $git_repo $git_repo_target_dir"
        empty_line
    fi
    
    cmd_len=${#pre_build_cmds[@]}
    if [[ $cmd_len -gt 0 ]]; then
        append_line "# Pre-build commands"
        if [ -v pre_build_workdir ]; then
            append_line "WORKDIR $pre_build_workdir"
        fi

        for ((i = 0; i < cmd_len; i++)); do
            if ((i == 0)); then
                line="RUN "
            else
                line="    "
            fi
            line+="${pre_build_cmds[i]}"
            if ((i < cmd_len - 1)); then
                line+=" && \\"
            fi
            append_line "$line"
        done
        empty_line
    fi

    append_file .pre-build
}

build() {
    append_line "# Build $gendocker_name"
    cmd_len=${#build_cmds[@]}
    if [[ $cmd_len -gt 0 ]]; then
        if [ -v build_workdir ]; then
            append_line "WORKDIR $build_workdir"
        fi

        for ((i = 0; i < cmd_len; i++)); do
            if ((i == 0)); then
                line="RUN "
            else
                line="    "
            fi

            line+="${build_cmds[i]}"
            if ((i < cmd_len - 1)); then
                line+=" && \\"
            fi
            append_line "$line"
        done
    fi

    empty_line
}

post_build() {
    cmd_len=${#post_build_apt_get[@]}
    if [[ $cmd_len -gt 0 ]]; then
        append_line "# Install applications"
        append_line "RUN apt-get install -y \\"
        for ((i = 0; i < cmd_len; i++)); do
            line="    ${post_build_apt_get[i]}"
            if ((i < cmd_len - 1)); then
                line+=" \\"
            fi
            append_line "$line"
        done
        empty_line
    fi

    cmd_len=${#post_build_cmds[@]}
    if [[ $cmd_len -gt 0 ]]; then
        append_line "# Post-build commands"
        if [ -v post_build_workdir ]; then
            append_line "WORKDIR $post_build_workdir"
        fi

        for ((i = 0; i < cmd_len; i++)); do
            if ((i == 0)); then
                line="RUN "
            else
                line="    "
            fi
            line+="${post_build_cmds[i]}"
            if ((i < cmd_len - 1)); then
                line+=" && \\"
            fi
            append_line "$line"
        done
        empty_line
    fi

    append_file .post-build
}

setup_gui() {
    append_line "# GUI Application"
    append_line "RUN apt-get install -y \\"
    append_line "    x11-apps \\"
    append_line "    xterm \\"
    append_line "    && \\"
    append_line "    apt-get clean && \\"
    append_line "    rm -rf /var/lib/apt/lists/*"
    append_line "ENV DISPLAY=:0"
    append_line "CMD [\"xterm\"]"
    empty_line
}

clean_apt_cache() {
    append_line "# Clean apt-get cache"
    append_line "RUN apt-get clean && \\"
    append_line "    rm -rf /var/lib/apt/lists/*"
    empty_line
}

# Arg Parsing
print_usage() {
    echo "Usage: $0 [OPTIONS] [NAME]"
    echo "Options:"
    echo "  -i, --image [STRING]     default value ($gendocker_image)"
    echo "  -g, --gui                default value (False)"
    echo "  -h, --help               Display this help message"
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
            gendocker_image="$1"
            shift
            ;;
        -t|--timezone)
            timezone="$1"
            shift
            ;;
        -g|--gui)
            gendocker_use_gui=True
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
    gendocker_name=${positional_args[0]}
fi

if [ ! -v gendocker_name ]; then
    echo "NAME not found"
    exit 1
fi

dockerfile="Dockerfile"
if [ ! -z $gendocker_name ]; then
    dockerfile+=".$gendocker_name"
fi

set_outfile $dockerfile
autogen
from
tz_data
pre_build
build
post_build

check_boolean() {
    lowercase_input=$(echo "$1" | tr '[:upper:]' '[:lower:]')
    
    # Perform the comparison
    case "$lowercase_input" in
        true|yes|1)
            echo "true"
            ;;
        *)
            echo "false"
            ;;
    esac
}

if [[ $(check_boolean $gendocker_use_gui) == "true" ]]; then
    setup_gui
fi

clean_apt_cache
