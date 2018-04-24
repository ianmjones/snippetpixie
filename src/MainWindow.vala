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
    public Gtk.SearchEntry search_entry { get; private set; }

    private Settings settings;
    private Gtk.Paned main_hpaned;
    private WelcomeView welcome;
    private Granite.Widgets.SourceList snippet_list;
    
    public MainWindow (Gtk.Application application) {
        Object (
            application: application,
            height_request: 600,
            icon_name: "com.bytepixie.snippet-pixie",
            resizable: true,
            title: _("Snippet Pixie"),
            width_request: 800
        );
    }

    construct {
        settings = new Settings ("com.bytepixie.snippet-pixie");

        var add_button = new Gtk.Button.from_icon_name ("document-new", Gtk.IconSize.LARGE_TOOLBAR);
        //play_button.action_name = ACTION_PREFIX + ACTION_PLAY;
        add_button.tooltip_text = _("Add snippet");

        var import_button = new Gtk.Button.from_icon_name ("document-import", Gtk.IconSize.LARGE_TOOLBAR);
        //next_button.action_name = ACTION_PREFIX + ACTION_PLAY_NEXT;
        import_button.tooltip_text = _("Import snippets…");

        var export_button = new Gtk.Button.from_icon_name ("document-export", Gtk.IconSize.LARGE_TOOLBAR);
        //next_button.action_name = ACTION_PREFIX + ACTION_PLAY_NEXT;
        export_button.tooltip_text = _("Export snippets…");

        search_entry = new Gtk.SearchEntry ();
        search_entry.valign = Gtk.Align.CENTER;
        search_entry.placeholder_text = _("Search Snippets");
 
        // Preferences menu etc.
        var import_menuitem = new Gtk.MenuItem.with_label (_("Import snippets…"));
        //import_menuitem.action_name = ACTION_PREFIX + ACTION_IMPORT;

        var export_menuitem = new Gtk.MenuItem.with_label (_("Export snippets…"));
        //export_menuitem.action_name = ACTION_PREFIX + ACTION_EXPORT;

        var preferences_menuitem = new Gtk.MenuItem.with_label (_("Preferences"));
        //preferences_menuitem.activate.connect (editPreferencesClick);

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
       
        var headerbar = new Gtk.HeaderBar ();
        headerbar.show_close_button = true;
        headerbar.pack_start (add_button);
        headerbar.pack_start (import_button);
        headerbar.pack_start (export_button);
        headerbar.pack_end (menu_button);
        headerbar.pack_end (search_entry);
        headerbar.set_title (_("Snippet Pixie"));
        headerbar.show_all ();
 
        var left_pane = new Gtk.Grid ();
        left_pane.orientation = Gtk.Orientation.VERTICAL;

        snippet_list = new Granite.Widgets.SourceList();
        var root = snippet_list.root;

        // TODO: Get snippets from settings/database.
        // TODO: Maybe use snippet groups?
        var spr = new Granite.Widgets.SourceList.Item ("spr`");
        root.add (spr);
        var sprt = new Granite.Widgets.SourceList.Item ("sprt`");
        root.add (sprt);

        left_pane.add (snippet_list);

        var right_pane = new Gtk.Grid ();
        right_pane.orientation = Gtk.Orientation.VERTICAL;

        welcome = new WelcomeView();
        right_pane.add (welcome);

        main_hpaned = new Gtk.Paned (Gtk.Orientation.HORIZONTAL);
        main_hpaned.pack1 (left_pane, false, false);
        main_hpaned.pack2 (right_pane, true, false);
        main_hpaned.position = 100; // TODO: Get from settings, enforce minimum.
        main_hpaned.show_all ();
        
        this.add (main_hpaned);
        this.set_titlebar (headerbar);
    }
}
