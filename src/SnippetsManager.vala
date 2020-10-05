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

public errordomain SnippetPixieError {
    INVALID_FORMAT
}

public class SnippetPixie.SnippetsManager : Object {
    public signal void snippets_changed (Gee.ArrayList<Snippet> snippets, string reason);

    // Current collection of snippets.
    public Gee.ArrayList<Snippet> snippets { get; private set; }
    public Gee.HashMap<string,string> abbreviations { get; private set; }
    public Gee.HashMap<string,bool> triggers { get; private set; }
    public int max_abbr_len = 0;

    private Sqlite.Database db;
    private int db_version = 150;

    public SnippetsManager () {
        init_database ();
        refresh_snippets ();
    }

    private void init_database () {
        var data_dir = Environment.get_user_data_dir ();
        var dir_path = Path.build_path (Path.DIR_SEPARATOR_S, data_dir, Environment.get_prgname ());
        var db_dir = File.new_for_path (dir_path);

        try {
            db_dir.make_directory_with_parents (null);
        } catch (GLib.Error err) {
            if (err is IOError.EXISTS == false) {
                error ("Could not create data directory: %s", err.message);
            }
        }

        var db_file = db_dir.get_child (Environment.get_prgname () + ".db");
        bool new_db = !db_file.query_exists ();

        open_database (db_file);

        int curr_db_version = 0;
        if (!new_db) {
            curr_db_version = get_db_version();
        }

        if (curr_db_version < db_version) {
            upgrade_database (curr_db_version);
        }
    }

    private void open_database (File db_file) {
        int ec = Sqlite.Database.open(db_file.get_path (), out db);
        if (ec != Sqlite.OK) {
            critical ("Unable to open database at %s", db_file.get_path ());
        }
    }

    public int get_db_version () {
        int version = 0;
        int count = 0;
        Sqlite.Statement stmt;

        // Make sure settings table exists before trying to get db version from it.
        string query = "SELECT COUNT(*) FROM sqlite_master WHERE type = 'table' AND name = 'settings';";
        int ec = db.prepare_v2 (query, query.length, out stmt);
        if (ec != Sqlite.OK) {
            critical ("Error preparing to fetch from database schema: %s\n", db.errmsg ());
            return version;
        }

        while ((ec = stmt.step ()) == Sqlite.ROW) {
            count = stmt.column_int (0);
        }
        if (ec != Sqlite.DONE) {
            critical ("Error checking whether settings table exists: %s\n", db.errmsg ());
            return version;
        }

        // If no table, assume db is from pre v1.5.0 and therefore has schema version 100.
        version = 100;
        if (count < 1) {
            return version;
        }

        query = "SELECT setting_value FROM settings WHERE setting_key = 'SCHEMA_VERSION';";
        ec = db.prepare_v2 (query, query.length, out stmt);
        if (ec != Sqlite.OK) {
            critical ("Error preparing to fetch schema version from settings table: %s\n", db.errmsg ());
            return version;
        }

        while ((ec = stmt.step ()) == Sqlite.ROW) {
            version = int.parse (stmt.column_text (0));
            return version;
        }
        if (ec != Sqlite.DONE) {
            warning ("Error getting schema version from settings table: %s\n", db.errmsg ());
            return version;
        }

        return version;
    }

    private void upgrade_database (int curr_db_version) {
        string query;
        string error_message;
        int ec;

        // 100: Snippets!
        if (curr_db_version < 100) {
            query = """
                CREATE TABLE IF NOT EXISTS snippets (
                    id INTEGER PRIMARY KEY NOT NULL,
                    abbreviation TEXT NOT NULL UNIQUE,
                    body TEXT NOT NULL
                );
                """;
            ec = db.exec (query, null, out error_message);
            if (ec != Sqlite.OK) {
                critical ("Unable to create snippets table in database. Error: %s", error_message);
            }
        }

        // 150: Track schema changes and last time snippet used.
        if (curr_db_version < 150) {
            query = """
                CREATE TABLE IF NOT EXISTS settings (
                    setting_key TEXT NOT NULL UNIQUE,
                    setting_value TEXT NOT NULL
                );
                """;
            ec = db.exec (query, null, out error_message);
            if (ec != Sqlite.OK) {
                critical ("Unable to create settings table in database. Error: %s", error_message);
            }

            query = """
                ALTER TABLE snippets ADD COLUMN last_used TIMESTAMP;
                """;
            ec = db.exec (query, null, out error_message);
            if (ec != Sqlite.OK) {
                critical ("Unable to add last_used column to snippets table in database. Error: %s", error_message);
            }

            query = """
                CREATE UNIQUE INDEX idx_snippets_last_used ON snippets (last_used, id);
                """;
            ec = db.exec (query, null, out error_message);
            if (ec != Sqlite.OK) {
                critical ("Unable to create index for last_used column on snippets table in database. Error: %s", error_message);
            }
        }

        // At the moment we'll play it safe and not use UPSERT.
        if (curr_db_version < 150) {
            insert_setting ("SCHEMA_VERSION", db_version.to_string ());
        } else {
            update_setting ("SCHEMA_VERSION", db_version.to_string ());
        }
    }

