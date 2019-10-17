snippetpixie(1)

# NAME

snippetpixie - Your little expandable text snippet helper.

# DESCRIPTION

Save your often used text snippets and then expand them whenever you type their
abbreviation.

For example:- "spr`" expands to "Snippet Pixie rules!"

# SYNOPSIS

*com.github.bytepixie.snippetpixie* [*--show*]

*com.github.bytepixie.snippetpixie* *--start*

*com.github.bytepixie.snippetpixie* *--stop*

*com.github.bytepixie.snippetpixie* *--autostart=*{*on*|*off*|*status*}

*com.github.bytepixie.snippetpixie* *--status*

*com.github.bytepixie.snippetpixie* *-e*|*--export* _filename_

*com.github.bytepixie.snippetpixie* *-i*|*--import* _filename_ [*--force*]

*com.github.bytepixie.snippetpixie* *--version*

*com.github.bytepixie.snippetpixie* *-h*|*--help*

# OPTIONS

*--show*
	Show Snippet Pixie's window (default action).

*--start*
	Start with no window.

*--stop*
	Fully quit the application, including the background process.

*--autostart=*{*on*|*off*|*status*}
	Turn auto start of Snippet Pixie on login, on, off, or show status of
	setting.

*--status*
	Shows status of the application, exits with status 0 if running, 1 if not.

*-e*, *--export=*_filename_
	Export snippets to file.

*-i*, *--import=*_filename_
	Import snippets from file, skips snippets where abbreviation already exists.

*--force*
	If used in conjunction with import, existing snippets with same abbreviation
	are updated.

*--version*
	Display version number.

*-h*, *--help*
	Display help.

# NOTES

- Only works with accessible applications with simple(ish) text entry.
- Does not work with Chromium/WebKit based browsers because they have "very limited support" for ATK on Linux (see https://www.chromium.org/developers/design-documents/accessibility#TOC-API-support & https://www.chromium.org/developers/accessibility/linux-accessibility).
- Does not work with Electron based apps because they use Chrome under the hood.

# AUTHORS

Created and maintained by Ian Jones <ian@ianmjones.com>, supported by Byte Pixie Limited <hello@bytepixie.com> and other generous contributors of skills, time, and funds. Up to date sources can be found at https://github.com/bytepixie/snippetpixie, where bug reports and feature requests may also be submitted.
