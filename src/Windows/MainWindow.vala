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

public class SnippetPixie.MainWindow : Gtk.ApplicationWindow {
    public signal void search_changed (string search_term);
    public signal void search_escaped ();

    public weak SnippetPixie.Application app { get; construct; }

    public SimpleActionGroup actions { get; construct; }

    public const string ACTION_PREFIX = "win.";
    public const string ACTION_ADD = "action_add";
    // public const string ACTION_UNDO = "action_undo";
    // public const string ACTION_REDO = "action_redo";
    public const string ACTION_IMPORT = "action_import";
    public const string ACTION_EXPORT = "action_export";
    public const string ACTION_SEARCH = "action_search";
    public const string ACTION_ABOUT = "action_about";

    public static Gee.MultiMap<string, string> action_accelerators = new Gee.HashMultiMap<string, string> ();

    private const ActionEntry[] action_entries = {
        { ACTION_ADD, action_add },
        // { ACTION_UNDO, action_undo, null, 0 },
        // { ACTION_REDO, action_redo, null, 0 },
        { ACTION_IMPORT, action_import },
        { ACTION_ABOUT, action_about }
    };

    private Settings settings;
    private MainWindowHeader headerbar;
    private ViewStack main_view;

    public MainWindow (SnippetPixie.Application application) {
        Object (
            app: application,
            height_request: 600,
            icon_name: Application.ID,
            resizable: true,
            title: "Snippet Pixie",
            width_request: 800
        );
    }

    static construct {
        action_accelerators.set (ACTION_ADD, "<Control>n");
        action_accelerators.set (ACTION_IMPORT, "<Control>o");
        action_accelerators.set (ACTION_EXPORT, "<Control>s");
        action_accelerators.set (ACTION_SEARCH, "<Control>f");
    }

    construct {
        settings = new Settings (Application.ID);

        actions = new SimpleActionGroup ();
        actions.add_action_entries (action_entries, this);
        actions.add_action (settings.create_action ("autostart"));
        actions.add_action (settings.create_action ("auto-expand"));
        actions.add_action (settings.create_action ("search-selected-text"));
        actions.add_action (settings.create_action ("focus-search"));
        insert_action_group ("win", actions);

        foreach (var action in action_accelerators.get_keys ()) {
            var accels_array = action_accelerators[action].to_array ();
            accels_array += null;

            app.set_accels_for_action (ACTION_PREFIX + action, accels_array);
        }

        var window_x = settings.get_int ("window-x");
        var window_y = settings.get_int ("window-y");
        var window_width = settings.get_int ("window-width");
        var window_height = settings.get_int ("window-height");

        if (window_x != -1 ||  window_y != -1) {
            this.move (window_x, window_y);
        }

        if (window_width != -1 ||  window_width != -1) {
            this.set_default_size (window_width, window_height);
        }

        // Construct window's components.
        main_view = new ViewStack ();
        this.add (main_view);

        headerbar = new MainWindowHeader ();
        headerbar.search_changed.connect ((search_term) => {
            search_changed (search_term);
        });
        headerbar.search_escaped.connect (() => {
            search_escaped ();
        });
        this.set_titlebar (headerbar);

        // Depending on whether there are snippets or not, might set "snippets" visible etc.
        update_ui (app.snippets_manager.snippets);
        app.snippets_manager.snippets_changed.connect (update_ui);
    }

    private void update_ui (Gee.ArrayList<Snippet> snippets, string reason = "update") {
        SimpleAction export_action = (SimpleAction) actions.lookup_action (ACTION_EXPORT);
        SimpleAction search_action = (SimpleAction) actions.lookup_action (ACTION_SEARCH);

        if (snippets.size > 0) {
            if (reason != "remove") {
                main_view.visible_child_name = "snippets";
            }

            if (export_action == null) {
                export_action = new SimpleAction (ACTION_EXPORT, null);
                export_action.activate.connect (action_export);
                actions.add_action (export_action);
            }
            if (search_action == null) {
                search_action = new SimpleAction (ACTION_SEARCH, null);
                search_action.activate.connect (action_search);
                actions.add_action (search_action);
            }
        } else {
            main_view.visible_child_name = "welcome";

            if (export_action != null) {
                actions.remove_action (ACTION_EXPORT);
            }
            if (search_action != null) {
                actions.remove_action (ACTION_SEARCH);
            }
        }
    }