    private void insert_setting (string setting_key, string setting_value) {
        Sqlite.Statement stmt;

        const string query = "INSERT INTO settings (setting_key, setting_value) VALUES ($KEY, $VAL);";
        int ec = db.prepare_v2 (query, query.length, out stmt);
        if (ec != Sqlite.OK) {
            warning ("Error preparing to insert setting: %s\n", db.errmsg ());
            return;
        }

        int param_position = stmt.bind_parameter_index ("$KEY");
        assert (param_position > 0);
        stmt.bind_text (param_position, setting_key);

        param_position = stmt.bind_parameter_index ("$VAL");
        assert (param_position > 0);
        stmt.bind_text (param_position, setting_value);

        ec = stmt.step();
        if (ec != Sqlite.DONE) {
            warning ("Error inserting setting: %s\n", db.errmsg ());
        }
    }

    private void update_setting (string setting_key, string setting_value) {
        Sqlite.Statement stmt;

        const string query = "UPDATE settings SET (setting_value) = ($VAL) WHERE setting_key = $KEY;";
        int ec = db.prepare_v2 (query, query.length, out stmt);
        if (ec != Sqlite.OK) {
            warning ("Error preparing to update setting: %s\n", db.errmsg ());
            return;
        }

        int param_position = stmt.bind_parameter_index ("$VAL");
        assert (param_position > 0);
        stmt.bind_text (param_position, setting_value);

        param_position = stmt.bind_parameter_index ("$KEY");
        assert (param_position > 0);
        stmt.bind_text (param_position, setting_key);

        ec = stmt.step();
        if (ec != Sqlite.DONE) {
            warning ("Error updating setting: %s\n", db.errmsg ());
        }
    }

    /*
     * TODO: Enable when needed.
     *
    private void delete_setting (string setting_key) {
        Sqlite.Statement stmt;

        const string query = "DELETE FROM settings WHERE setting_key = $KEY;";
        int ec = db.prepare_v2 (query, query.length, out stmt);
        if (ec != Sqlite.OK) {
            warning ("Error preparing to delete setting: %s\n", db.errmsg ());
            return;
        }

        int param_position = stmt.bind_parameter_index ("$KEY");
        assert (param_position > 0);
        stmt.bind_text (param_position, setting_key);

        ec = stmt.step();
        if (ec != Sqlite.DONE) {
            warning ("Error deleting setting: %s\n", db.errmsg ());
        }
    }
    */

    private void insert_snippet (Snippet snippet) {
        Sqlite.Statement stmt;

        const string query = "INSERT INTO snippets (abbreviation, body) VALUES ($ABBR, $BODY);";
        int ec = db.prepare_v2 (query, query.length, out stmt);
        if (ec != Sqlite.OK) {
            warning ("Error preparing to insert snippet: %s\n", db.errmsg ());
            return;
        }

        int param_position = stmt.bind_parameter_index ("$ABBR");
        assert (param_position > 0);
        stmt.bind_text (param_position, snippet.abbreviation);

        param_position = stmt.bind_parameter_index ("$BODY");
        assert (param_position > 0);
        stmt.bind_text (param_position, snippet.body);

        ec = stmt.step();
        if (ec != Sqlite.DONE) {
            warning ("Error inserting snippet: %s\n", db.errmsg ());
        }
    }

    private void update_snippet (Snippet snippet) {
        Sqlite.Statement stmt;

        const string query = "UPDATE snippets SET (abbreviation, body, last_used) = ($ABBR, $BODY, $LASTUSED) WHERE id = $ID;";
        int ec = db.prepare_v2 (query, query.length, out stmt);
        if (ec != Sqlite.OK) {
            warning ("Error preparing to update snippet: %s\n", db.errmsg ());
            return;
        }

        int param_position = stmt.bind_parameter_index ("$ABBR");
        assert (param_position > 0);
        stmt.bind_text (param_position, snippet.abbreviation);

        param_position = stmt.bind_parameter_index ("$BODY");
        assert (param_position > 0);
        stmt.bind_text (param_position, snippet.body);

        param_position = stmt.bind_parameter_index ("$LASTUSED");
        assert (param_position > 0);
        stmt.bind_int64 (param_position, snippet.last_used.to_unix ());

        param_position = stmt.bind_parameter_index ("$ID");
        assert (param_position > 0);
        stmt.bind_int (param_position, snippet.id);

        ec = stmt.step();
        if (ec != Sqlite.DONE) {
            warning ("Error updating snippet: %s\n", db.errmsg ());
        }
    }

