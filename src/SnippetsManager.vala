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

public class SnippetPixie.SnippetsManager : Object {
    // Current collection of snippets.
    public Gee.ArrayList<Snippet> snippets { get; private set; }
    public Gee.HashMap<string,string> abbreviations { get; private set; }
    public Gee.HashMap<string,bool> triggers { get; private set; }
    public int max_abbr_len = 0;

    public SnippetsManager () {
        if (snippets == null ) {
            snippets = new Gee.ArrayList<Snippet> ();
            abbreviations = new Gee.HashMap<string,string> ();

            var snippet = new Snippet (1);
            abbreviations.set (snippet.abbreviation, snippet.body);
            snippets.add (snippet);

            snippet = new Snippet (2);
            snippet.abbreviation = "@b`";
            snippet.body = "hello@bytepixie.com";
            abbreviations.set (snippet.abbreviation, snippet.body);
            snippets.add (snippet);

            snippet = new Snippet (3);
            snippet.abbreviation = "sp`";
            snippet.body = "Snippet Pixie";
            abbreviations.set (snippet.abbreviation, snippet.body);
            snippets.add (snippet);

            snippet = new Snippet (4);
            snippet.abbreviation = "spu`";
            snippet.body = "https://www.snippetpixie.com";
            abbreviations.set (snippet.abbreviation, snippet.body);
            snippets.add (snippet);

            refresh_triggers ();

            max_abbr_len = 0;
            if (null != snippets && ! snippets.is_empty) {
                // TODO: Rename back to "snippet" when properly getting data from db?
                foreach (var snippetX in snippets) {
                    if (snippetX.abbreviation.char_count () > max_abbr_len) {
                        max_abbr_len = snippetX.abbreviation.char_count ();
                    }
                }
            }
        }
    }

    public void remove (Snippet snippet) {
        snippets.remove (snippet);
        abbreviations.unset (snippet.abbreviation);
        refresh_triggers ();
    }

    private void refresh_triggers () {
        triggers = new Gee.HashMap<string,bool> ();

        foreach (var snippet in snippets) {
            triggers.set (snippet.trigger (), true);
        }
    }
}
