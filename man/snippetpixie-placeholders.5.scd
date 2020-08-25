snippetpixie-placeholders(5) "" "Placeholders Format Manual"

# NAME

snippetpixie-placeholders - placeholders that can be used in snippetpixie abbreviation bodies

# SYNTAX

All placeholders are delimited (wrapped) by *$$*, with the placeholder name starting with an *@* symbol.

For example, today's date can be inserted with *$$@date$$*.

Some placeholders allow for extra arguments when *:* follows their name and that is followed by the argument. For example a format for a date, or the abbreviation for a snippet. Check the following descriptions for each placeholder for more details.

To use *$$* in your snippet body, escape the second *$* with a backslash like so: *$\\$*.

# @DATE & @TIME

Quick Examples:

- Today's date with system format: *$$@date$$*
- Today's date with custom format: *$$@date:%Y-%m-%d %H:%M:%S$$*
- Tomorrow's date with system format: *$$@date@+1D$$*
- Date 2 weeks from today with custom format: *$$@date@+2W:%x$$*
- Time 3 hours from now: *$$@time@+3H$$*

*@time* is an alias for *@date*, with one important difference, the default output if no format specified is the default time format (*%X*) rather than default date format (*%x*).

The optional format specified after *:* can take a format string as detailed in the GLib.DateTime.format function's docs, see https://valadoc.org/glib-2.0/GLib.DateTime.format.html.

The optional date calculation starts with an *@* after the placeholder name, followed by a signed integer and unit. The unit types are as follows:

- *Y:* Years
- *M:* Months
- *W:* Weeks
- *D:* Days
- *h:* Hours
- *m:* Minutes
- *s:* Seconds

You can apply more than one date calculation, for example *+2h+30m* adds 2 hours and 30 minutes to the current time.

You can use both positive (*+*) and negative calculations, for example *-3D* takes 3 days from the current date.

# @CLIPBOARD

When *$$@clipboard$$* is part of a snippet's body, when its abbreviation is expanded the current text contents of the clipboard will replace the placeholder.

# @SNIPPET

You can have up to three levels of embedded snippets with the *@snippet* placeholder.

The abbreviation for the snippet to be embedded is entered after *:*, for example *$$@snippet:sigg;$$* expands the snippet with abbreviation *sigg;* in place of the placeholder.

# @CURSOR

Adding *$$@cursor$$* to a snippet's body will put the cursor in its place after expansion instead of at the end of the expanded text.

If *$$@cursor$$* is entered more than once in a snippet's body or via snippet embedding, then the last occurrence of the cursor placeholder wins.

The @cursor placeholder does not work when using the shortcut to open the search and paste window rather than auto-expansion.

# SEE ALSO

snippetpixie(1)

# AUTHORS

Created and maintained by Ian Jones <ian@ianmjones.com>, supported by Byte Pixie Limited <hello@bytepixie.com> and other generous contributors of skills, time, and funds. Up to date sources can be found at https://github.com/bytepixie/snippetpixie, where bug reports and feature requests may also be submitted.
