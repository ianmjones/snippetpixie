#!/usr/bin/env bash

cd `dirname "$0"`

#
# Clean out any previous artifacts.
#
rm -rf ./build ./parts ./prime ./stage ./snap ./snippetpixie_*

#
# Set up local environment.
#
meson build --prefix=/usr