    private void action_add () {
        app.snippets_manager.add (new Snippet ());
        main_view.select_latest_item ();
    }

    private void action_import () {
        var diag = new Gtk.FileChooserNative (_("Import Snippets"), this, Gtk.FileChooserAction.OPEN, _("Import"), null);
        var response =  diag.run ();

        if (response == Gtk.ResponseType.ACCEPT) {
            var overwrite = false;
            if (app.snippets_manager.snippets.size > 0) {
                var cancel = false;
                var overwrite_diag = new Granite.MessageDialog.with_image_from_icon_name (_("Overwrite Duplicate Snippets?"), _("If any of the snippet abbreviations about to be imported already exist, do you want to skip importing them or update the existing snippet?"), "dialog-warning", Gtk.ButtonsType.NONE);
                overwrite_diag.add_button (_("Update Existing"), 1);
                overwrite_diag.add_button (_("Cancel"), 0);
                overwrite_diag.add_button (_("Skip Duplicates"), 2);
                overwrite_diag.set_default_response (2);
                overwrite_diag.response.connect ((response_id) => {
                    switch (response_id) {
                        case 1:
                            overwrite = true;
                            break;
                        case 2:
                            overwrite = false;
                            break;
                        default:
                            cancel = true;
                            break;
                    }
                });
                overwrite_diag.run ();
                overwrite_diag.destroy ();

                if (cancel) {
                    return;
                }
            }

            var filepath  = diag.get_filename ();
            var result = app.snippets_manager.import_from_file (filepath, overwrite);

            if (result == 0) {
                var cheer = new Granite.MessageDialog.with_image_from_icon_name (_("Imported Snippets"), _("Your snippets were successfully imported."), "document-import", Gtk.ButtonsType.CLOSE);
                cheer.run ();
                cheer.destroy ();
            } else {
                var boo = new Granite.MessageDialog.with_image_from_icon_name (_("Failed to import selected file"), _("Snippet Pixie can currently only import the JSON format files that it also exports."), "dialog-error", Gtk.ButtonsType.CLOSE);
                boo.run ();
                boo.destroy ();
            }
        }
    }

    private void action_export () {
        var diag = new Gtk.FileChooserNative (_("Export Snippets"), this, Gtk.FileChooserAction.SAVE, null, null);
        var response =  diag.run ();

        if (response == Gtk.ResponseType.ACCEPT) {
            var filepath  = diag.get_filename ();
            var result = app.snippets_manager.export_to_file (filepath);

            if (result == 0) {
                var cheer = new Granite.MessageDialog.with_image_from_icon_name (_("Exported Snippets"), _("Your snippets were successfully exported."), "document-export", Gtk.ButtonsType.CLOSE);
                cheer.run ();
                cheer.destroy ();
            } else {
                var boo = new Granite.MessageDialog.with_image_from_icon_name (_("Failed to export to file"), _("Something went wrong, sorry."), "dialog-error", Gtk.ButtonsType.CLOSE);
                boo.run ();
                boo.destroy ();
            }
        }
    }

    private void action_search () {
        if (headerbar.search_entry != null) {
            headerbar.search_entry.grab_focus ();
        }
    }

    private void action_about () {
        Gtk.AboutDialog dialog = new Gtk.AboutDialog ();
        dialog.set_destroy_with_parent (true);
        dialog.set_transient_for (this);
        dialog.set_modal (true);

        dialog.authors = {"@ianmjones https://github.com/ianmjones/"};
        dialog.translator_credits = _("""@NathanBnm https://github.com/NathanBnm/
            @Vistaus https://github.com/Vistaus/""");

        dialog.program_name = "Snippet Pixie";
        dialog.copyright = _("Copyright © Byte Pixie Limited");
        dialog.logo_icon_name = Application.ID;
        dialog.version = Application.VERSION;

        dialog.license_type = Gtk.License.GPL_2_0;

        dialog.website = "https://www.snippetpixie.com/";
        dialog.website_label = "www.snippetpixie.com";

        dialog.response.connect ((response_id) => {
            if (response_id == Gtk.ResponseType.CANCEL || response_id == Gtk.ResponseType.DELETE_EVENT) {
                dialog.hide_on_delete ();
            }
        });

        // Show the dialog:
        dialog.present ();
    }
}
