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
        public const string ID = "com.github.bytepixie.snippetpixie";
        public const string VERSION = "1.1.2";

        private const string placeholder_delimiter = "$$";
        private const string placeholder_macro = "@";

        private static Application? _app = null;

        private bool app_running = false;
        private bool show = true;
        public MainWindow app_window { get; private set; }

        // For tracking keystrokes.
        private Atspi.DeviceListenerCB listener_cb;
        private Atspi.DeviceListener listener;

        // For tracking currently focused editable text controls.
        private Atspi.EventListenerCB focused_event_listener_cb;
        private Atspi.EventListenerCB window_activated_event_listener_cb;
        private Atspi.EventListenerCB window_deactivated_event_listener_cb;
        private bool focus_changed = true;
        private int focused_app_id = -1;
        public static Atspi.EditableText focused_control;

        public SnippetsManager snippets_manager;

        public Application () {
            Object (
                application_id: ID,
                flags: ApplicationFlags.HANDLES_COMMAND_LINE
            );
        }

        protected override void activate () {
            if (snippets_manager == null) {
                snippets_manager = new SnippetsManager ();
            }

            if (show) {
                build_ui ();
            } 

            // We only want the one listener process.
            if (app_running) {
                return;
            }

            app_running = true;

            // Set up AT-SPI listeners.
            Atspi.init();

            if (Atspi.is_initialized () == false) {
                message ("AT-SPI not initialized.");
                quit ();
            }

            listener_cb = (Atspi.DeviceListenerCB) on_key_released_event;
            listener = new Atspi.DeviceListener ((owned) listener_cb);

            try {
                // Single keystrokes.
                Atspi.register_keystroke_listener (listener, null, 0, Atspi.EventType.KEY_RELEASED_EVENT, Atspi.KeyListenerSyncType.CANCONSUME);
                // Shift.
                Atspi.register_keystroke_listener (listener, null, IBus.ModifierType.SHIFT_MASK, Atspi.EventType.KEY_RELEASED_EVENT, Atspi.KeyListenerSyncType.CANCONSUME);
                // Shift-Lock.
                Atspi.register_keystroke_listener (listener, null, IBus.ModifierType.LOCK_MASK, Atspi.EventType.KEY_RELEASED_EVENT, Atspi.KeyListenerSyncType.CANCONSUME);
                // Shift + Shift-Lock.
                Atspi.register_keystroke_listener (listener, null, IBus.ModifierType.SHIFT_MASK | IBus.ModifierType.LOCK_MASK, Atspi.EventType.KEY_RELEASED_EVENT, Atspi.KeyListenerSyncType.CANCONSUME);
                // Control.
                Atspi.register_keystroke_listener (listener, null, IBus.ModifierType.CONTROL_MASK, Atspi.EventType.KEY_RELEASED_EVENT, Atspi.KeyListenerSyncType.CANCONSUME);
                // Control + Shift.
                Atspi.register_keystroke_listener (listener, null, IBus.ModifierType.CONTROL_MASK | IBus.ModifierType.SHIFT_MASK, Atspi.EventType.KEY_RELEASED_EVENT, Atspi.KeyListenerSyncType.CANCONSUME);
                // Control + Shift-Lock.
                Atspi.register_keystroke_listener (listener, null, IBus.ModifierType.CONTROL_MASK | IBus.ModifierType.LOCK_MASK, Atspi.EventType.KEY_RELEASED_EVENT, Atspi.KeyListenerSyncType.CANCONSUME);
                // Control + Shift + Shift-Lock.
                Atspi.register_keystroke_listener (listener, null, IBus.ModifierType.CONTROL_MASK | IBus.ModifierType.SHIFT_MASK | IBus.ModifierType.LOCK_MASK, Atspi.EventType.KEY_RELEASED_EVENT, Atspi.KeyListenerSyncType.CANCONSUME);
                // Mod1 (Alt/Meta).
                Atspi.register_keystroke_listener (listener, null, IBus.ModifierType.MOD1_MASK, Atspi.EventType.KEY_RELEASED_EVENT, Atspi.KeyListenerSyncType.CANCONSUME);
                // Mod1 + Shift.
                Atspi.register_keystroke_listener (listener, null, IBus.ModifierType.MOD1_MASK | IBus.ModifierType.SHIFT_MASK, Atspi.EventType.KEY_RELEASED_EVENT, Atspi.KeyListenerSyncType.CANCONSUME);
                // Mod1 + Shift-Lock.
                Atspi.register_keystroke_listener (listener, null, IBus.ModifierType.MOD1_MASK | IBus.ModifierType.LOCK_MASK, Atspi.EventType.KEY_RELEASED_EVENT, Atspi.KeyListenerSyncType.CANCONSUME);
                // Mod1 + Shift + Shift-Lock.
                Atspi.register_keystroke_listener (listener, null, IBus.ModifierType.MOD1_MASK | IBus.ModifierType.SHIFT_MASK | IBus.ModifierType.LOCK_MASK, Atspi.EventType.KEY_RELEASED_EVENT, Atspi.KeyListenerSyncType.CANCONSUME);
                // Mod2 (NumLock).
                Atspi.register_keystroke_listener (listener, null, IBus.ModifierType.MOD2_MASK, Atspi.EventType.KEY_RELEASED_EVENT, Atspi.KeyListenerSyncType.CANCONSUME);
                // Mod2 + Shift.
                Atspi.register_keystroke_listener (listener, null, IBus.ModifierType.MOD2_MASK | IBus.ModifierType.SHIFT_MASK, Atspi.EventType.KEY_RELEASED_EVENT, Atspi.KeyListenerSyncType.CANCONSUME);
                // Mod2 + Shift-Lock.
                Atspi.register_keystroke_listener (listener, null, IBus.ModifierType.MOD2_MASK | IBus.ModifierType.LOCK_MASK, Atspi.EventType.KEY_RELEASED_EVENT, Atspi.KeyListenerSyncType.CANCONSUME);
                // Mod2 + Shift + Shift-Lock.
                Atspi.register_keystroke_listener (listener, null, IBus.ModifierType.MOD2_MASK | IBus.ModifierType.SHIFT_MASK | IBus.ModifierType.LOCK_MASK, Atspi.EventType.KEY_RELEASED_EVENT, Atspi.KeyListenerSyncType.CANCONSUME);
                // Mod3 (???).
                Atspi.register_keystroke_listener (listener, null, IBus.ModifierType.MOD3_MASK, Atspi.EventType.KEY_RELEASED_EVENT, Atspi.KeyListenerSyncType.CANCONSUME);
                // Mod3 + Shift.
                Atspi.register_keystroke_listener (listener, null, IBus.ModifierType.MOD3_MASK | IBus.ModifierType.SHIFT_MASK, Atspi.EventType.KEY_RELEASED_EVENT, Atspi.KeyListenerSyncType.CANCONSUME);
                // Mod3 + Shift-Lock.
                Atspi.register_keystroke_listener (listener, null, IBus.ModifierType.MOD3_MASK | IBus.ModifierType.LOCK_MASK, Atspi.EventType.KEY_RELEASED_EVENT, Atspi.KeyListenerSyncType.CANCONSUME);
                // Mod3 + Shift + Shift-Lock.
                Atspi.register_keystroke_listener (listener, null, IBus.ModifierType.MOD3_MASK | IBus.ModifierType.SHIFT_MASK | IBus.ModifierType.LOCK_MASK, Atspi.EventType.KEY_RELEASED_EVENT, Atspi.KeyListenerSyncType.CANCONSUME);
                // Mod4 (Super/Menu).
                Atspi.register_keystroke_listener (listener, null, IBus.ModifierType.MOD4_MASK, Atspi.EventType.KEY_RELEASED_EVENT, Atspi.KeyListenerSyncType.CANCONSUME);
                // Mod4 + Shift.
                Atspi.register_keystroke_listener (listener, null, IBus.ModifierType.MOD4_MASK | IBus.ModifierType.SHIFT_MASK, Atspi.EventType.KEY_RELEASED_EVENT, Atspi.KeyListenerSyncType.CANCONSUME);
                // Mod4 + Shift-Lock.
                Atspi.register_keystroke_listener (listener, null, IBus.ModifierType.MOD4_MASK | IBus.ModifierType.LOCK_MASK, Atspi.EventType.KEY_RELEASED_EVENT, Atspi.KeyListenerSyncType.CANCONSUME);
                // Mod4 + Shift + Shift-Lock.
                Atspi.register_keystroke_listener (listener, null, IBus.ModifierType.MOD4_MASK | IBus.ModifierType.SHIFT_MASK | IBus.ModifierType.LOCK_MASK, Atspi.EventType.KEY_RELEASED_EVENT, Atspi.KeyListenerSyncType.CANCONSUME);
                // Mod5 (ISO_Level3_Shift/Alt Gr).
                Atspi.register_keystroke_listener (listener, null, IBus.ModifierType.MOD5_MASK, Atspi.EventType.KEY_RELEASED_EVENT, Atspi.KeyListenerSyncType.CANCONSUME);
                // Mod5 + Shift.
                Atspi.register_keystroke_listener (listener, null, IBus.ModifierType.MOD5_MASK | IBus.ModifierType.SHIFT_MASK, Atspi.EventType.KEY_RELEASED_EVENT, Atspi.KeyListenerSyncType.CANCONSUME);
                // Mod5 + Shift-Lock.
                Atspi.register_keystroke_listener (listener, null, IBus.ModifierType.MOD5_MASK | IBus.ModifierType.LOCK_MASK, Atspi.EventType.KEY_RELEASED_EVENT, Atspi.KeyListenerSyncType.CANCONSUME);
                // Mod5 + Shift + Shift-Lock.
                Atspi.register_keystroke_listener (listener, null, IBus.ModifierType.MOD5_MASK | IBus.ModifierType.SHIFT_MASK | IBus.ModifierType.LOCK_MASK, Atspi.EventType.KEY_RELEASED_EVENT, Atspi.KeyListenerSyncType.CANCONSUME);
            } catch (Error e) {
                message ("Could not register keystroke listener: %s", e.message);
                Atspi.exit ();
                quit ();
            }

            try {
                focused_event_listener_cb = (Atspi.EventListenerCB) on_focus;
                Atspi.EventListener.register_from_callback ((owned) focused_event_listener_cb, "focus:");
            } catch (Error e) {
                message ("Could not register focus event listener: %s", e.message);
                Atspi.exit ();
                quit ();
            }

            try {
                window_activated_event_listener_cb = (Atspi.EventListenerCB) on_window_activate;
                Atspi.EventListener.register_from_callback ((owned) window_activated_event_listener_cb, "window:activate");
            } catch (Error e) {
                message ("Could not register window activated event listener: %s", e.message);
                Atspi.exit ();
                quit ();
            }

            try {
                window_deactivated_event_listener_cb = (Atspi.EventListenerCB) on_window_deactivate;
                Atspi.EventListener.register_from_callback ((owned) window_deactivated_event_listener_cb, "window:deactivate");
            } catch (Error e) {
                message ("Could not register window deactivated event listener: %s", e.message);
                Atspi.exit ();
                quit ();
            }
        }

        [CCode (instance_pos = -1)]
        private bool on_key_released_event (Atspi.DeviceEvent stroke) {
            var expanded = false;
            debug ("*** KEY EVENT ID = '%u', Str = '%s'", stroke.id, stroke.event_string);

            lock (focused_control) {
                lock (focus_changed) {
                    if (
                        focused_control != null &&
                        focus_changed != true &&
                        stroke.is_text &&
                        stroke.event_string != null &&
                        snippets_manager.triggers != null &&
                        snippets_manager.triggers.size > 0 &&
                        snippets_manager.triggers.has_key (stroke.event_string)
                        ) {
                        debug ("!!! GOT A TRIGGER KEY MATCH !!!");

                        var ctrl = (Atspi.Text) focused_control;
                        var caret_offset = 0;

                        try {
                            caret_offset = ctrl.get_caret_offset ();
                        } catch (Error e) {
                            message ("Could not get caret offset: %s", e.message);
                            return expanded;
                        }
                        debug ("Caret Offset %d", caret_offset);

                        for (int pos = caret_offset; pos >= 0; pos--) {
                            // Stop checking if we're already checking against a larger character set than in any abbreviation.
                            if ((caret_offset - pos) > snippets_manager.max_abbr_len) {
                                return expanded;
                            }

                            var str = "";

                            try {
                                // At time of key capture the trigger isn't in the text yet so it's tacked onto search string.
                                str = ctrl.get_text (pos, caret_offset) + stroke.event_string;
                            } catch (Error e) {
                                message ("Could not get text between positions %d and %d: %s", pos, caret_offset, e.message);
                                return expanded;
                            }
                            debug ("Pos %d, Str %s", pos, str);

                            if (snippets_manager.abbreviations.has_key (str)) {
                                debug ("IT'S AN ABBREVIATION!!!");

                                try {
                                    if (! focused_control.delete_text (pos, caret_offset)) {
                                        message ("Could not delete abbreviation string from text.");
                                        break;
                                    }
                                } catch (Error e) {
                                    message ("Could not delete abbreviation string from text between positions %d and %d: %s", pos, caret_offset, e.message);
                                    return expanded;
                                }

                                var body = snippets_manager.abbreviations.get (str);

                                // Before trying to insert the snippet's body, parse it to expand placeholders such as date/time and embedded snippets.
                                body = expand_snippet (body);

                                try {
                                    if (! focused_control.insert_text (pos, body, body.length)) {
                                        message ("Could not insert expanded snippet into text.");
                                        break;
                                    }
                                } catch (Error e) {
                                    message ("Could not insert expanded snippet into text at position %d: %s", pos, e.message);
                                    return expanded;
                                }

                                expanded = true;
                                break;
                            } // have matching abbreviation
                        } // step back through characters
                    } // if something to check
                } // lock focus_changed
            } // lock focused_control

            return expanded;
        }

        private string expand_snippet (string body) {
            // Quick check that placeholder exists at least once in string, and a macro name start is too.
            if (body.contains (placeholder_delimiter) && body.contains (placeholder_delimiter.concat (placeholder_macro))) {
                string result = "";
                var bits = body.split (placeholder_delimiter);

                foreach (string bit in bits) {
                    // Date/Time Placeholder.
                    bit = expand_date (bit);

                    result = result.concat (bit);
                }

                return result;
            }

            return body;
        }

        private string expand_date (owned string body) {
            string macros[] = { _("date"), _("time") };

            foreach (string macro in macros) {
                var needle = placeholder_macro.concat (macro, ":");

                if (body.index_of (needle) == 0) {
                    var fmt = body.substring (needle.length);
                    var dt = new DateTime.now_local ();
                    body = dt.format (fmt);
                }
            }

            return body;
        }

        private void focus_changing () {
            // Focused control must have changed.
            focused_control = null;
            focus_changed = true;
        }

        [CCode (instance_pos = -1)]
        private bool on_focus (Atspi.Event event) {
            debug ("!!! FOCUS EVENT Type ='%s', Source: '%s'", event.type, event.source.name);

            lock (focused_control) {
                lock (focus_changed) {
                    focus_changing ();

                    try {
                        focused_app_id = event.source.get_id ();

                        // Try and grab editable control's handle, but don't want expansion within Snippet Pixie.
                        var app = event.source.get_application ();
                        if (app.get_name () != this.application_id) {
                            focused_control = event.source.get_editable_text_iface ();
                        }
                    } catch (Error e) {
                        message ("Could not get focused control: %s", e.message);
                        return false;
                    }

                    // We no longer need to look for a focused control.
                    if (focused_control != null) {
                        focus_changed = false;
                    }
                }
            }

            return false;
        }

        [CCode (instance_pos = -1)]
        private bool on_window_activate (Atspi.Event event) {
            debug (">>> WINDOW ACTIVATE EVENT Type ='%s', Source: '%s'", event.type, event.source.name);

            lock (focused_control) {
                lock (focus_changed) {
                    focus_changing ();

                    try {
                        focused_app_id = event.source.get_id ();

                        event.source.clear_cache ();
                        debug ("Cleared the cache for '%s'", event.source.name);
                    } catch (Error e) {
                        message ("Could not clear cache for '%s': %s", event.source.name, e.message);
                        return false;
                    }
                }
            }

            // TODO: Maybe spin off in thread or async?
            // If a window is being returned to one way or another, then check whether an editable text is already focused.
            var ctrl = get_focused_control (event.source);

            lock (focused_control) {
                focused_control = ctrl;
            }

            return false;
        }

        [CCode (instance_pos = -1)]
        private bool on_window_deactivate (Atspi.Event event) {
            debug ("<<< WINDOW DEACTIVATE EVENT Type ='%s', Source: '%s'", event.type, event.source.name);

            lock (focused_control) {
                lock (focus_changed) {
                    int deactivated_app_id = -1;

                    try {
                        deactivated_app_id = event.source.get_id ();
                    } catch (Error e) {
                        message ("Could not get deactivated app id for '%s': %s", event.source.name, e.message);
                        return false;
                    }

                    if (focused_app_id > 0 && deactivated_app_id != focused_app_id) {
                        debug ("Out of order event: '%s', skipping.", event.type);
                        return false;
                    }

                    // Make sure previously focused control doesn't accidently get results of expansion.
                    focus_changing ();
                }
            }

            return false;
        }

        private Atspi.EditableText? get_focused_control (owned Atspi.Accessible? parent, int level = 0) {
            // Too far down the rabbit hole and we'll get stuck.
            if (level > 20) {
                debug ("Too deep down the rabit hole, returning to surface.");
                return null;
            }

            lock (focus_changed) {
                // Safe guard, should not be called unless window just changed.
                if (level == 0 && focus_changed == false) {
                    debug ("Oops, looking for focused control but focus event hasn't trigger it?");
                    return null;
                }

                if (level == 0 && focus_changed == true) {
                    focus_changed = false;
                }

                // If we're still looking for a focused control while focus changes, abort.
                // In current single thread form this isn't going to happen, but we may need to go multi-threaded soon.
                if (level != 0 && focus_changed == true) {
                    debug("Focus changed while looking for focused control, aborting current lookup.");
                    return null;
                }
            }

            level++;

            try {
                if (parent == null) {
                    debug ("Hmmm, had to go to desktop to try and find focused control, seems suspicious.");
                    parent = Atspi.get_desktop (0);
                } else {
                    //debug("Checking that current app isn't myself.");
                    var app = parent.get_application ();
                    if (app.get_name () == this.application_id) {
                        return null;
                    }
                }
            } catch (Error e) {
                message ("Could not get/check current app: %s", e.message);
                Atspi.exit ();
                quit ();
            }

            var children = 0;

            try {
                debug("Counting child controls...");
                children = parent.get_child_count ();
                debug("...%d child controls found.", children);
            } catch (Error e) {
                message ("Could not get parent control's child count: %s", e.message);
                Atspi.exit ();
                quit ();
            }

            if (children > 0) {
                for (int i = 0; i < children; i++) {
                    Atspi.Accessible child = null;

                    lock (focus_changed) {
                        // If we're still looking for a focused control while focus changes, abort.
                        if (focus_changed == true) {
                            debug("Focus changed while looking for focused control, aborting current lookup.");
                            return null;
                        }
                    }

                    try {
                        if (parent != null) {
                            child = parent.get_child_at_index(i);
                        }
                    } catch (Error e) {
                        message ("Could not get child control: %s", e.message);
                        Atspi.exit ();
                        quit ();
                    }

                    if (child != null && child.states.contains(Atspi.StateType.FOCUSED) && (child is Atspi.EditableText)) {
                        debug ("$$$ Found focsed child control.");
                        return child;
                    }

                    // If the child control is visible and showing it's worth looking at its children.
                    if (child != null && child.states.contains(Atspi.StateType.VISIBLE) && child.states.contains(Atspi.StateType.SHOWING)) {
                        var control = get_focused_control (child, level);

                        // Woo hoo, found it buried down here somewhere.
                        if (control != null) {
                            return control;
                        }
                    }

                    // Be nice.
                    yield;
                }
            }

            return null;
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
        }

        private void save_ui_settings () {
            var settings = new Settings ("com.github.bytepixie.snippetpixie");

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

        /**
         * Mostly "Borrowed" from Clipped by David Hewitt.
         * https://github.com/davidmhewitt/clipped/blob/edac68890c2a78357910f05bf44060c2aba5958e/src/Application.vala#L153
         */
        private void update_autostart (bool autostart) {
            var desktop_file_name = application_id + ".desktop";
            var desktop_file_path = new DesktopAppInfo (desktop_file_name).filename;
            var desktop_file = File.new_for_path (desktop_file_path);
            var dest_path = Path.build_path (
                Path.DIR_SEPARATOR_S,
                Environment.get_user_config_dir (),
                "autostart",
                desktop_file_name
            );
            var dest_file = File.new_for_path (dest_path);

            try {
                var parent = dest_file.get_parent ();

                if (! parent.query_exists ()) {
                    parent.make_directory_with_parents ();
                }
                desktop_file.copy (dest_file, FileCopyFlags.OVERWRITE);
            } catch (Error e) {
                warning ("Error making copy of desktop file for autostart: %s", e.message);
                return;
            }

            var keyfile = new KeyFile ();

            try {
                keyfile.load_from_file (dest_path, KeyFileFlags.NONE);
                keyfile.set_string ("Desktop Entry", "Exec", "com.github.bytepixie.snippetpixie --start");
                keyfile.set_boolean ("Desktop Entry", "X-GNOME-Autostart-enabled", autostart);

                if (keyfile.has_group ("Desktop Action Start")) {
                    keyfile.remove_group ("Desktop Action Start");
                }

                if (keyfile.has_group ("Desktop Action Stop")) {
                    keyfile.remove_group ("Desktop Action Stop");
                }

                keyfile.save_to_file (dest_path);
            } catch (Error e) {
                warning ("Error enabling autostart: %s", e.message);
                return;
            }
        }

        private bool get_autostart () {
            var desktop_file_name = application_id + ".desktop";
            var dest_path = Path.build_path (
                Path.DIR_SEPARATOR_S,
                Environment.get_user_config_dir (),
                "autostart",
                desktop_file_name
            );
            var dest_file = File.new_for_path (dest_path);

            if (! dest_file.query_exists ()) {
                // By default we want to autostart.
                update_autostart (true);
                return true;
            }

            var autostart = false;
            var keyfile = new KeyFile ();

            try {
                keyfile.load_from_file (dest_path, KeyFileFlags.NONE);
                autostart = keyfile.get_boolean ("Desktop Entry", "X-GNOME-Autostart-enabled");
            } catch (Error e) {
                warning ("Error enabling autostart: %s", e.message);
            }

            return autostart;
        }

        public override int command_line (ApplicationCommandLine command_line) {
            show = true;
            bool start = false;
            bool stop = false;
            string autostart = null;
            bool status = false;
            string export_file = null;
            string import_file = null;
            bool force = false;
            bool version = false;
            bool help = false;

            OptionEntry[] options = new OptionEntry[10];
            options[0] = { "show", 0, 0, OptionArg.NONE, ref show, _("Show Snippet Pixie's window (default action)"), null };
            options[1] = { "start", 0, 0, OptionArg.NONE, ref start, _("Start with no window"), null };
            options[2] = { "stop", 0, 0, OptionArg.NONE, ref stop, _("Fully quit the application, including the background process"), null };
            options[3] = { "autostart", 0, 0, OptionArg.STRING, ref autostart, _("Turn auto start of Snippet Pixie on login, on, off, or show status of setting"), "{on|off|status}" };
            options[4] = { "status", 0, 0, OptionArg.NONE, ref status, _("Shows status of the application, exits with status 0 if running, 1 if not"), null };
            options[5] = { "export", 'e', 0, OptionArg.FILENAME, ref export_file, _("Export snippets to file"), "filename" };
            options[6] = { "import", 'i', 0, OptionArg.FILENAME, ref import_file, _("Import snippets from file, skips snippets where abbreviation already exists"), _("filename") };
            options[7] = { "force", 0, 0, OptionArg.NONE, ref force, _("If used in conjunction with import, existing snippets with same abbreviation are updated"), null };
            options[8] = { "version", 0, 0, OptionArg.NONE, ref version, _("Display version number"), null };
            options[9] = { "help", 'h', 0, OptionArg.NONE, ref help, _("Display this help"), null };

            // We have to make an extra copy of the array, since .parse assumes
            // that it can remove strings from the array without freeing them.
            string[] args = command_line.get_arguments ();
            string[] _args = new string[args.length];
            for (int i = 0; i < args.length; i++) {
                _args[i] = args[i];
            }

            OptionContext opt_context;

            try {
                opt_context = new OptionContext ();
                opt_context.set_help_enabled (false);
                opt_context.add_main_entries (options, null);
                unowned string[] tmp = _args;
                opt_context.parse (ref tmp);
            } catch (OptionError e) {
                command_line.print (_("error: %s\n"), e.message);
                command_line.print (_("Run '%s --help' to see a full list of available command line options.\n"), args[0]);
                return 0;
            }

            if (help) {
                command_line.print ("%s\n", opt_context.get_help (true, null));
                return 0;
            }

            if (version) {
                command_line.print ("%s\n", VERSION);
                return 0;
            }

            if (stop) {
                command_line.print (_("Quitting…\n"));
                var app = get_default ();
                app.quit ();
                return 0;
            }

            if (status) {
                if (app_running) {
                    command_line.print (_("Running.\n"));
                    return 0;
                } else {
                    command_line.print (_("Not Running.\n"));
                    return 1;
                }
            }

            switch (autostart) {
                case null:
                    break;
                case "on":
                    update_autostart (true);
                    return 0;
                case "off":
                    update_autostart (false);
                    return 0;
                case "status":
                    if (get_autostart ()) {
                        command_line.print ("on\n");
                    } else {
                        command_line.print ("off\n");
                    }
                    return 0;
                default:
                    command_line.print (_("Invalid autostart value \"%s\".\n"), autostart);
                    help = true;
                    break;
            }

            if (export_file != null) {
                if (snippets_manager == null) {
                    snippets_manager = new SnippetsManager ();
                }

                return snippets_manager.export_to_file (export_file);
            }

            if (import_file != null) {
                if (snippets_manager == null) {
                    snippets_manager = new SnippetsManager ();
                }

                return snippets_manager.import_from_file (import_file, force);
            }

            if (start) {
                show = false;
            }

            // If we get here we're either showing the window or running the background process.
            if ( show == false || ! app_running ) {
                get_autostart ();
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
            if (Thread.supported () == false) {
                stderr.printf(_("Cannot run without threads.\n"));
                return -1;
            }

            var app = get_default ();
            return app.run (args);
        }
    }
}
