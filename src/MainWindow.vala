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

public class MainWindow : Gtk.ApplicationWindow {
    private Settings settings;

    public MainWindow (Gtk.Application application) {
        Object (
            application: application,
            height_request: 500,
            icon_name: "com.bytepixie.snippet-pixie",
            resizable: true,
            title: _("Snippet Pixie"),
            width_request: 700
        );
    }

    construct {
        settings = new Settings ("com.bytepixie.snippet-pixie");
    }
}
