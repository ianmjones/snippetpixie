/*
* Copyright (c) 2020 Byte Pixie Limited (https://www.bytepixie.com)
* Copyright (c) 2017 David Hewitt (https://github.com/davidmhewitt)
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
* Based on Clipped's MainWindow.vala
* https://github.com/davidmhewitt/clipped/blob/b00d44757cc2bf7bc9948d535668099db4ab9896/src/MainWindow.vala
*/

public class SnippetPixie.SearchAndPasteWindow : Gtk.Dialog {
    public signal void search_changed (string search_term);
    public signal void paste_snippet (Snippet snippet);

    private const string SEARCH_CSS =
    """
        .large-search-entry {
            font-size: 175%;
            border: none;
        }
    """;

    private SearchAndPasteList list_box;
    private Gtk.Stack stack;
    private Gtk.SearchEntry search_headerbar;
    private Settings settings = new Settings (Application.ID);

    public SearchAndPasteWindow (Gee.ArrayList<Snippet?> snippets, string selected_text) {
        Gtk.Container content_area = get_content_area () as Gtk.Container;

        if (content_area == null) {
            return;
        }

        icon_name = Application.ID;

        set_keep_above (true);
        window_position = Gtk.WindowPosition.CENTER;

        set_default_size (640, 480);

        search_headerbar = new Gtk.SearchEntry ();
        search_headerbar.placeholder_text = _("Search Snippets\u2026");
        search_headerbar.hexpand = true;
        search_headerbar.text = selected_text;
        search_headerbar.key_press_event.connect ((event) => {
            switch (event.keyval) {
                case Gdk.Key.Escape:
                    close ();
                    return true;
                default:
                    return false;
            }
        });
        search_headerbar.search_changed.connect (() => {
            search_changed (search_headerbar.text);
        });

        var font_size_provider = new Gtk.CssProvider ();
        try {
            font_size_provider.load_from_data (SEARCH_CSS, -1);
        } catch (Error e) {
            warning ("Failed to load CSS style for search box: %s", e.message);
        }
        var style_context = search_headerbar.get_style_context ();
        style_context.add_provider (font_size_provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
        style_context.add_class ("large-search-entry");

        var list_box_scroll = new Gtk.ScrolledWindow (null, null);
        list_box_scroll.vexpand = true;
        list_box = new SearchAndPasteList ();
        list_box_scroll.add (list_box);
        list_box_scroll.show_all ();

        list_box.row_activated.connect ((row) => {
            SearchAndPasteListRow sprow = row as SearchAndPasteListRow;

            if (sprow == null) {
                return;
            }

            paste_snippet (sprow.snippet);
            destroy ();
        });

        var not_found = new Granite.Widgets.Welcome ( _("No Snippets Found"), _("Please try entering a different search term."));
        var no_snippets = new Granite.Widgets.Welcome ( _("No Snippets Found"), _("Please add some snippets!"));

        stack = new Gtk.Stack ();
        stack.add_named (list_box_scroll, "listbox");
        stack.add_named (not_found, "not_found");
        stack.add_named (no_snippets, "no_snippets");

        foreach (var snippet in snippets) {
            add_snippet (snippet);
        }

        content_area.add (stack);

        key_press_event.connect ((event) => {
            switch (event.keyval) {
                case Gdk.Key.@0:
                case Gdk.Key.@1:
                case Gdk.Key.@2:
                case Gdk.Key.@3:
                case Gdk.Key.@4:
                case Gdk.Key.@5:
                case Gdk.Key.@6:
                case Gdk.Key.@7:
                case Gdk.Key.@8:
                case Gdk.Key.@9:
                    if (!search_headerbar.is_focus) {
                        uint val = event.keyval - Gdk.Key.@0;
                        if (val == 0) {
                            val = 10;
                        }
                        list_box.select_row (list_box.get_row_at_index ((int)val - 1));
                        var rows = list_box.get_selected_rows ();
                        if (rows.length () > 0) {
                            rows.nth_data (0).grab_focus ();
                        }
                        list_box.activate_cursor_row ();
                        return true;
                    }

                    break;
                case Gdk.Key.Down:
                case Gdk.Key.Up:
                    bool has_selection = list_box.get_selected_rows ().length () > 0;
                    if (!has_selection) {
                        list_box.select_row (list_box.get_row_at_index (0));
                    }
                    var rows = list_box.get_selected_rows ();
                    if (rows.length () > 0) {
                        rows.nth_data (0).grab_focus ();
                    }
                    if (has_selection) {
                        list_box.key_press_event (event);
                    }
                    return true;
                case Gdk.Key.Return:
                    bool has_selection = list_box.get_selected_rows ().length () > 0;
                    if (has_selection && Gdk.ModifierType.SHIFT_MASK in event.state) {
                        list_box.activate_cursor_row ();
                        return true;
                    }
                    return false;
                default:
                    break;
            }

            if (event.keyval != Gdk.Key.Escape && event.keyval != Gdk.Key.Shift_L && event.keyval != Gdk.Key.Shift_R && !search_headerbar.is_focus) {
                search_headerbar.grab_focus ();
                search_headerbar.key_press_event (event);
                return true;
            }
            return false;
        });

        set_titlebar (search_headerbar);

        show_all ();

        if (settings.get_boolean ("focus-search")) {
            search_headerbar.grab_focus ();
        }

        update_stack_visibility ();
    }

    public void add_snippet (Snippet snippet) {
        uint? index = list_box.get_children ().length () + 1;
        if (index == 10) {
            index = 0;
        }
        if (index > 10) {
            index = null;
        }
        list_box.add (new SearchAndPasteListRow (index, snippet));
        update_stack_visibility ();
    }

    private void update_stack_visibility () {
        if (list_box.get_children ().length () > 0) {
            stack.visible_child_name = "listbox";
        } else if (Application.get_default ().snippets_manager.snippets.size > 0) {
            stack.visible_child_name = "not_found";
        } else {
            stack.visible_child_name = "no_snippets";
        }
    }

    public void clear_list () {
        foreach (var child in list_box.get_children ()) {
            list_box.remove (child);
        }
        update_stack_visibility ();
    }
}
