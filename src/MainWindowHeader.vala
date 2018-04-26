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

public class MainWindowHeader : Gtk.HeaderBar {
    public Gtk.SearchEntry search_entry { get; private set; }
    
    public signal void add_snippet ();
    public signal void import_snippets ();
    public signal void export_snippets ();
    public signal void show_preferences ();

    construct {
        var add_button = new Gtk.Button.from_icon_name ("document-new", Gtk.IconSize.LARGE_TOOLBAR);
        add_button.tooltip_text = _("Add snippet");
        add_button.clicked.connect (() => {
            add_snippet ();
        });

        var import_button = new Gtk.Button.from_icon_name ("document-import", Gtk.IconSize.LARGE_TOOLBAR);
        import_button.tooltip_text = _("Import snippets…");
        import_button.clicked.connect (() => {
            import_snippets ();
        });

        var export_button = new Gtk.Button.from_icon_name ("document-export", Gtk.IconSize.LARGE_TOOLBAR);
        export_button.tooltip_text = _("Export snippets…");
        export_button.clicked.connect (() => {
            export_snippets ();
        });

        search_entry = new Gtk.SearchEntry ();
        search_entry.valign = Gtk.Align.CENTER;
        search_entry.placeholder_text = _("Search Snippets");
 
        // Preferences menu etc.
        var import_menuitem = new Gtk.MenuItem.with_label (_("Import snippets…"));
        import_menuitem.activate.connect (() => {
            import_snippets ();
        });
        var export_menuitem = new Gtk.MenuItem.with_label (_("Export snippets…"));
        export_menuitem.activate.connect (() => {
            export_snippets ();
        });
        var preferences_menuitem = new Gtk.MenuItem.with_label (_("Preferences"));
        preferences_menuitem.activate.connect (() => {
            show_preferences ();
        });

        var menu = new Gtk.Menu ();
        menu.append (import_menuitem);
        menu.append (export_menuitem);
        menu.append (new Gtk.SeparatorMenuItem ());
        menu.append (preferences_menuitem);
        menu.show_all ();

        var menu_button = new Gtk.MenuButton ();
        menu_button.image = new Gtk.Image.from_icon_name ("open-menu", Gtk.IconSize.LARGE_TOOLBAR);
        menu_button.popup = menu;
        menu_button.valign = Gtk.Align.CENTER;
       
        show_close_button = true;
        pack_start (add_button);
        pack_start (import_button);
        pack_start (export_button);
        pack_end (menu_button);
        pack_end (search_entry);
        set_title (_("Snippet Pixie"));
        show_all ();
     }
}
