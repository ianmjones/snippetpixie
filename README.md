[![Platform](https://img.shields.io/badge/platform-elementary-64BAFF.svg?logo=elementary&style=flat&logoColor=white)](https://appcenter.elementary.io/com.github.bytepixie.snippetpixie) [![Build Status](https://travis-ci.com/bytepixie/snippetpixie.svg?branch=master)](https://travis-ci.com/bytepixie/snippetpixie) [![GitHub tag (latest SemVer)](https://img.shields.io/github/tag/bytepixie/snippetpixie.svg)](https://github.com/bytepixie/snippetpixie/releases) [![GitHub issues](https://img.shields.io/github/issues/bytepixie/snippetpixie.svg)](https://github.com/bytepixie/snippetpixie/issues) [![GitHub pull requests](https://img.shields.io/github/issues-pr/bytepixie/snippetpixie.svg)](https://github.com/bytepixie/snippetpixie/pulls) ![GitHub](https://img.shields.io/github/license/bytepixie/snippetpixie.svg)


<p align="center">
  <img src="data/icons/128/com.github.bytepixie.snippetpixie.svg" alt="Icon" width="128" height="128" />
</p>
<h1 align="center">Snippet Pixie</h1>
<p align="center">
    <a href="https://appcenter.elementary.io/com.github.bytepixie.snippetpixie><img src="https://appcenter.elementary.io/badge.svg?new" alt="Get it on AppCenter" /></a>
</p>

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

* Proper icon!
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
