#!/usr/bin/env bash

cd `dirname "$0"`

#
# Clean out any previous artifacts and then build.
#
flatpak-builder build com.github.bytepixie.snippetpixie.yml --user --install --force-clean
