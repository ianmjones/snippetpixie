snippetpixie(1)

# NAME

snippetpixie - Your little expandable text snippet helper.

# DESCRIPTION

Save your often used text snippets and then expand them whenever you type their
abbreviation.

For example:- "spr`" expands to "Snippet Pixie rules!"

# SYNOPSIS

*com.github.bytepixie.snippetpixie* [*--show*] [*--start*] [*--stop*] [*--autostart=*{*on*|*off*|*status*}] [*--status*] [*-e*|*--export* _filename_] [*-i*|*--import* _filename_ [*--force*]] [*--version*] [*-h*|*--help*]

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

# AUTHORS

Created and maintained by Ian Jones <ian@ianmjones.com>, supported by Byte Pixie Limited <hello@bytepixie.com> and other generous contributors of skills, time, and funds. Up to date sources can be found at https://github.com/bytepixie/snippetpixie, where bug reports and feature requests may also be submitted.
