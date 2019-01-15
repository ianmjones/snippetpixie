/*
* Copyright (c) 2018 Byte Pixie Limited (https://www.bytepixie.com)
*
* This program is free software; you can redistribute it and/or
* modify it under the terms of the GNU General Public
* License as published by the Free Software Foundation; either
* version 2 of the License, or (at your option) any later version.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
* General Public License for more details.
*
* You should have received a copy of the GNU General Public
* License along with this program; if not, write to the
* Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
* Boston, MA 02110-1301 USA
*/

public class SnippetPixie.FramedTextView : Gtk.Frame {
    private Gtk.TextView textview;

    construct {
        textview = new Gtk.TextView ();
        textview.wrap_mode = Gtk.WrapMode.WORD_CHAR;
        textview.focus.connect ((direction) => {
            if (direction == Gtk.DirectionType.TAB_FORWARD || direction == Gtk.DirectionType.TAB_BACKWARD) {
                textview.select_all (true);
            }
        });

        var scroll = new Gtk.ScrolledWindow (null, null);
        scroll.set_policy (Gtk.PolicyType.EXTERNAL, Gtk.PolicyType.AUTOMATIC);
        scroll.add (textview);

        add (scroll);
    }

    public Gtk.TextBuffer buffer {
        get { return textview.buffer; }
        set { textview.buffer = value; }
    }
}
