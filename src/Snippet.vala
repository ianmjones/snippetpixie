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

public class SnippetPixie.Snippet : Object {
    public virtual int id { get; construct set; }
    public virtual string abbreviation { get; set; default = _("new") + "`"; }
    public virtual string body { get; set; default = _("Something to be replaced"); }
    public virtual DateTime last_used { get; set; }

    // public Snippet (int id) {
    //     this.id = id;
    // }

    public string trigger () {
        return abbreviation.reverse ().get_char (0).to_string ();
    }
}