    private void delete_snippet (Snippet snippet) {
        Sqlite.Statement stmt;

        const string query = "DELETE FROM snippets WHERE id = $ID;";
        int ec = db.prepare_v2 (query, query.length, out stmt);
        if (ec != Sqlite.OK) {
            warning ("Error preparing to delete snippet: %s\n", db.errmsg ());
            return;
        }

        int param_position = stmt.bind_parameter_index ("$ID");
        assert (param_position > 0);
        stmt.bind_int (param_position, snippet.id);

        ec = stmt.step();
        if (ec != Sqlite.DONE) {
            warning ("Error deleting snippet: %s\n", db.errmsg ());
        }
    }

    private Gee.ArrayList<Snippet>? select_snippets () {
        Sqlite.Statement stmt;

        const string query = "SELECT id, abbreviation, body, last_used FROM snippets ORDER BY abbreviation, id;";
        int ec = db.prepare_v2 (query, query.length, out stmt);
        if (ec != Sqlite.OK) {
            warning ("Error preparing to fetch snippets: %s\n", db.errmsg ());
            return null;
        }

        var snippets = new Gee.ArrayList<Snippet?> ();
        while ((ec = stmt.step ()) == Sqlite.ROW) {
            Snippet snippet = new Snippet ();
            snippet.id = stmt.column_int (0);
            snippet.abbreviation = stmt.column_text (1);
            snippet.body = stmt.column_text (2);
            snippet.last_used = new DateTime.from_unix_utc (stmt.column_int64 (3));
            snippets.add (snippet);
        }
        if (ec != Sqlite.DONE) {
            warning ("Error fetching snippets: %s\n", db.errmsg ());
            return null;
        }

        return snippets;
    }

    public Snippet? select_snippet (string abbreviation) {
        Sqlite.Statement stmt;

        const string query = "SELECT id, abbreviation, body FROM snippets WHERE abbreviation = $ABR ORDER BY id;";
        int ec = db.prepare_v2 (query, query.length, out stmt);
        if (ec != Sqlite.OK) {
            warning ("Error preparing to fetch snippet: %s\n", db.errmsg ());
            return null;
        }

        int param_position = stmt.bind_parameter_index ("$ABR");
        assert (param_position > 0);
        stmt.bind_text (param_position, abbreviation);

        Snippet snippet = null;
        while ((ec = stmt.step ()) == Sqlite.ROW) {
            snippet = new Snippet ();
            snippet.id = stmt.column_int (0);
            snippet.abbreviation = stmt.column_text (1);
            snippet.body = stmt.column_text (2);
            snippet.last_used = new DateTime.from_unix_utc (stmt.column_int64 (3));

            // Return the first found, duplicates are ignored.
            return snippet;
        }
        if (ec != Sqlite.DONE) {
            warning ("Error fetching snippet: %s\n", db.errmsg ());
            return null;
        }

        return snippet;
    }

    public Gee.ArrayList<Snippet>? search_snippets (string term) {
        Sqlite.Statement stmt;

        const string query = """
            SELECT id, abbreviation, body, last_used
            FROM snippets
            WHERE abbreviation LIKE $ABR
            OR body LIKE $BODY
            ORDER BY last_used DESC, abbreviation, id;
        """;
        int ec = db.prepare_v2 (query, query.length, out stmt);
        if (ec != Sqlite.OK) {
            warning ("Error preparing to fetch snippets: %s\n", db.errmsg ());
            return null;
        }

        int param_position = stmt.bind_parameter_index ("$ABR");
        assert (param_position > 0);
        stmt.bind_text (param_position, "%" + term + "%");
        param_position = stmt.bind_parameter_index ("$BODY");
        assert (param_position > 0);
        stmt.bind_text (param_position, "%" + term + "%");

        var snippets = new Gee.ArrayList<Snippet?> ();
        while ((ec = stmt.step ()) == Sqlite.ROW) {
            Snippet snippet = new Snippet ();
            snippet.id = stmt.column_int (0);
            snippet.abbreviation = stmt.column_text (1);
            snippet.body = stmt.column_text (2);
            snippet.last_used = new DateTime.from_unix_utc (stmt.column_int64 (3));
            snippets.add (snippet);
        }
        if (ec != Sqlite.DONE) {
            warning ("Error fetching snippets: %s\n", db.errmsg ());
            return null;
        }

        return snippets;
    }

