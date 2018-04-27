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

public class ViewStack : Gtk.Stack {
    private WelcomeView welcome;
    private Gtk.Paned main_hpaned;
    private Granite.Widgets.SourceList snippet_list;

    construct {
        this.transition_type = Gtk.StackTransitionType.CROSSFADE;
        
        // Welcome view shown when no snippets saved.
        welcome = new WelcomeView();

        // Snippets listed in left pane.
        var left_pane = new Gtk.Grid ();
        left_pane.orientation = Gtk.Orientation.VERTICAL;

        snippet_list = new Granite.Widgets.SourceList();
        var root = snippet_list.root;

        // TODO: Get snippets from settings/database.
        // TODO: Maybe use snippet groups?
        var spr = new Granite.Widgets.SourceList.Item ("spr`");
        root.add (spr);
        var sprt = new Granite.Widgets.SourceList.Item ("sprt`");
        root.add (sprt);

        left_pane.add (snippet_list);

        // Snippet details in right pane.
        var right_pane = new Gtk.Grid ();
        right_pane.orientation = Gtk.Orientation.VERTICAL;
        right_pane.margin = 12;
        right_pane.row_spacing = 6;

        var abbreviation_label = new Gtk.Label (_("Abbreviation"));
        abbreviation_label.xalign = 0;
        right_pane.add (abbreviation_label);

        var abbreviation_entry = new Gtk.Entry ();
        abbreviation_entry.hexpand = true;
        right_pane.add (abbreviation_entry);

        var body_label = new Gtk.Label (_("Body"));
        body_label.xalign = 0;
        right_pane.add (body_label);

        var body_entry = new FramedTextView ();
        body_entry.expand = true;
        right_pane.add (body_entry);

        main_hpaned = new Gtk.Paned (Gtk.Orientation.HORIZONTAL);
        main_hpaned.pack1 (left_pane, false, false);
        main_hpaned.pack2 (right_pane, true, false);
        main_hpaned.position = 100; // TODO: Get from settings, enforce minimum.
        main_hpaned.show_all ();
        
        this.add_named (welcome, "welcome");
        this.add_named (main_hpaned, "snippets");
        this.show_all ();
    }
}
