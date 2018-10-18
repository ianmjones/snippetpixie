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
*
*/

namespace SnippetPixie {
    public class Application : Gtk.Application {
        public static MainWindow app_window { get; private set; }

        public Application () {
            Object (
                application_id: "com.bytepixie.snippet-pixie",
                flags: ApplicationFlags.FLAGS_NONE
            );
        }

        protected override void activate () {
            build_ui ();
            var display = Gdk.Display.get_default ();
            var seat = display.get_default_seat ();
            var kbd = seat.get_keyboard ();
            message("Keyboard Name: " + kbd.name);
            var windows = Gtk.Window.list_toplevels ();
            windows.foreach ((window) => {
                message("got 1");
                window.key_release_event.connect ((event) => {
                    message("EVENT");
                    message("KeyVal: " + event.keyval.to_string ());
                    return false;
                });
            });
        }

        private void build_ui () {
            if (get_windows ().length () > 0) {
                get_windows ().data.present ();
                return;
            }

            var provider = new Gtk.CssProvider ();
            provider.load_from_resource ("com/bytepixie/snippet-pixie/Application.css");
            Gtk.StyleContext.add_provider_for_screen (Gdk.Screen.get_default (), provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);

            app_window = new MainWindow (this);
            app_window.show_all ();

            var quit_action = new SimpleAction ("quit", null);

            add_action (quit_action);
            set_accels_for_action ("app.quit", {"<Control>q"});

            quit_action.activate.connect (() => {
                if (app_window != null) {
                    app_window.destroy ();
                }
            });

            app_window.state_flags_changed.connect (save_ui_settings);
            app_window.delete_event.connect (save_ui_settings_on_delete);
        }

        private void save_ui_settings () {
            var settings = new Settings ("com.bytepixie.snippet-pixie");

            int window_x, window_y;
            app_window.get_position (out window_x, out window_y);
            settings.set_int ("window-x", window_x);
            settings.set_int ("window-y", window_y);

            int window_width, window_height;
            app_window.get_size (out window_width, out window_height);
            settings.set_int ("window-width", window_width);
            settings.set_int ("window-height", window_height);
        }

        private bool save_ui_settings_on_delete () {
            save_ui_settings ();
            return false;
        }

        public static int main (string[] args) {
            var app = new Application ();
            return app.run (args);
        }
    }
}
