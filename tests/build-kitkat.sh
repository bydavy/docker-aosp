#!/bin/bash
#
# Test script file that maps itself into a docker container and runs
#
# Example invocation:
#
# $ AOSP_VOL=$PWD/build ./build-kitkat.sh
#
set -ex

if [ "$1" = "docker" ]; then
    branch=android-4.4.4_r2.0.1
    cpus=$(grep ^processor /proc/cpuinfo | wc -l)

    repo init -u https://android.googlesource.com/platform/manifest -b $branch
    repo sync -j $cpus

    prebuilts/misc/linux-x86/ccache/ccache -M 10G

    source build/envsetup.sh
    lunch aosp_arm-eng
    make -j $cpus
else
    aosp_url="https://raw.githubusercontent.com/kylemanna/docker-aosp/master/utils/aosp"
    args="run.sh docker"
    export AOSP_EXTRA_ARGS="-v $(cd $(dirname $0) && pwd -P)/$(basename $0):/usr/local/bin/run.sh:ro"

    #
    # Try to invoke the aosp wrapper with the following priority:
    #
    # 1. If AOSP_BIN is set, use that
    # 2. If aosp is found in the shell $PATH
    # 3. Grab it from the web
    #
    if [ -n "$AOSP_BIN" ]; then
        $AOSP_BIN $args
    elif [ -x "../utils/aosp" ]; then
        ../utils/aosp $args
    elif [ -n "$(type -P aosp)" ]; then
        aosp $args
    else
        if [ -n "$(type -P curl)" ]; then
            bash <(curl -s $aosp_url) $args
        elif [ -n "$(type -P wget)" ]; then
            bash <(wget -q $aosp_url -O -) $args
        else
            echo "Unable to run the aosp binary"
        fi
    fi
fi
