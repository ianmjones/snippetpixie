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

public class SnippetPixie.ViewStack : Gtk.Stack {
    private WelcomeView welcome;
    private Gtk.Entry abbreviation_entry;
    private FramedTextView body_entry;
    private Gtk.Button remove_button;
    private SnippetsList snippets_list;
    private bool form_updating = false;
    private bool abbr_updating = false;

    construct {
        this.transition_type = Gtk.StackTransitionType.CROSSFADE;

        // Welcome view shown when no snippets saved.
        welcome = new WelcomeView();

        // Snippets listed in left pane.
        var left_pane = new Gtk.Grid ();
        left_pane.orientation = Gtk.Orientation.VERTICAL;

        snippets_list = new SnippetsList();
        snippets_list.selection_changed.connect (update_form);
        Application.get_default ().snippets_manager.snippets_changed.connect ((snippets) => {
            if (! abbr_updating) {
                snippets_list.set_snippets (snippets);
            }
        });

        left_pane.add (snippets_list);

        // Snippet details in right pane.
        var snippet_form = new Gtk.Grid ();
        snippet_form.orientation = Gtk.Orientation.VERTICAL;
        snippet_form.margin = 12;
        snippet_form.row_spacing = 6;

        var abbreviation_label = new Gtk.Label (_("Abbreviation"));
        abbreviation_label.xalign = 0;
        snippet_form.add (abbreviation_label);

        abbreviation_entry = new Gtk.Entry ();
        abbreviation_entry.hexpand = true;
        abbreviation_entry.changed.connect (abbreviation_updated);
        snippet_form.add (abbreviation_entry);

        var body_label = new Gtk.Label (_("Body"));
        body_label.xalign = 0;
        snippet_form.add (body_label);

        body_entry = new FramedTextView ();
        body_entry.expand = true;
        body_entry.buffer.changed.connect (body_updated);
        snippet_form.add (body_entry);

        remove_button = new Gtk.Button.with_label (_("Remove Snippet"));
        remove_button.hexpand = true;
        remove_button.get_style_context ().add_class (Gtk.STYLE_CLASS_DESTRUCTIVE_ACTION);
        remove_button.clicked.connect (remove_snippet);
        snippet_form.add (remove_button);

        var main_hpaned = new Gtk.Paned (Gtk.Orientation.HORIZONTAL);
        main_hpaned.pack1 (left_pane, false, false);
        main_hpaned.pack2 (snippet_form, true, false);
        main_hpaned.position = 100; // TODO: Get from settings, enforce minimum.
        main_hpaned.show_all ();

        this.add_named (welcome, "welcome");
        this.add_named (main_hpaned, "snippets");
        this.show_all ();

        // Grab the current snippets.
        snippets_list.set_snippets (Application.get_default ().snippets_manager.snippets);
    }

    private void update_form (Snippet snippet) {
        form_updating = true;
        abbreviation_entry.text = snippet.abbreviation;
        body_entry.buffer.text = snippet.body;

        if (! abbr_updating) {
            abbreviation_entry.grab_focus ();
        }
        form_updating = false;
    }

    private void abbreviation_updated () {
        if (form_updating) {
            return;
        }

        var item = snippets_list.selected as SnippetsListItem;

        if (item.snippet.abbreviation != abbreviation_entry.text) {
            abbr_updating = true;
            item.snippet.abbreviation = abbreviation_entry.text;
            Application.get_default ().snippets_manager.update (item.snippet);
            abbr_updating = false;
        }
    }

    private void body_updated () {
        if (form_updating) {
            return;
        }

        var item = snippets_list.selected as SnippetsListItem;

        if (item.snippet.body != body_entry.buffer.text) {
            abbr_updating = true;
            item.snippet.body = body_entry.buffer.text;
            Application.get_default ().snippets_manager.update (item.snippet);
            abbr_updating = false;
        }
    }

    private void remove_snippet () {
        var item = snippets_list.selected as SnippetsListItem;

        Application.get_default ().snippets_manager.remove (item.snippet);

        if (snippets_list.first_item != null) {
            select_item (snippets_list.first_item);
        }
    }

    public void select_item (SnippetsListItem item) {
        snippets_list.selected = item;
    }

    public void select_latest_item () {
        if (snippets_list.latest_item != null) {
            select_item (snippets_list.latest_item);
        }
    }
}
