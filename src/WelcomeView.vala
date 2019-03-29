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

public class SnippetPixie.WelcomeView : Gtk.Grid {
    construct {
        var welcome = new Granite.Widgets.Welcome ( "Snippet Pixie", _("No snippets found."));
        welcome.append ("document-new", _("Add Snippet"), _("Create your first snippet."));
        welcome.append ("document-import", _("Import Snippets"), _("Import previously exported snippets."));
        welcome.append ("help-contents", _("Quick Start Guide"), _("Learn the basics of how to use Snippet Pixie."));

        add (welcome);

        welcome.activated.connect ((index) => {
            switch (index) {
                case 0:
                    Utils.action_from_group (MainWindow.ACTION_ADD, Application.get_default ().app_window.actions).activate (null);

                    break;
                case 1:
                    Utils.action_from_group (MainWindow.ACTION_IMPORT, Application.get_default ().app_window.actions).activate (null);

                    break;
                case 2:
                    try {
                        AppInfo.launch_default_for_uri ("https://www.snippetpixie.com/", null);
                    } catch (Error e) {
                        warning (e.message);
                    }

                    break;
            }
        });
    }
}
