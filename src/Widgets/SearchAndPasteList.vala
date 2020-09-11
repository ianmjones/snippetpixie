/*
* Copyright (c) 2020 Byte Pixie Limited (https://www.bytepixie.com)
* Copyright (c) 2017 David Hewitt (https://github.com/davidmhewitt)
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
*
* Based on Clipped's ClipboardListBox.vala
* https://github.com/davidmhewitt/clipped/blob/b00d44757cc2bf7bc9948d535668099db4ab9896/src/Widgets/ClipboardListBox.vala
*/

public class SnippetPixie.SearchAndPasteList : Gtk.ListBox {

    public SearchAndPasteList () {
        set_selection_mode (Gtk.SelectionMode.SINGLE);
    }
}
