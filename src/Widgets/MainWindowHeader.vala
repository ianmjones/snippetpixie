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

public class SnippetPixie.MainWindowHeader : Gtk.HeaderBar {
    public signal void search_changed (string search_term);
    public signal void search_escaped ();
    public Gtk.SearchEntry search_entry;

    construct {
        var app = Application.get_default ();

        var add_button = new Gtk.Button.from_icon_name ("document-new", Gtk.IconSize.LARGE_TOOLBAR);
        add_button.action_name = MainWindow.ACTION_PREFIX + MainWindow.ACTION_ADD;
        add_button.tooltip_markup = Granite.markup_accel_tooltip (
            app.get_accels_for_action (add_button.action_name),
            _("Add Snippet")
        );

        // var undo_button = new Gtk.Button.from_icon_name ("edit-undo", Gtk.IconSize.LARGE_TOOLBAR);
        // undo_button.action_name = MainWindow.ACTION_PREFIX + MainWindow.ACTION_UNDO;
        // undo_button.tooltip_text = _("Undo last edit");

        // var redo_button = new Gtk.Button.from_icon_name ("edit-redo", Gtk.IconSize.LARGE_TOOLBAR);
        // redo_button.action_name = MainWindow.ACTION_PREFIX + MainWindow.ACTION_REDO;
        // redo_button.tooltip_text = _("Redo last undo");

        // Main menu.
        var autostart_menuitem = new Gtk.ModelButton ();
        autostart_menuitem.text = _("Auto start on login");
        autostart_menuitem.action_name = MainWindow.ACTION_PREFIX + "autostart";
        var auto_expand_menuitem = new Gtk.ModelButton ();
        auto_expand_menuitem.text = _("Auto expand Snippets");
        auto_expand_menuitem.action_name = MainWindow.ACTION_PREFIX + "auto-expand";
        var shortcut_sub_menuitem = new Gtk.ModelButton ();
        shortcut_sub_menuitem.text = _("Shortcut");
        shortcut_sub_menuitem.menu_name = "shortcut";
        var import_menuitem = new Gtk.ModelButton ();
        import_menuitem.text = _("Import Snippets…");
        import_menuitem.action_name = MainWindow.ACTION_PREFIX + MainWindow.ACTION_IMPORT;
        import_menuitem.tooltip_markup = Granite.markup_accel_tooltip (
            app.get_accels_for_action (import_menuitem.action_name),
            _("Import Snippets…")
        );
        var export_menuitem = new Gtk.ModelButton ();
        export_menuitem.text = _("Export Snippets…");
        export_menuitem.action_name = MainWindow.ACTION_PREFIX + MainWindow.ACTION_EXPORT;
        export_menuitem.tooltip_markup = Granite.markup_accel_tooltip (
            app.get_accels_for_action (export_menuitem.action_name),
            _("Export Snippets…")
        );
        var about_menuitem = new Gtk.ModelButton ();
        about_menuitem.text = _("About…");
        about_menuitem.action_name = MainWindow.ACTION_PREFIX + MainWindow.ACTION_ABOUT;

        var main_menu = new Gtk.Grid ();
        main_menu.margin_top = main_menu.margin_bottom = 3;
        main_menu.orientation = Gtk.Orientation.VERTICAL;
        main_menu.add (autostart_menuitem);
        main_menu.add (auto_expand_menuitem);
        main_menu.add (shortcut_sub_menuitem);
        main_menu.add (new Gtk.Separator (Gtk.Orientation.HORIZONTAL));
        main_menu.add (import_menuitem);
        main_menu.add (export_menuitem);
        main_menu.add (new Gtk.Separator (Gtk.Orientation.HORIZONTAL));
        main_menu.add (about_menuitem);
        main_menu.show_all ();

        // Shortcut submenu.
        var shortcut_menuitem = new Gtk.ModelButton ();
        shortcut_menuitem.text = _("Shortcut");
        shortcut_menuitem.menu_name = "main";
        shortcut_menuitem.centered = true;
        shortcut_menuitem.inverted = true;
        var search_selected_text_menuitem = new Gtk.ModelButton ();
        search_selected_text_menuitem.text = _("Search selected text");
        search_selected_text_menuitem.action_name = MainWindow.ACTION_PREFIX + "search-selected-text";
        var focus_search_menuitem = new Gtk.ModelButton ();
        focus_search_menuitem.text = _("Focus search box");
        focus_search_menuitem.action_name = MainWindow.ACTION_PREFIX + "focus-search";

        var accel = "";
        string? accel_path = null;

        CustomShortcutSettings.init ();
        foreach (var shortcut in CustomShortcutSettings.list_custom_shortcuts ()) {
            if (shortcut.command == app.SEARCH_AND_PASTE_CMD) {
                accel = shortcut.shortcut;
                accel_path = shortcut.relocatable_schema;
            }
        }

        var shortcut_label = create_label (_("Shortcut:"));
        var shortcut_entry = new ShortcutEntry (accel);
        shortcut_entry.halign = Gtk.Align.END;
        shortcut_entry.margin_end = 12;
        shortcut_entry.shortcut_changed.connect ((new_shortcut) => {
            if (accel_path != null) {
                CustomShortcutSettings.edit_shortcut (accel_path, new_shortcut);
            }
        });

        var shortcut_menu = new Gtk.Grid ();
        shortcut_menu.margin_top = shortcut_menu.margin_bottom = 3;
        shortcut_menu.orientation = Gtk.Orientation.VERTICAL;
        shortcut_menu.attach (shortcut_menuitem, 0, 0, 2);
        shortcut_menu.attach (shortcut_label, 0, 1);
        shortcut_menu.attach (shortcut_entry, 1, 1);
        shortcut_menu.attach (search_selected_text_menuitem, 0, 2, 2);
        shortcut_menu.attach (focus_search_menuitem, 0, 3, 2);
        shortcut_menu.show_all ();

        var popover = new Gtk.PopoverMenu ();
        popover.add (main_menu);
        popover.add (shortcut_menu);
        popover.child_set_property (shortcut_menu, "submenu", "shortcut");

        var menu_button = new Gtk.MenuButton ();
        menu_button.image = new Gtk.Image.from_icon_name ("open-menu", Gtk.IconSize.LARGE_TOOLBAR);
        menu_button.popover = popover;
        menu_button.valign = Gtk.Align.CENTER;

        set_title ("Snippet Pixie");
        show_close_button = true;
        pack_start (add_button);
        // pack_start (undo_button); // TODO: Add undo.
        // pack_start (redo_button); // TODO: Add redo.
        pack_end (menu_button);

        // Hide the search box as necessary.
        update_ui (app.snippets_manager.snippets);
        app.snippets_manager.snippets_changed.connect (update_ui);
    }

