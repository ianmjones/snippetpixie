#!/usr/bin/env bash

cd `dirname "$0"`

#
# We'll update translations and then just run tests as they also build the binary.
#
cd build/
ninja com.github.bytepixie.snippetpixie-pot
ninja com.github.bytepixie.snippetpixie-update-po
ninja extra-pot
ninja extra-update-po
ninja test
