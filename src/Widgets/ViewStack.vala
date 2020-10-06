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
    private bool search_changing = false;

    private string search_term = "";

    construct {
        this.transition_type = Gtk.StackTransitionType.CROSSFADE;

        // Welcome view shown when no snippets saved.
        welcome = new WelcomeView();

        // Snippets listed in left pane.
        var left_pane = new Gtk.Grid ();
        left_pane.orientation = Gtk.Orientation.VERTICAL;

        snippets_list = new SnippetsList();
        snippets_list.selection_changed.connect (update_form);
        Application.get_default ().snippets_manager.snippets_changed.connect (update_ui);

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

        var not_found = new Granite.Widgets.Welcome ( _("No Snippets Found"), _("Please try entering a different search term."));

        this.add_named (welcome, "welcome");
        this.add_named (main_hpaned, "snippets");
        this.add_named (not_found, "not_found");
        this.show_all ();

        // Set up for filtering snippets by search box.
        snippets_list.set_filter_func (filter_snippets_by_search_term, false);
        Application.get_default ().search_changed.connect ((term) => {
            search_changing = true;
            search_term = term;
            snippets_list.refilter ();
            filter_ui ();
            search_changing = false;
        });
        Application.get_default ().search_escaped.connect (() => {
            abbreviation_entry.grab_focus ();
        });

        // Grab the current snippets.
        snippets_list.set_snippets (Application.get_default ().snippets_manager.snippets);
    }

    private void update_ui (Gee.ArrayList<Snippet> snippets, string reason = "update") {
        if (! abbr_updating) {
            snippets_list.set_snippets (snippets);

            if (snippets.size > 0 && reason == "remove" && search_term.length > 0) {
                filter_ui ();
            }
        }
    }

    private void filter_ui () {
        var item = snippets_list.get_first_child (snippets_list.root);
        if (item == null) {
            visible_child_name = "not_found";
        } else {
            snippets_list.selected = item;
            visible_child_name = "snippets";
        }
    }

    private void update_form (Snippet snippet) {
        form_updating = true;
        abbreviation_entry.text = snippet.abbreviation;
        body_entry.buffer.text = snippet.body;

        if (! abbr_updating && ! search_changing) {
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
    }

    public void select_item (SnippetsListItem item) {
        snippets_list.selected = item;
    }

    public void select_latest_item () {
        if (snippets_list.latest_item != null) {
            select_item (snippets_list.latest_item);
        }
    }

    public bool filter_snippets_by_search_term (Granite.Widgets.SourceList.Item item) {
        if (search_term.length == 0) {
            return true;
        }

        var snippet = ((SnippetsListItem) item).snippet;

        if (snippet.abbreviation.contains (search_term) || snippet.body.contains (search_term)) {
            return true;
        }

        if (! search_changing && snippets_list.selected != null && snippets_list.selected == item) {
            return true;
        }

        return false;
    }
}