    public int count_snippets_ending_with (string abbreviation) {
        int count = 0;
        Sqlite.Statement stmt;

        const string query = "SELECT COUNT(DISTINCT id) FROM snippets WHERE abbreviation LIKE $ABR;";
        int ec = db.prepare_v2 (query, query.length, out stmt);
        if (ec != Sqlite.OK) {
            warning ("Error preparing to fetch snippet: %s\n", db.errmsg ());
            return count;
        }

        int param_position = stmt.bind_parameter_index ("$ABR");
        assert (param_position > 0);
        stmt.bind_text (param_position, "%" + abbreviation);

        while ((ec = stmt.step ()) == Sqlite.ROW) {
            count = stmt.column_int (0);

            // Return the value.
            return count;
        }
        if (ec != Sqlite.DONE) {
            warning ("Error fetching count of snippets ending with '%s': %s\n", abbreviation, db.errmsg ());
            return count;
        }

        return count;
    }

    public int min_length_ending_with (string abbreviation) {
        int min = 0;
        Sqlite.Statement stmt;

        const string query = "SELECT MIN(LENGTH(abbreviation)) FROM snippets WHERE abbreviation LIKE $ABR;";
        int ec = db.prepare_v2 (query, query.length, out stmt);
        if (ec != Sqlite.OK) {
            warning ("Error preparing to fetch minimum length of abbreviations with ending: %s\n", db.errmsg ());
            return min;
        }

        int param_position = stmt.bind_parameter_index ("$ABR");
        assert (param_position > 0);
        stmt.bind_text (param_position, "%" + abbreviation);

        while ((ec = stmt.step ()) == Sqlite.ROW) {
            min = stmt.column_int (0);

            // Return the value.
            return min;
        }
        if (ec != Sqlite.DONE) {
            warning ("Error fetching minimum length of abbreviations ending with '%s': %s\n", abbreviation, db.errmsg ());
            return min;
        }

        return min;
    }

    public int max_length_ending_with (string abbreviation) {
        int max = 0;
        Sqlite.Statement stmt;

        const string query = "SELECT MAX(LENGTH(abbreviation)) FROM snippets WHERE abbreviation LIKE $ABR;";
        int ec = db.prepare_v2 (query, query.length, out stmt);
        if (ec != Sqlite.OK) {
            warning ("Error preparing to fetch maximum length of abbreviations with ending: %s\n", db.errmsg ());
            return max;
        }

        int param_position = stmt.bind_parameter_index ("$ABR");
        assert (param_position > 0);
        stmt.bind_text (param_position, "%" + abbreviation);

        while ((ec = stmt.step ()) == Sqlite.ROW) {
            max = stmt.column_int (0);

            // Return the value.
            return max;
        }
        if (ec != Sqlite.DONE) {
            warning ("Error fetching maximum length of abbreviations ending with '%s': %s\n", abbreviation, db.errmsg ());
            return max;
        }

        return max;
    }

    public void add (Snippet snippet) {
        insert_snippet (snippet);
        refresh_snippets ("add");
    }

    public void update (Snippet snippet) {
        update_snippet (snippet);
        refresh_snippets ();
    }

    public void remove (Snippet snippet) {
        delete_snippet (snippet);
        refresh_snippets ("remove");
    }

    public void refresh_snippets (string reason = "update") {
        snippets = select_snippets ();
        abbreviations = new Gee.HashMap<string,string> ();
        triggers = new Gee.HashMap<string,bool> ();
        max_abbr_len = 0;

        foreach (var snippet in snippets) {
            abbreviations.set (snippet.abbreviation, snippet.body);
            triggers.set (snippet.trigger (), true);

            if (snippet.abbreviation.char_count () > max_abbr_len) {
                max_abbr_len = snippet.abbreviation.char_count ();
            }
        }

        snippets_changed (snippets, reason);
    }

