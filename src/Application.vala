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

        private static Application? _app = null;
        private string version_string = "0.1-dev";

        private bool app_running = false;
        private bool show = true;

        // We need ATK to register all the things.
        //private Atk.NoOpObject noopobj = new Atk.NoOpObject (new Object ());

        // For tracking keystrokes.
        private Atspi.DeviceListenerCB listener_cb;
        private Atspi.DeviceListener listener;

        // FOr tracking currently active application.
        private Atspi.Accessible desktop;
        private Atspi.EventListenerCB event_listener_cb;
        public static Atspi.Accessible active_application;
        public static Atspi.EditableText focussed_control;

        // Current collection of snippets.
        private Gee.Collection<Snippet> snippets;
        private Gee.HashMap<string,string> abbreviations;
        private Gee.HashMap<string,bool> triggers;

        public Application () {
            Object (
                application_id: "com.bytepixie.snippetpixie",
                flags: ApplicationFlags.HANDLES_COMMAND_LINE
            );
        }

        protected override void activate () {
            if (show) {
                build_ui ();
            } 

            // We only want the one listener process.
            if (app_running) {
                return;
            }

            app_running = true;
            Atspi.init();

            if (Atspi.is_initialized () == false) {
                message ("AT-SPI not initialized.");
                quit ();
            }

            listener_cb = (Atspi.DeviceListenerCB) on_key_released_event;
            listener = new Atspi.DeviceListener ((owned) listener_cb);

            try {
                // Single keystrokes.
                Atspi.register_keystroke_listener (listener, null, 0, Atspi.EventType.KEY_RELEASED_EVENT, Atspi.KeyListenerSyncType.NOSYNC);
                // Shift+Key.
                Atspi.register_keystroke_listener (listener, null, 1, Atspi.EventType.KEY_RELEASED_EVENT, Atspi.KeyListenerSyncType.NOSYNC);
            } catch (Error e) {
                message ("Could not register keystroke listener: %s", e.message);
                Atspi.exit ();
                quit ();
            }

            event_listener_cb = (Atspi.EventListenerCB) on_focus;
            Atspi.EventListener.register_from_callback (event_listener_cb, "focus:");

            desktop = Atspi.get_desktop (0);

            // Clear desktop's cache.
            // desktop.set_cache_mask (Atspi.Cache.UNDEFINED);
            // desktop.clear_cache ();

            var children = 0;

            try {
                children = desktop.get_child_count ();
            } catch (Error e) {
                message ("Could not get Desktop's child count: %s", e.message);
                Atspi.exit ();
                quit ();
            }

            message ("Desktop has %d children.", children);

            for (int i = 0; i < children; i++) {
                var child = desktop.get_child_at_index(i);
                // child.set_cache_mask (Atspi.Cache.UNDEFINED);
                // child.clear_cache ();
                message ("Child's name %s", child.get_name ());

                if (child.role == Atspi.Role.APPLICATION) {
                    message ("It's an application.");

                    var app_children = child.get_child_count ();

                    for (int j = 0; j < app_children; j++) {
                        var frame = child.get_child_at_index (j);

                        if (frame.role == Atspi.Role.FRAME && frame.states.contains(Atspi.StateType.ACTIVE)) {
                            message ("!!! THE ACTIVE ONE TOO !!!");
                            SnippetPixie.Application.active_application = (Atspi.Accessible) child;
                        }
                    }
                }

            }
        }

        // It's working, just need to figure out what data we have!
        [CCode (instance_pos = -1)]
        private bool on_key_released_event (Atspi.DeviceEvent stroke) {
            if (stroke.is_text && stroke.event_string != null) {
                message ("ID: %u, Event String: %s, Modifiers: %d", stroke.id, stroke.event_string, stroke.modifiers);
            } else {
                message ("Another Event: %u", stroke.id);
            }

            if (stroke.is_text && stroke.event_string != null && "`" == stroke.event_string) {
                message ("!!! GOT A MATCH !!!");

                if (SnippetPixie.Application.focussed_control != null) {
                    message ("And in an editable.");
                    SnippetPixie.Application.focussed_control.set_text_contents ("YABADABADOO!!!");
                }
            }

            return false;
        }

        [CCode (instance_pos = -1)]
        private bool on_focus (Atspi.Event event) {
            message ("Got focus event! Type ='%s', detail1 ='%d', detail2 = '%d', any_data = '%s'", event.type, event.detail1, event.detail2, event.any_data.get_string ());
            message ("Source: '%s', Role: '%s'", event.source.name, event.source.role.get_name ());

            SnippetPixie.Application.focussed_control = event.source.get_editable_text_iface ();

            return false;
        }

        private Gee.Collection<Snippet> get_snippets () {
            if (snippets == null ) {
                snippets = new Gee.ArrayList<Snippet> ();
                abbreviations = new Gee.HashMap<string,string> ();
                triggers = new Gee.HashMap<string,bool> ();

                var snippet = new Snippet (1);
                abbreviations.set (snippet.abbreviation, snippet.body);
                triggers.set (snippet.trigger (), true);
                snippets.add (snippet);

                snippet = new Snippet (2);
                snippet.abbreviation = "@b`";
                snippet.body = "hello@bytepixie.com";
                abbreviations.set (snippet.abbreviation, snippet.body);
                triggers.set (snippet.trigger (), true);
                snippets.add (snippet);

                snippet = new Snippet (3);
                snippet.abbreviation = "sp`";
                snippet.body = "Snippet Pixie";
                abbreviations.set (snippet.abbreviation, snippet.body);
                triggers.set (snippet.trigger (), true);
                snippets.add (snippet);

                snippet = new Snippet (4);
                snippet.abbreviation = "spu`";
                snippet.body = "https://www.snippetpixie.com";
                abbreviations.set (snippet.abbreviation, snippet.body);
                triggers.set (snippet.trigger (), true);
                snippets.add (snippet);
            }

            return snippets;
        }

        private void build_ui () {
            if (get_windows ().length () > 0) {
                get_windows ().data.present ();
                return;
            }

            var provider = new Gtk.CssProvider ();
            provider.load_from_resource ("com/bytepixie/snippetpixie/Application.css");
            Gtk.StyleContext.add_provider_for_screen (Gdk.Screen.get_default (), provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);


            app_window = new MainWindow (this);
            app_window.request_snippets.connect ((_) => {
                return get_snippets ();
            });
            app_window.show_all ();
            add_window (app_window);

            app_window.state_flags_changed.connect (save_ui_settings);
            app_window.delete_event.connect (save_ui_settings_on_delete);

            var quit_action = new SimpleAction ("quit", null);
            add_action (quit_action);
            set_accels_for_action ("app.quit", {"<Control>q"});

            quit_action.activate.connect (() => {
                if (app_window != null) {
                    app_window.destroy ();
                }
            });

            app_window.init ();
        }

        private void save_ui_settings () {
            var settings = new Settings ("com.bytepixie.snippetpixie");

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

	    public override int command_line (ApplicationCommandLine command_line) {
            show = true;
            bool start = false;
            bool stop = false;
            bool status = false;
		    bool version = false;

		    OptionEntry[] options = new OptionEntry[5];
            options[0] = { "show", 0, 0, OptionArg.NONE, ref show, "Show Snippet Pixie's window (default action)", null };
            options[1] = { "start", 0, 0, OptionArg.NONE, ref start, "Start in the background", null };
            options[2] = { "stop", 0, 0, OptionArg.NONE, ref stop, "Fully quit the application, including the background process", null };
            options[3] = { "status", 0, 0, OptionArg.NONE, ref status, "Shows status of the application, exits with status 0 if running, 1 if not", null };
		    options[4] = { "version", 0, 0, OptionArg.NONE, ref version, "Display version number", null };

		    // We have to make an extra copy of the array, since .parse assumes
		    // that it can remove strings from the array without freeing them.
		    string[] args = command_line.get_arguments ();
		    string[] _args = new string[args.length];
		    for (int i = 0; i < args.length; i++) {
			    _args[i] = args[i];
		    }

		    try {
			    var opt_context = new OptionContext ();
			    opt_context.set_help_enabled (true);
			    opt_context.add_main_entries (options, null);
			    unowned string[] tmp = _args;
			    opt_context.parse (ref tmp);
		    } catch (OptionError e) {
			    command_line.print ("error: %s\n", e.message);
			    command_line.print ("Run '%s --help' to see a full list of available command line options.\n", args[0]);
			    return 0;
		    }

		    if (version) {
			    command_line.print ("%s\n", version_string);
			    return 0;
		    }

		    if (stop) {
			    command_line.print ("Quitting...\n");
                var app = get_default ();
                app.quit ();
			    return 0;
		    }

            if (start) {
                show = false;
            }

		    if (status) {
		        if (app_running) {
			        command_line.print ("Running.\n");
			        return 0;
		        } else {
			        command_line.print ("Not Running.\n");
			        return 1;
		        }
		    }

            // If we get here we're either showing the window or running the background process.
            if ( show == false || ! app_running ) {
                hold ();
            }

            activate ();

		    return 0;
	    }

        public static new Application get_default () {
            if (_app == null) {
                _app = new Application ();
            }
            return _app;
        }

        public static int main (string[] args) {
            var app = get_default ();
            return app.run (args);
        }
    }
}
