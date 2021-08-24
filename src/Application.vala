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
        public const string VERSION = "1.5.3";

        public signal void search_changed (string search_term);
        public signal void search_escaped ();

        public string SEARCH_AND_PASTE_CMD = "";

        private const ulong SLEEP_INTERVAL = (ulong) TimeSpan.MILLISECOND * 10;
        private const ulong SLEEP_INTERVAL_RETRY = SLEEP_INTERVAL * 2;
        private const ulong SLEEP_INTERVAL_LONG = SLEEP_INTERVAL * 20;

        private const string placeholder_delimiter = "$$";
        private const string placeholder_macro = "@";
        private const string placeholder_delimiter_escaped = "$\\$";

        private static Application? _app = null;
        private static bool app_running = false;

        private Settings settings = new Settings (ID);

        private bool show = true;
        private bool search_and_paste = false;
        private bool snap = false;
        public MainWindow app_window { get; private set; }
        private SearchAndPasteWindow? search_and_paste_window = null;
        private Snippet? snippet_to_paste = null;

        // For tracking keystrokes.
        private Atspi.DeviceListenerCB listener_cb;
        private Atspi.DeviceListener listener;
        private static bool listeners_registered = false;
        private static bool listening = false;
        private Thread check_thread;
        private static bool checking = false;
        private bool autostart = true;
        private bool auto_expand = true;

        // For tracking current focused editable text control.
        private Atspi.EventListenerCB focused_event_listener_cb;
        private Atspi.EventListenerCB text_changed_event_listener_cb;
        private Atspi.EditableText? focused_control = null;
        private Atspi.Accessible? last_focused_control = null;

        // For tracking window events that mean focused control has likely changed.
        private Atspi.EventListenerCB window_deactivated_event_listener_cb;
        private Atspi.EventListenerCB window_minimize_event_listener_cb;
        private Atspi.EventListenerCB window_shade_event_listener_cb;
        private Atspi.EventListenerCB window_lower_event_listener_cb;
        private Atspi.EventListenerCB window_close_event_listener_cb;
        private Atspi.EventListenerCB window_desktop_destroy_event_listener_cb;

        public SnippetsManager snippets_manager;

        public Application () {
            Object (
                application_id: ID,
                flags: ApplicationFlags.HANDLES_COMMAND_LINE
            );
        }

        protected override void shutdown () {
            debug ("shutdown");
            base.shutdown ();
            cleanup ();
        }

        protected override void activate () {
            // There's a couple of things that need setting up once,
            // even before a window is shown.
            if (snippets_manager == null) {
                snippets_manager = new SnippetsManager ();

                // Register shortcut for paste method.
                set_default_shortcut ();

                window_removed.connect ((closed_window) => {
                    if (snippet_to_paste != null && snippet_to_paste.body.strip ().length > 0) {
                        // Before trying to paste the snippet's body, parse it to expand placeholders such as date/time and embedded snippets.
                        // NOTE: For paste method we do not support placing cursor.
                        var new_offset = -1;
                        var dt = new DateTime.now_local ();
                        var body = expand_snippet (snippet_to_paste.body, ref new_offset, dt);
                        body = collapse_escaped_placeholder_delimiter (body, ref new_offset);
                        Gtk.Clipboard.get_default (Gdk.Display.get_default ()).set_text (body, -1);
                        paste ();
                        snippet_to_paste.last_used = dt;
                        snippets_manager.update (snippet_to_paste);
                    }
                    if (closed_window == search_and_paste_window) {
                        close_search_and_paste_window ();
                    }
                });

                // Style stuff needed before any window shown.
                var provider = new Gtk.CssProvider ();
                provider.load_from_resource ("com/bytepixie/snippetpixie/Application.css");
                Gtk.StyleContext.add_provider_for_screen (Gdk.Screen.get_default (), provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);

                var granite_settings = Granite.Settings.get_default ();
                var gtk_settings = Gtk.Settings.get_default ();

                gtk_settings.gtk_application_prefer_dark_theme = granite_settings.prefers_color_scheme == Granite.Settings.ColorScheme.DARK;

                granite_settings.notify["prefers-color-scheme"].connect (() => {
                    gtk_settings.gtk_application_prefer_dark_theme = granite_settings.prefers_color_scheme == Granite.Settings.ColorScheme.DARK;
                });
            }

            if (show) {
                show_window ();
            } else if (search_and_paste) {
                show_search_and_paste_window ();
            }

            // We only want the one listener process.
            lock (app_running) {
                if (app_running) {
                    return;
                }

                app_running = true;
            }

            // Set up AT-SPI listeners.
            Atspi.init();

            if (Atspi.is_initialized () == false) {
                message ("AT-SPI not initialized.");
                quit ();
            }

            listener_cb = (Atspi.DeviceListenerCB) on_key_released_event;
            listener = new Atspi.DeviceListener ((owned) listener_cb);

            try {
                focused_event_listener_cb = (Atspi.EventListenerCB) on_focus;
                Atspi.EventListener.register_from_callback ((owned) focused_event_listener_cb, "focus:");
                text_changed_event_listener_cb = (Atspi.EventListenerCB) on_focus;
                Atspi.EventListener.register_from_callback ((owned) text_changed_event_listener_cb, "object:text-changed:insert");
            } catch (Error e) {
                message ("Could not register focus event listener: %s", e.message);
                Atspi.exit ();
                quit ();
            }

            try {
                window_deactivated_event_listener_cb = (Atspi.EventListenerCB) on_window_deactivate;
                Atspi.EventListener.register_from_callback ((owned) window_deactivated_event_listener_cb, "window:deactivate");
                window_minimize_event_listener_cb = (Atspi.EventListenerCB) on_window_deactivate;
                Atspi.EventListener.register_from_callback ((owned) window_minimize_event_listener_cb, "window:minimize");
                window_shade_event_listener_cb = (Atspi.EventListenerCB) on_window_deactivate;
                Atspi.EventListener.register_from_callback ((owned) window_shade_event_listener_cb, "window:shade");
                window_lower_event_listener_cb = (Atspi.EventListenerCB) on_window_deactivate;
                Atspi.EventListener.register_from_callback ((owned) window_lower_event_listener_cb, "window:lower");
                window_close_event_listener_cb = (Atspi.EventListenerCB) on_window_deactivate;
                Atspi.EventListener.register_from_callback ((owned) window_close_event_listener_cb, "window:close");
                window_desktop_destroy_event_listener_cb = (Atspi.EventListenerCB) on_window_deactivate;
                Atspi.EventListener.register_from_callback ((owned) window_desktop_destroy_event_listener_cb, "window:desktop-destroy");
            } catch (Error e) {
                message ("Could not register window deactivated event listener: %s", e.message);
                Atspi.exit ();
                quit ();
            }

            // Are we auto-starting on log in?
            settings.changed["autostart"].connect (() => {
                autostart = settings.get_boolean ("autostart");

                update_autostart (autostart);
            });
            autostart = settings.get_boolean ("autostart");
            if (get_autostart () != autostart) {
                settings.set_boolean ("autostart", autostart);
            }

            // Are we auto expanding too?
            settings.changed["auto-expand"].connect (() => {
                auto_expand = settings.get_boolean ("auto-expand");

                // Ensure focused_control is re-evaluated and listeners potentially (de)registered.
                focused_control = null;
                last_focused_control = null;
            });
            auto_expand = settings.get_boolean ("auto-expand");
        }

        private void cleanup () {
            debug ("cleanup");

            lock (app_running) {
                if (app_running) {
                    deregister_listeners ();

                    try {
                        Atspi.EventListener.deregister_from_callback ((owned) focused_event_listener_cb, "focus:");
                        Atspi.EventListener.deregister_from_callback ((owned) text_changed_event_listener_cb, "object:text-changed:insert");
                        Atspi.EventListener.deregister_from_callback ((owned) window_deactivated_event_listener_cb, "window:deactivate");
                        Atspi.EventListener.deregister_from_callback ((owned) window_minimize_event_listener_cb, "window:minimize");
                        Atspi.EventListener.deregister_from_callback ((owned) window_shade_event_listener_cb, "window:shade");
                        Atspi.EventListener.deregister_from_callback ((owned) window_lower_event_listener_cb, "window:lower");
                        Atspi.EventListener.deregister_from_callback ((owned) window_close_event_listener_cb, "window:close");
                        Atspi.EventListener.deregister_from_callback ((owned) window_desktop_destroy_event_listener_cb, "window:desktop-destroy");
                    } catch (Error e) {
                        message ("Could not deregister focus or window event listener: %s", e.message);
                        Atspi.exit ();
                        quit ();
                    }

                    var atspi_exit_code = Atspi.exit();
                    debug ("AT-SPI exit code is %d.", atspi_exit_code);
                } // app_running
            }
        }

        private void register_listeners () {
            if (! auto_expand) {
                debug ("register_listeners: auto expand turned off.");
                return;
            }

            lock (listeners_registered) {
                if (listeners_registered) {
                    return;
                }
                if (focused_control == null) {
                    return;
                }

                debug ("Registering listeners...");

                try {
                    // Single keystrokes.
                    Atspi.register_keystroke_listener (listener, null, 0, Atspi.EventType.KEY_RELEASED_EVENT, Atspi.KeyListenerSyncType.NOSYNC);

                    // Shift.
                    Atspi.register_keystroke_listener (listener, null, IBus.ModifierType.SHIFT_MASK, Atspi.EventType.KEY_RELEASED_EVENT, Atspi.KeyListenerSyncType.NOSYNC);
                    // Shift-Lock.
                    Atspi.register_keystroke_listener (listener, null, IBus.ModifierType.LOCK_MASK, Atspi.EventType.KEY_RELEASED_EVENT, Atspi.KeyListenerSyncType.NOSYNC);
                    // Shift + Shift-Lock.
                    Atspi.register_keystroke_listener (listener, null, IBus.ModifierType.SHIFT_MASK | IBus.ModifierType.LOCK_MASK, Atspi.EventType.KEY_RELEASED_EVENT, Atspi.KeyListenerSyncType.NOSYNC);

                    // Mod2 (NumLock).
                    Atspi.register_keystroke_listener (listener, null, IBus.ModifierType.MOD2_MASK, Atspi.EventType.KEY_RELEASED_EVENT, Atspi.KeyListenerSyncType.NOSYNC);
                    // Mod2 + Shift.
                    Atspi.register_keystroke_listener (listener, null, IBus.ModifierType.MOD2_MASK | IBus.ModifierType.SHIFT_MASK, Atspi.EventType.KEY_RELEASED_EVENT, Atspi.KeyListenerSyncType.NOSYNC);
                    // Mod2 + Shift-Lock.
                    Atspi.register_keystroke_listener (listener, null, IBus.ModifierType.MOD2_MASK | IBus.ModifierType.LOCK_MASK, Atspi.EventType.KEY_RELEASED_EVENT, Atspi.KeyListenerSyncType.NOSYNC);
                    // Mod2 + Shift + Shift-Lock.
                    Atspi.register_keystroke_listener (listener, null, IBus.ModifierType.MOD2_MASK | IBus.ModifierType.SHIFT_MASK | IBus.ModifierType.LOCK_MASK, Atspi.EventType.KEY_RELEASED_EVENT, Atspi.KeyListenerSyncType.NOSYNC);

                    // Mod5 (ISO_Level3_Shift/Alt Gr).
                    Atspi.register_keystroke_listener (listener, null, IBus.ModifierType.MOD5_MASK, Atspi.EventType.KEY_RELEASED_EVENT, Atspi.KeyListenerSyncType.NOSYNC);
                    // Mod5 + Shift.
                    Atspi.register_keystroke_listener (listener, null, IBus.ModifierType.MOD5_MASK | IBus.ModifierType.SHIFT_MASK, Atspi.EventType.KEY_RELEASED_EVENT, Atspi.KeyListenerSyncType.NOSYNC);
                    // Mod5 + Shift-Lock.
                    Atspi.register_keystroke_listener (listener, null, IBus.ModifierType.MOD5_MASK | IBus.ModifierType.LOCK_MASK, Atspi.EventType.KEY_RELEASED_EVENT, Atspi.KeyListenerSyncType.NOSYNC);
                    // Mod5 + Shift + Shift-Lock.
                    Atspi.register_keystroke_listener (listener, null, IBus.ModifierType.MOD5_MASK | IBus.ModifierType.SHIFT_MASK | IBus.ModifierType.LOCK_MASK, Atspi.EventType.KEY_RELEASED_EVENT, Atspi.KeyListenerSyncType.NOSYNC);
                } catch (Error e) {
                    message ("Could not register keystroke listener: %s", e.message);
                    Atspi.exit ();
                    quit ();
                }

                listeners_registered = true;
                start_listening ();
            } // lock listeners_registered
        }

        private void deregister_listeners () {
            stop_listening ();

            lock (listeners_registered) {
                if (listeners_registered != true) {
                    return;
                }
                focused_control = null;
                last_focused_control = null;
                listeners_registered = false;

                debug ("De-registering listeners...");

                try {
                    // Single keystrokes.
                    Atspi.deregister_keystroke_listener (listener, null, 0, Atspi.EventType.KEY_RELEASED_EVENT);

                    // Shift.
                    Atspi.deregister_keystroke_listener (listener, null, IBus.ModifierType.SHIFT_MASK, Atspi.EventType.KEY_RELEASED_EVENT);
                    // Shift-Lock.
                    Atspi.deregister_keystroke_listener (listener, null, IBus.ModifierType.LOCK_MASK, Atspi.EventType.KEY_RELEASED_EVENT);
                    // Shift + Shift-Lock.
                    Atspi.deregister_keystroke_listener (listener, null, IBus.ModifierType.SHIFT_MASK | IBus.ModifierType.LOCK_MASK, Atspi.EventType.KEY_RELEASED_EVENT);

                    // Mod2 (NumLock).
                    Atspi.deregister_keystroke_listener (listener, null, IBus.ModifierType.MOD2_MASK, Atspi.EventType.KEY_RELEASED_EVENT);
                    // Mod2 + Shift.
                    Atspi.deregister_keystroke_listener (listener, null, IBus.ModifierType.MOD2_MASK | IBus.ModifierType.SHIFT_MASK, Atspi.EventType.KEY_RELEASED_EVENT);
                    // Mod2 + Shift-Lock.
                    Atspi.deregister_keystroke_listener (listener, null, IBus.ModifierType.MOD2_MASK | IBus.ModifierType.LOCK_MASK, Atspi.EventType.KEY_RELEASED_EVENT);
                    // Mod2 + Shift + Shift-Lock.
                    Atspi.deregister_keystroke_listener (listener, null, IBus.ModifierType.MOD2_MASK | IBus.ModifierType.SHIFT_MASK | IBus.ModifierType.LOCK_MASK, Atspi.EventType.KEY_RELEASED_EVENT);

                    // Mod5 (ISO_Level3_Shift/Alt Gr).
                    Atspi.deregister_keystroke_listener (listener, null, IBus.ModifierType.MOD5_MASK, Atspi.EventType.KEY_RELEASED_EVENT);
                    // Mod5 + Shift.
                    Atspi.deregister_keystroke_listener (listener, null, IBus.ModifierType.MOD5_MASK | IBus.ModifierType.SHIFT_MASK, Atspi.EventType.KEY_RELEASED_EVENT);
                    // Mod5 + Shift-Lock.
                    Atspi.deregister_keystroke_listener (listener, null, IBus.ModifierType.MOD5_MASK | IBus.ModifierType.LOCK_MASK, Atspi.EventType.KEY_RELEASED_EVENT);
                    // Mod5 + Shift + Shift-Lock.
                    Atspi.deregister_keystroke_listener (listener, null, IBus.ModifierType.MOD5_MASK | IBus.ModifierType.SHIFT_MASK | IBus.ModifierType.LOCK_MASK, Atspi.EventType.KEY_RELEASED_EVENT);
                } catch (Error e) {
                    message ("Could not deregister keystroke listener: %s", e.message);
                    Atspi.exit ();
                    quit ();
                }
            } // lock listeners_registered
        }

        private void start_listening () {
            lock (listening) {
                listening = true;
            }
            debug ("Started listening.");
        }

        private void stop_listening () {
            lock (listening) {
                listening = false;
            }
            debug ("Stopped listening.");
        }

        [CCode (instance_pos = -1)]
        private bool on_focus (Atspi.Event event) {
            try {
                // Quick shortcut out if editable text focused control not changed.
                if (focused_control != null && focused_control == event.source) {
                    return false;
                }

                // Quick shortcut out if control doesn't have keyboard focus.
                var state = event.source.get_state_set ();
                if (
                    ! state.contains (Atspi.StateType.EDITABLE) ||
                    ! state.contains (Atspi.StateType.FOCUSABLE) ||
                    ! state.contains (Atspi.StateType.FOCUSED) ||
                    ! state.contains (Atspi.StateType.SHOWING) ||
                    ! state.contains (Atspi.StateType.VISIBLE)
                ) {
                    return false;
                }

                // Quick shortcut out if some unusable focused control not changed.
                if (focused_control == null && last_focused_control != null && last_focused_control == event.source) {
                    return false;
                }
                last_focused_control = event.source;

                var app = event.source.get_application ();
                debug ("!!! FOCUS EVENT Type ='%s', Source: '%s'", event.type, app.get_name ());

                if (app.get_name () == this.application_id) {
                    debug ("Nope, not monitoring within %s!", app.get_name ());
                    deregister_listeners ();
                } else {
                    // Try and grab editable control's handle.
                    focused_control = event.source.get_editable_text_iface ();

                    if (focused_control != null) {
                        debug ("Focused editable text control found.");
                        register_listeners ();

                        // If new control found because of keystroke, check whether trigger key.
                        if (event.type == "object:text-changed:insert" && event.any_data.get_string ().length > 0) {
                            debug ("&&& VALUE INSERTED: '%s'", event.any_data.get_string ());
                            check_trigger (event.any_data.get_string ().substring (-1));
                        }
                    } else {
                        debug ("Focused editable text control not found.");
                        deregister_listeners ();
                    }
                }
            } catch (Error e) {
                message ("Could not get focused control: %s", e.message);
                deregister_listeners ();
            }

            return false;
        }

        [CCode (instance_pos = -1)]
        private bool on_window_deactivate (Atspi.Event event) {
            debug ("<<< WINDOW DEACTIVATE EVENT Type ='%s', Source: '%s'", event.type, event.source.name);

            deregister_listeners ();

            return false;
        }

        [CCode (instance_pos = -1)]
        private bool on_key_released_event (Atspi.DeviceEvent stroke) {
            debug ("*** KEY EVENT ID = '%u', Str = '%s'", stroke.id, stroke.event_string);

            if (stroke.is_text && stroke.event_string != null) {
                check_trigger (stroke.event_string);
            } // if something to check

            return false;
        }

        private void check_trigger (string trigger) {
            if (
                listening == true &&
                checking == false &&
                focused_control != null &&
                snippets_manager.triggers != null &&
                snippets_manager.triggers.size > 0 &&
                snippets_manager.triggers.has_key (trigger)
                ) {
                debug ("!!! GOT A TRIGGER KEY MATCH !!!");

                // Let thread check for abbreviation, while we let the target window have its keystroke.
                check_thread = new Thread<bool> ("check_thread", editable_text_check);
            } // if something to check
        }

        private bool editable_text_check () {
            var expanded = false;

            lock (checking) {
                if (checking == true) {
                    return expanded;
                }
                checking = true;
                debug ("Checking for abbreviation via editable text...");

                stop_listening ();

                if (focused_control == null) {
                    debug ("No focused control, oops!");
                    checking = false;
                    start_listening ();
                    return expanded;
                }

                var ctrl = (Atspi.Text) focused_control;
                var caret_offset = 0;

                Thread.yield ();
                Thread.usleep (SLEEP_INTERVAL);

                try {
                    caret_offset = ctrl.get_caret_offset ();
                } catch (Error e) {
                    message ("Could not get caret offset: %s", e.message);
                    checking = false;
                    start_listening ();
                    return expanded;
                }
                debug ("Caret Offset %d", caret_offset);

                var last_str = "";
                var tries = 1;
                var min = 1;
                var last_min = 1;

                for (int pos = 1; pos <= snippets_manager.max_abbr_len; pos++) {
                    if (pos < min) {
                        continue;
                    }

                    var sel_start = caret_offset - pos;
                    var sel_end = caret_offset;
                    var str = "";

                    try {
                        str = ctrl.get_text (sel_start, sel_end);
                    } catch (Error e) {
                        message ("Could not get text between positions %d and %d: %s", sel_start, sel_end, e.message);
                        break;
                    }
                    debug ("Pos %d, Str %s", pos, str);

                    if (str == null || str == last_str || str.char_count () != pos) {
                        tries++;

                        if (tries > 3) {
                            debug ("Tried 3 times to get some text, giving up.");
                            break;
                        }

                        debug ("Text different than expected, starting again, attempt #%d.", tries);
                        last_str = "";
                        min = last_min;
                        pos = 0;
                        continue;
                    }

                    last_str = str;
                    last_min = min;

                    var count = snippets_manager.count_snippets_ending_with (str);
                    debug ("Count of abbreviations ending with '%s': %d", str, count);

                    if (count < 1) {
                        debug ("Nothing matched '%s'", str);
                        break;
                    } else if (snippets_manager.abbreviations.has_key (str)) {
                        debug ("IT'S AN ABBREVIATION!!!");

                        var editable_ctrl = (Atspi.EditableText) focused_control;

                        try {
                            if (! editable_ctrl.delete_text (sel_start, sel_end)) {
                                message ("Could not delete abbreviation string from text.");
                                break;
                            }
                        } catch (Error e) {
                            message ("Could not delete abbreviation string from text between positions %d and %d: %s", sel_start, sel_end, e.message);
                            break;
                        }

                        var selected_snippet = snippets_manager.select_snippet (str);

                        // Before trying to insert the snippet's body, parse it to expand placeholders such as date/time and embedded snippets.
                        var new_offset = -1;
                        var dt = new DateTime.now_local ();
                        var body = expand_snippet (selected_snippet.body, ref new_offset, dt);
                        body = collapse_escaped_placeholder_delimiter (body, ref new_offset);

                        selected_snippet.last_used = dt;
                        snippets_manager.update (selected_snippet);

                        try {
                            if (! editable_ctrl.insert_text (sel_start, body, body.length)) {
                                message ("Could not insert expanded snippet into text.");
                                break;
                            }
                        } catch (Error e) {
                            message ("Could not insert expanded snippet into text at position %d: %s", sel_start, e.message);
                            break;
                        }

                        if (new_offset >= 0) {
                            try {
                                if (! ((Atspi.Text) editable_ctrl).set_caret_offset (sel_start + new_offset)) {
                                    message ("Could not set new cursor position.");
                                    break;
                                }
                            } catch (Error e) {
                                message ("Could not set new cursor at position %d: %s", sel_start + new_offset, e.message);
                                break;
                            }
                        }

                        expanded = true;
                        break;
                    } // have matching abbreviation

                    // We can can try and speed things up a bit.
                    min = snippets_manager.min_length_ending_with (str);
                    debug ("Minimum length of abbreviations ending with '%s': %d", str, min);
                } // step back through characters

                checking = false;
                start_listening ();
            } // lock checking

            return expanded;
        }

        private string collapse_escaped_placeholder_delimiter (owned string body, ref int caret_offset) {
            var diff = placeholder_delimiter_escaped.length - placeholder_delimiter.length;
            var index = body.index_of (placeholder_delimiter_escaped);

            while (index >= 0) {
                body = body.splice (index, index + placeholder_delimiter_escaped.length, placeholder_delimiter);

                if (caret_offset > index) {
                    caret_offset -= diff;
                }

                index = body.index_of (placeholder_delimiter_escaped);
            }

            return body;
        }

        private string expand_snippet (string body, ref int caret_offset, DateTime dt, int level = 0) {
            level++;

            // We don't want keep on going down the rabbit hole for ever.
            if (level > 3) {
                debug ("Too much inception at level %d, returning to the surface.", level);
                return body;
            }

            // Quick check that placeholder exists at least once in string, and a macro name start is too.
            if (body.contains (placeholder_delimiter) && body.contains (placeholder_delimiter.concat (placeholder_macro))) {
                string result = "";
                var bits = body.split (placeholder_delimiter);

                foreach (string bit in bits) {
                    // Other Placeholder.
                    bit = expand_snippet_placeholder (bit, ref caret_offset, dt, level, result);

                    // Date/Time Placeholder.
                    bit = expand_date_placeholder (bit, dt);

                    // Clipboard Placeholder.
                    bit = expand_clipboard_placeholder (bit);

                    // Cursor Placeholder.
                    if (expand_cursor_placeholder (bit)) {
                        caret_offset = result.length;
                        debug ("New caret offset = %d", caret_offset);
                    } else {
                        result = result.concat (bit);
                    }
                }

                return result;
            }

            return body;
        }

        private string expand_snippet_placeholder (owned string body, ref int caret_offset, DateTime dt, int level, string result) {
            string macros[] = { "snippet", _("snippet") };
            Gee.HashMap<string,bool> done = new Gee.HashMap<string,bool> ();

            foreach (string macro in macros) {
                // If macro name not translated, don't repeat ourselves.
                if (done.has_key (macro)) {
                    continue;
                } else {
                    done.set (macro, true);
                }

                /*
                 * Expect "@snippet:abbr"
                 */
                if (body.index_of (placeholder_macro.concat (macro, ":")) == 0) {
                    var str = body.substring (placeholder_macro.concat (macro, ":").length);
                    debug ("Embedded snippet placeholder value: '%s'", str);

                    /*
                     * If abbreviation exists, get its body and run through expansion.
                     */
                    if (snippets_manager.abbreviations.has_key (str)) {
                        debug ("Embedded snippet '%s' exists, yay.", str);
                        body = snippets_manager.abbreviations.get (str);

                        var new_offset = -1;
                        body = expand_snippet(body, ref new_offset, dt, level);

                        if (new_offset >= 0) {
                            caret_offset = result.length + new_offset;
                        }

                        // Don't need to process other macro name variants.
                        return body;
                    }
                }
            }

            return body;
        }

        private string expand_date_placeholder (owned string body, DateTime dt) {
            string macros[] = { "date", "time", _("date"), _("time") };
            Gee.HashMap<string,bool> done = new Gee.HashMap<string,bool> ();

            foreach (string macro in macros) {
                // If macro name not translated, don't repeat ourselves.
                if (done.has_key (macro)) {
                    continue;
                } else {
                    done.set (macro, true);
                }

                /*
                 * Test for macro in following order...
                 * @macro@calc:fmt
                 * @macro@calc:
                 * @macro@calc
                 * @macro:fmt
                 * @macro:
                 * @macro
                 */
                if (body.index_of (placeholder_macro.concat (macro, placeholder_macro)) == 0) {
                    var rest = body.substring (placeholder_macro.concat (macro, placeholder_macro).length);

                    var calc = rest.substring (0, rest.index_of (":"));
                    var fmt = rest.substring (calc.length);

                    fmt = maybe_fix_date_placeholder_format (fmt, macro);

                    var ndt = dt.to_local ();
                    var pos = 0;
                    var cnt = 0;
                    var nums = calc.split_set ("YMWDhms");

                    if (nums.length == 0) {
                        warning (_("Date adjustment does not seem to have a positive or negative integer in placeholder '%1$s'."), body);
                        return body;
                    }

                    foreach (string num_str in nums) {
                        cnt++;

                        // Because we expect the calc string to end with a "delimiter", chances are we'll get a blank last element.
                        if (num_str.length == 0 && nums.length == cnt) {
                            continue;
                        }

                        var num = int.parse (num_str);

                        if (num == 0) {
                            warning (_("Date adjustment number %1$d does not seem to start with a positive or negative integer in placeholder '%2$s'."), cnt, body);
                            return body;
                        }

                        pos += num_str.length;
                        var unit = calc.substring (pos, 1);
                        pos++;

                        switch (unit) {
                            case "Y":
                                ndt = ndt.add_years (num);
                                break;
                            case "M":
                                ndt = ndt.add_months (num);
                                break;
                            case "W":
                                ndt = ndt.add_weeks (num);
                                break;
                            case "D":
                                ndt = ndt.add_days (num);
                                break;
                            case "h":
                                ndt = ndt.add_hours (num);
                                break;
                            case "m":
                                ndt = ndt.add_minutes (num);
                                break;
                            case "s":
                                ndt = ndt.add_seconds (num);
                                break;
                            default:
                                warning (_("Date adjustment number %1$d does not seem to end with either 'Y', 'M', 'W', 'D', 'h', 'm' or 's' in placeholder '%2$s'."), cnt, body);
                                return body;
                        }
                    }

                    var result = ndt.format (fmt);

                    if (result == null) {
                        warning (_("Oops, date format '%1$s' could not be parsed."), fmt);
                        return body;
                    } else {
                        return result;
                    }
                } else if (body.index_of (placeholder_macro.concat (macro)) == 0) {
                    var fmt = body.substring (placeholder_macro.concat (macro).length);

                    fmt = maybe_fix_date_placeholder_format (fmt, macro);

                    var result = dt.format (fmt);

                    if (result == null) {
                        warning (_("Oops, date format '%1$s' could not be parsed."), fmt);
                        return body;
                    } else {
                        return result;
                    }
                }
            }

            return body;
        }

        private string maybe_fix_date_placeholder_format (owned string fmt, owned string macro) {
            // Strip leading ":" from format string.
            if (fmt.has_prefix (":")) {
                fmt = fmt.substring (1);
            }

            if (fmt.strip ().length == 0 && (macro == "date" || macro == _("date"))) {
                fmt = "%x";
            }

            if (fmt.strip ().length == 0 && (macro == "time" || macro == _("time"))) {
                fmt = "%X";
            }

            return fmt;
        }

        private string expand_clipboard_placeholder (string body) {
            string macros[] = { "clipboard", _("clipboard") };
            Gee.HashMap<string,bool> done = new Gee.HashMap<string,bool> ();

            foreach (string macro in macros) {
                // If macro name not translated, don't repeat ourselves.
                if (done.has_key (macro)) {
                    continue;
                } else {
                    done.set (macro, true);
                }

                var board = Gtk.Clipboard.get_default (Gdk.Display.get_default ());

                /*
                 * Expect "@clipboard"
                 *
                 * Currently only handles text from clipboard, and this will be the default if other formats added later.
                 */
                if (body.index_of (placeholder_macro.concat (macro)) == 0 && board.wait_is_text_available ()) {
                    var text = board.wait_for_text ();

                    if (text == null) {
                        continue;
                    } else {
                        body = text;
                    }

                    // Don't need to process other macro name variants.
                    return body;
                }
            }

            return body;
        }

        private bool expand_cursor_placeholder (string body) {
            string macros[] = { "cursor", _("cursor") };
            Gee.HashMap<string,bool> done = new Gee.HashMap<string,bool> ();

            foreach (string macro in macros) {
                // If macro name not translated, don't repeat ourselves.
                if (done.has_key (macro)) {
                    continue;
                } else {
                    done.set (macro, true);
                }

                /*
                 * Expect "@cursor"
                 */
                if (body.index_of (placeholder_macro.concat (macro)) == 0) {
                    // Don't need to process other macro name variants.
                    return true;
                }
            }

            return false;
        }

        private void set_default_shortcut () {
            if (SEARCH_AND_PASTE_CMD.length == 0) {
                return;
            }

            var keystroke = "<Control>grave";

            CustomShortcutSettings.init ();

            foreach (var shortcut in CustomShortcutSettings.list_custom_shortcuts ()) {
                if (shortcut.command == SEARCH_AND_PASTE_CMD) {
                    debug ("Found shortcut: %s, for command: %s, in schema: %s", shortcut.shortcut, shortcut.command, shortcut.relocatable_schema);
                    return;
                }
            }

            var shortcut = CustomShortcutSettings.create_shortcut ();
            if (shortcut != null) {
                CustomShortcutSettings.edit_shortcut (shortcut, keystroke);
                CustomShortcutSettings.edit_command (shortcut, SEARCH_AND_PASTE_CMD);
            }
        }

        /**
         * "Borrowed" from Clipped by David Hewitt.
         * https://github.com/davidmhewitt/clipped/blob/b00d44757cc2bf7bc9948d535668099db4ab9896/src/ClipboardManager.vala#L55
         */
        private void paste () {
            debug ("paste start");

            // TODO: Ctrl-v isn't always the right thing to do, e.g. Terminal, or changed paste hot-key combination.
            perform_key_event ("<Control>v", true, 0);
            perform_key_event ("<Control>v", false, 0);

            Thread.yield ();
            Thread.usleep (SLEEP_INTERVAL);

            debug ("paste end");
        }

        /**
         * "Borrowed" from Clipped by David Hewitt.
         * https://github.com/davidmhewitt/clipped/blob/b00d44757cc2bf7bc9948d535668099db4ab9896/src/ClipboardManager.vala#L60
         */
        private static void perform_key_event (string accelerator, bool press, ulong delay) {
            uint keysym;
            Gdk.ModifierType modifiers;
            Gtk.accelerator_parse (accelerator, out keysym, out modifiers);
            unowned X.Display display = Gdk.X11.get_default_xdisplay ();
            int keycode = display.keysym_to_keycode (keysym);

            if (keycode != 0) {
                if (Gdk.ModifierType.CONTROL_MASK in modifiers) {
                    int modcode = display.keysym_to_keycode (Gdk.Key.Control_L);
                    XTest.fake_key_event (display, modcode, press, delay);
                }

                if (Gdk.ModifierType.SHIFT_MASK in modifiers) {
                    int modcode = display.keysym_to_keycode (Gdk.Key.Shift_L);
                    XTest.fake_key_event (display, modcode, press, delay);
                }

                XTest.fake_key_event (display, keycode, press, delay);
            }
        }

        private void show_window () {
            if (get_windows ().length () > 0) {
                get_windows ().data.present ();
                return;
            }

            app_window = new MainWindow (this);
            app_window.search_changed.connect ((search_term) => {
                search_changed (search_term);
            });
            app_window.search_escaped.connect (() => {
                search_escaped ();
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
        }

        private void show_search_and_paste_window () {
            if (search_and_paste_window != null) {
                return;
            }

            snippet_to_paste = null;
            string? selected_text = "";

            if (settings.get_boolean ("search-selected-text")) {
                var selection = Gtk.Clipboard.get (Gdk.SELECTION_PRIMARY);

                if (selection.wait_is_text_available ()) {
                    selected_text = selection.wait_for_text ();

                    if (selected_text == null) {
                        selected_text = "";
                    }
                }
            }

            search_and_paste_window = new SearchAndPasteWindow (snippets_manager.search_snippets (selected_text), selected_text);
            add_window (search_and_paste_window);

            search_and_paste_window.search_changed.connect ((text) => {
                refresh_search_and_paste_snippets (snippets_manager.search_snippets (text));
            });

            // Sometimes wingpanel will focus out the window on startup, so wait 200ms
            // before connecting the focus out handler
            Timeout.add (200, () => {
                search_and_paste_window.focus_out_event.connect (() => {
                    close_search_and_paste_window ();
                    return false;
                });

                return false;
            });

            search_and_paste_window.paste_snippet.connect ((snippet) => {
                snippet_to_paste = snippet;
            });
        }

        private void refresh_search_and_paste_snippets (Gee.ArrayList<Snippet?> snippets) {
            search_and_paste_window.clear_list ();
            foreach (var snippet in snippets) {
                search_and_paste_window.add_snippet (snippet);
            }
        }

        private void close_search_and_paste_window () {
            if (search_and_paste_window != null) {
                Timeout.add (250, () => {
                    search_and_paste_window.destroy ();
                    search_and_paste_window = null;
                    return false;
                });
            }

            snippet_to_paste = null;
        }

        private void save_ui_settings () {
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
        private void update_autostart (bool new_autostart) {
            var desktop_file_name = application_id + ".desktop";

            if (snap) {
                desktop_file_name = "snippetpixie_snippetpixie.desktop";
            }

            var app_info = new DesktopAppInfo (desktop_file_name);

            if (app_info == null) {
                warning ("Could not find desktop file with name: %s", desktop_file_name);
                return;
            }

            var desktop_file_path = app_info.get_filename();
            var desktop_file = File.new_for_path (desktop_file_path);
            var dest_path = Path.build_path (
                Path.DIR_SEPARATOR_S,
                Environment.get_user_config_dir (),
                "autostart",
                desktop_file_name
            );
            var dest_file = File.new_for_path (dest_path);

            // If we're turning off autostart, attempt to remove file and shortcut out.
            if (! new_autostart) {
                if (dest_file.query_exists ()) {
                    try {
                        dest_file.delete ();
                    } catch (Error e) {
                        warning ("Error removing autostart file: %s", e.message);
                        return;
                    }
                }

                return;
            }

            // Create autostart file.
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

                var exec_string = keyfile.get_string ("Desktop Entry", "Exec");
                var start = exec_string.last_index_of ("snippetpixie");
                var end = start + 12;
                exec_string = exec_string.splice (start, end, "snippetpixie --start");

                keyfile.set_string ("Desktop Entry", "Exec", exec_string);
                keyfile.set_boolean ("Desktop Entry", "X-GNOME-Autostart-enabled", new_autostart);

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

            if (snap) {
                desktop_file_name = "snippetpixie_snippetpixie.desktop";
            }

            var dest_path = Path.build_path (
                Path.DIR_SEPARATOR_S,
                Environment.get_user_config_dir (),
                "autostart",
                desktop_file_name
            );

            var dest_file = File.new_for_path (dest_path);
            var autostart_exists = dest_file.query_exists ();

            if (! autostart && ! autostart_exists) {
                // We don't want autostart and it's file does not exist, we're done.
                return false;
            }

            if (autostart && ! autostart_exists) {
                // We want autostart but it does not exist, create it.
                update_autostart (true);
                return true;
            }

            var curr_autostart = false;
            var keyfile = new KeyFile ();

            try {
                keyfile.load_from_file (dest_path, KeyFileFlags.NONE);
                curr_autostart = keyfile.get_boolean ("Desktop Entry", "X-GNOME-Autostart-enabled");
            } catch (Error e) {
                warning ("Error getting autostart status: %s", e.message);
            }

            return curr_autostart;
        }

        public override int command_line (ApplicationCommandLine command_line) {
            var snap_env = Environment.get_variable ("SNAP");

            if (snap_env != null && snap_env.contains ("snippetpixie")) {
                snap = true;
                SEARCH_AND_PASTE_CMD = "snippetpixie --search-and-paste";
            }

            show = true;
            search_and_paste = false;
            bool start = false;
            bool stop = false;
            string autostart = null;
            bool status = false;
            string export_file = null;
            string import_file = null;
            bool force = false;
            bool version = false;
            bool help = false;

            OptionEntry[] options = new OptionEntry[11];
            options[0] = { "show", 0, 0, OptionArg.NONE, ref show, _("Show Snippet Pixie's window (default action)"), null };
            options[1] = { "search-and-paste", 0, 0, OptionArg.NONE, ref search_and_paste, _("Show Snippet Pixie's quick search and paste window"), null };
            options[2] = { "start", 0, 0, OptionArg.NONE, ref start, _("Start with no window"), null };
            options[3] = { "stop", 0, 0, OptionArg.NONE, ref stop, _("Fully quit the application, including the background process"), null };
            options[4] = { "autostart", 0, 0, OptionArg.STRING, ref autostart, _("Turn auto start of Snippet Pixie on login, on, off, or show status of setting"), "{on|off|status}" };
            options[5] = { "status", 0, 0, OptionArg.NONE, ref status, _("Shows status of the application, exits with status 0 if running, 1 if not"), null };
            options[6] = { "export", 'e', 0, OptionArg.FILENAME, ref export_file, _("Export snippets to file"), "filename" };
            options[7] = { "import", 'i', 0, OptionArg.FILENAME, ref import_file, _("Import snippets from file, skips snippets where abbreviation already exists"), _("filename") };
            options[8] = { "force", 0, 0, OptionArg.NONE, ref force, _("If used in conjunction with import, existing snippets with same abbreviation are updated"), null };
            options[9] = { "version", 0, 0, OptionArg.NONE, ref version, _("Display version number"), null };
            options[10] = { "help", 'h', 0, OptionArg.NONE, ref help, _("Display this help"), null };

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

            lock (app_running) {
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
                        settings.set_boolean ("autostart", true);
                        update_autostart (true);
                        return 0;
                    case "off":
                        settings.set_boolean ("autostart", false);
                        update_autostart (false);
                        return 0;
                    case "status":
                        this.autostart = settings.get_boolean ("autostart");
                        if (this.autostart) {
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

                if (start || search_and_paste) {
                    show = false;
                }

                // If we get here we're either showing the window or running the background process.
                if ( show == false || ! app_running ) {
                    hold ();
                }
            } // lock app_running

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

            // Tell X11 we're using threads.
            X.init_threads ();

            var app = get_default ();
            app.SEARCH_AND_PASTE_CMD = Path.get_basename (args[0]) + " --search-and-paste";
            var exit_code = app.run (args);

            debug ("Application terminated with exit code %d.", exit_code);
            return exit_code;
        }
    }
}