    public int export_to_file (string filepath) {
        debug ("Export File Path: %s", filepath);

        try {
            var builder = new Json.Builder ();
            builder.begin_object ();
            builder.set_member_name ("generator");
            builder.add_string_value (Application.ID);
            builder.set_member_name ("version");
            builder.add_int_value (101);

            builder.set_member_name ("data");
            builder.begin_array ();
            builder.begin_object ();
            builder.set_member_name ("snippets");
            builder.begin_array ();

            Gee.ArrayList<Snippet> snippets = select_snippets ();
            foreach (var snippet in snippets) {
                builder.begin_object ();
                builder.set_member_name ("abbreviation");
                builder.add_string_value (snippet.abbreviation);
                builder.set_member_name ("body");
                builder.add_string_value (snippet.body);
                builder.end_object ();
            }

            builder.end_array (); // snippets array
            builder.end_object (); // snippets object
            builder.end_array (); // data array

            builder.end_object ();

            var root = builder.get_root ();
            var generator = new Json.Generator ();
            generator.set_root (root);
            generator.set_pretty (true);
            generator.to_file (filepath);
        } catch (Error e) {
            print ("%s\n", e.message);
            return 1;
        }

        return 0;
    }

    public int import_from_file (string filepath, bool overwrite) {
        // Currently only support JSON file (as per export).
        var parser = new Json.Parser ();

        try {
            parser.load_from_file (filepath);

            var node = parser.get_root ();
            print ("Importing: '%s'\n", filepath);

            import_json (node, overwrite);
        } catch (Error e) {
            print ("Unable to load '%s': %s\n", filepath, e.message);
            return 1;
        }

        return 0;
    }

    private void import_json (Json.Node node, bool overwrite) throws Error {
        // Root is JSON Object.
        if (node.get_node_type () != Json.NodeType.OBJECT) {
            throw new SnippetPixieError.INVALID_FORMAT ("Unexpected element type %s", node.type_name ());
        }

        unowned Json.Object obj = node.get_object ();

        if (!obj.has_member ("generator")) {
            throw new SnippetPixieError.INVALID_FORMAT ("Missing 'generator' element.");
        }

        var generator = obj.get_string_member ("generator");
        print ("Generator: '%s'\n", generator);

        if (generator != Application.ID) {
            throw new SnippetPixieError.INVALID_FORMAT ("Invalid 'generator' element value.");
        }

        if (!obj.has_member ("version")) {
            throw new SnippetPixieError.INVALID_FORMAT ("Missing 'version' element.");
        }

        var version = obj.get_int_member ("version");
        print ("Version: '%s'\n", version.to_string ());

        // TODO: Change test if new export file format versions created.
        if (version != 101) {
            throw new SnippetPixieError.INVALID_FORMAT ("Invalid 'version' element value.");
        }

        if (!obj.has_member ("data")) {
            throw new SnippetPixieError.INVALID_FORMAT ("Missing 'data' element.");
        }

        var data = obj.get_member ("data");

        process_data_array (data, version, overwrite);
    }

    private void process_data_array (Json.Node node, int64 version, bool overwrite) throws Error {
        if (node.get_node_type () != Json.NodeType.ARRAY) {
            throw new SnippetPixieError.INVALID_FORMAT ("Unexpected 'data' element type %s", node.type_name ());
        }

        unowned Json.Array array = node.get_array ();

        // Tables.
        Json.Array snippets = null;

        // Each array element in data is a Table object, with array of objects.
        foreach (unowned Json.Node item in array.get_elements ()) {
            var obj = item.get_object ();

            foreach (unowned string name in obj.get_members ()) {
                switch (name) {
                case "snippets":
                    snippets = obj.get_array_member ("snippets");
                    break;
                default:
                    throw new SnippetPixieError.INVALID_FORMAT ("Unexpected 'data' element '%s'", name);
                }
            }
        }

        // We expect at least an empty array of snippets.
        if (snippets == null) {
            throw new SnippetPixieError.INVALID_FORMAT ("Missing 'snippets' element within 'data' element.");
        }

        process_snippets_array (snippets, version, overwrite);
    }

    private void process_snippets_array (Json.Array array, int64 version, bool overwrite) throws Error {
        var count = array.get_length ();

        print ("Snippets to process: %u\n", count);

        if (count < 1) {
            return;
        }

        var created = 0;
        var updated = 0;
        var skipped = 0;

        foreach (unowned Json.Node item in array.get_elements ()) {
            var obj = item.get_object ();
            var abr = obj.get_string_member ("abbreviation");

            Snippet snippet = select_snippet (abr);

            if (snippet != null && ! overwrite) {
                skipped++;
                continue;
            }

            if (snippet != null) {
                snippet.body = obj.get_string_member ("body");
                update_snippet (snippet);
                updated++;
            } else {
                snippet = new Snippet ();
                snippet.abbreviation = abr;
                snippet.body = obj.get_string_member ("body");
                insert_snippet (snippet);
                created++;
            }
        }

        print ("Created: %u\n", created);
        print ("Updated: %u\n", updated);
        print ("Skipped: %u\n", skipped);

        refresh_snippets ();
     }
}
