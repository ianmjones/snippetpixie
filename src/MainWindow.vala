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
    public SimpleActionGroup actions { get; construct; }

    public const string ACTION_PREFIX = "win.";
    public const string ACTION_ADD = "action_add";
    // public const string ACTION_UNDO = "action_undo";
    // public const string ACTION_REDO = "action_redo";
    public const string ACTION_IMPORT = "action_import";
    public const string ACTION_EXPORT = "action_export";
    public const string ACTION_ABOUT = "action_about";

    private const ActionEntry[] action_entries = {
        { ACTION_ADD, action_add },
        // { ACTION_UNDO, action_undo, null, 0 },
        // { ACTION_REDO, action_redo, null, 0 },
        { ACTION_IMPORT, action_import },
        { ACTION_EXPORT, action_export },
        { ACTION_ABOUT, action_about }
    };

    private Settings settings;
    private MainWindowHeader headerbar;
    private ViewStack main_view;

    public MainWindow (Gtk.Application application) {
        Object (
            application: application,
            height_request: 600,
            icon_name: "com.github.bytepixie.snippetpixie",
            resizable: true,
            title: _("Snippet Pixie"),
            width_request: 800
        );
    }

    construct {
        actions = new SimpleActionGroup ();
        actions.add_action_entries (action_entries, this);
        insert_action_group ("win", actions);

        settings = new Settings ("com.github.bytepixie.snippetpixie");

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
        this.set_titlebar (headerbar);

        // Depending on whether there are snippets or not, might set "snippets" visible.
        if (Application.get_default ().snippets_manager.snippets.size > 0) {
            main_view.visible_child_name = "snippets";
        } else {
            main_view.visible_child_name = "welcome";
        }
        Application.get_default ().snippets_manager.snippets_changed.connect ((snippets) => {
            if (snippets.size > 0) {
                main_view.visible_child_name = "snippets";
            } else {
                main_view.visible_child_name = "welcome";
            }
        });
    }

    private void action_add () {
        Application.get_default ().snippets_manager.add (new Snippet ());
        main_view.select_latest_item ();
    }

    private void action_import () {
        var diag = new Gtk.FileChooserNative (_("Import Snippets"), this, Gtk.FileChooserAction.OPEN, _("Import"), null);
        var response =  diag.run ();

        if (response == Gtk.ResponseType.ACCEPT) {
            var filepath  = diag.get_filename ();
            var result = Application.get_default ().snippets_manager.import_from_file (filepath, false);

            if (result == 0) {
                var cheer = new Granite.MessageDialog.with_image_from_icon_name (_("Imported Snippets"), _("Snippet Pixie successfully imported the file, any existing snippets were not updated. To update existing snippets during import, please use the command line option."), "process-completed", Gtk.ButtonsType.CLOSE);
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
            var result = Application.get_default ().snippets_manager.export_to_file (filepath);

            if (result == 0) {
                var cheer = new Granite.MessageDialog.with_image_from_icon_name (_("Exported Snippets"), _("Your snippets were successfully exported to file."), "process-completed", Gtk.ButtonsType.CLOSE);
                cheer.run ();
                cheer.destroy ();
            } else {
                var boo = new Granite.MessageDialog.with_image_from_icon_name (_("Failed to export to file"), _("Something went wrong, sorry."), "dialog-error", Gtk.ButtonsType.CLOSE);
                boo.run ();
                boo.destroy ();
            }
        }
    }

    private void action_about () {
        Gtk.AboutDialog dialog = new Gtk.AboutDialog ();
        dialog.set_destroy_with_parent (true);
        dialog.set_transient_for (this);
        dialog.set_modal (true);

        dialog.authors = {"Ian M. Jones"};

        dialog.program_name = "Snippet Pixie";
        dialog.copyright = "Copyright © Byte Pixie Limited";
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
