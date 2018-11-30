# Snippet Pixie
[![Get it on AppCenter](https://appcenter.elementary.io/badge.svg)](https://appcenter.elementary.io/com.github.bytepixie.snippetpixie)

Your little expandable snippet helper.

Save your often used snippets and then expand them whenever you type their abbreviation.

For example:- "spr`" expands to "Snippet Pixie rules!"

![Snippet Pixie Edit Screen](data/screenshot.png?raw=true)

![Snippet Pixie Welcome Screen](data/screenshot-2.png?raw=true)

## Knonw Issues

* Only works on Elementary OS
* Only works with accessible applications with simple(ish) text entry
* Does not work with Electron based apps (probably because they have "very limited" support for ATK on Linux)
* Have to add `com.github.bytepixie.snippetpixie --start` to System Settings -> Startup to enable on login
* Kinda a bit flakey (BETA BETA BETA)

## Roadmap

* Automatically add to Startup apps
* Undo/Redo of snippet edits
* Export/Import snippets
* Date/Time placeholders
* Snippet search
* Group snippets?
* Rich text?

## Building, Testing, and Installation

You'll need the following dependencies to build:
* libgtk-3-dev
* libgee-0.8-dev
* libsqlite3-dev
* meson
* valac

Run `meson build` to configure the build environment and then change to the build directory and run `ninja test` to build and run automated tests

    meson build --prefix=/usr 
    cd build
    ninja test

To install, use `ninja install`, then execute with `com.github.bytepixie.snippetpixie`

    sudo ninja install
    com.github.bytepixie.snippetpixie
