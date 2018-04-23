# Snippet Pixie
[![Get it on AppCenter](https://appcenter.elementary.io/badge.svg)](https://appcenter.elementary.io/com.bytepixie.snippet-pixie)

Your little snippet helper.

Save your often used snippets and then expand them whenever you type their abbreviation.

For example:- "spr`" expands to "Snippet Pixie rules!"

![Snippet Pixie Screenshot](data/screenshot.png?raw=true)

## Building, Testing, and Installation

You'll need the following dependencies to build:
* libgtk-3-dev
* meson
* valac

Run `meson build` to configure the build environment and then change to the build directory and run `ninja test` to build and run automated tests

    meson build --prefix=/usr 
    cd build
    ninja test

To install, use `ninja install`, then execute with `com.bytepixie.snippet-pixie`

    sudo ninja install
    com.bytepixie.snippet-pixie
