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

public class SnippetPixie.SnippetsList : Granite.Widgets.SourceList {
    public signal void selection_changed (Snippet? snippet);

    public void set_snippets (Gee.Collection<Snippet>? snippets) {
        int snippet_id = 0;

        if (this.selected != null) {
            var current_item = this.selected as SnippetsListItem;
            snippet_id = current_item.snippet.id;
        }

        root.clear ();

        if ( null != snippets && ! snippets.is_empty ) {
            SnippetsListItem item = null;

            foreach ( var snippet in snippets ) {
                item = new SnippetsListItem.from_snippet (snippet);
                root.add (item);

                if (snippet_id != 0 && snippet_id == snippet.id) {
                    this.selected = item;
                }
            }

            // If nothing selected, select last item.
            // if (this.selected == null && item != null) {
            // message ("HEY HEY HEY");
            //     this.selected = item;
            // }
        }
    }

    public override void item_selected (Granite.Widgets.SourceList.Item? item) {
        if (item is SnippetsListItem) {
            var list_item = item as SnippetsListItem;
            selection_changed (list_item.snippet);
        // } else {
            // selection_changed (null);
        }
    }
}
