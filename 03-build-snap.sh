#!/usr/bin/env bash

cd `dirname "$0"`

#
# Clean out any previous artifacts and then build.
#
snapcraft clean --use-lxd
snapcraft --use-lxd
