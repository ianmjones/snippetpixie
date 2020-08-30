snippetpixie(1)

# NAME

snippetpixie - Your little expandable text snippet helper.

# DESCRIPTION

Save your often used text snippets and then expand them whenever you type their
abbreviation.

For example:- "spr`" expands to "Snippet Pixie rules!"

# SYNOPSIS

*com.github.bytepixie.snippetpixie* [*--show*]

*com.github.bytepixie.snippetpixie* *--search-and-paste*

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

*--search-and-paste*
	Show Snippet Pixie's quick search and paste window.

	A default shortcut of *Ctrl*+*`* for using the search and replace window is installed on first run.

	You should change this to your preferred shortcut via Snippet Pixie's preferences menu or your operating system's settings UI or files.

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

Abbreviations should be short, easy to remember and hard to trigger accidentally.

It helps if an abbreviation includes either a key word from the fully expanded text, or an initialization or acronym that is part of it.

For example, if you regularly wrote "Snippet Pixie" 😉 you might use "*sp*".

However, there are a lot of words that include the letter combination "*sp*", (see https://www.wordfind.com/contains/sp/), so there's a reasonably high chance that Snippet Pixie would expand that abbreviation when you didn't want it to.

So instead it's common to add a "*trigger character*" to the end of the abbreviation. This is commonly a character that isn't found in normal sentences such as "*`*" or "*~*" that is easy to find on your keyboard. Often just appending a space is enough, or doubling up characters.

I personally use "*`*" (commonly known as grav or backtick) a lot as it's a single keystroke on my British layout keyboard just below my Escape key. So for me "*sp`*" is a natural abbreviation for "*Snippet Pixie*".

However, I could see using "*sp *" or "*spp*" for the abbreviation.

If you do use a trailing space as your trigger character you might find it useful to include a trailing space in the text that is expanded, e.g. "*sp *" expands to "*Snippet Pixie *" as it's more natural when typing.

# LIMITATIONS

- Auto-expansion only works on accessible applications, use the shortcut to open the search and paste window for other applications such as browsers and Electron based apps.
- Auto-expansion does not work in terminals, but the shortcut method works with terminals that accept *Ctrl*+*v* for paste such as the elementary OS terminal.
- The cursor placeholder is not supported when using the shortcut method rather than auto-expansion.

# SEE ALSO

snippetpixie-placeholders(5)

# AUTHORS

Created and maintained by Ian Jones <ian@ianmjones.com>, supported by Byte Pixie Limited <hello@bytepixie.com> and other generous contributors of skills, time, and funds. Up to date sources can be found at https://github.com/bytepixie/snippetpixie, where bug reports and feature requests may also be submitted.