    private void enable_search () {
        if (search_entry == null) {
            search_entry = new Gtk.SearchEntry ();
            search_entry.valign = Gtk.Align.CENTER;
            search_entry.placeholder_text = _("Search Snippets");
            search_entry.tooltip_markup = Granite.markup_accel_tooltip (
            Application.get_default ().get_accels_for_action (MainWindow.ACTION_PREFIX + MainWindow.ACTION_SEARCH),
                _("Search Snippets…")
            );
            search_entry.key_press_event.connect ((event) => {
                switch (event.keyval) {
                    case Gdk.Key.Escape:
                        search_entry.text = "";
                        search_escaped ();
                        return true;
                    default:
                        return false;
                }
            });
            search_entry.search_changed.connect (() => {
                search_changed (search_entry.text);
            });
            pack_end (search_entry);
        }

        search_entry.show ();
    }

    private void disable_search () {
        if (search_entry != null) {
            search_entry.hide ();
        }
    }

    private void update_ui (Gee.ArrayList<Snippet> snippets, string reason = "update") {
        if (snippets.size > 0) {
            enable_search ();
            if (reason == "add") {
                search_entry.text = "";
            }
        } else {
            disable_search ();
        }
    }

    private Gtk.Label create_label (string text) {
        var label = new Gtk.Label (text);
        label.hexpand = true;
        label.halign = Gtk.Align.START;
        label.margin_start = 15;
        label.margin_end = 3;

        return label;
    }
}