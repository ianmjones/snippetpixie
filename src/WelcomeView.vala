public class WelcomeView : Gtk.Grid {
    construct {
        var welcome = new Granite.Widgets.Welcome ( _("Snippet Pixie"), _("Your little snippet helper."));
        welcome.append (_("document-new"), _("Add Snippet"), _("Create your first snippet."));
        welcome.append (_("document-import"), _("Import Snippets"), _("Import previously exported snippets."));
        welcome.append (_("help-contents"), _("Quick Start Guide"), _("Learn the basics of how to use Snippet Pixie."));

        add (welcome);

        welcome.activated.connect ((index) => {
            switch (index) {
                case 0:
                    try {
                        AppInfo.launch_default_for_uri ("https://valadoc.org/granite/Granite.html", null);
                    } catch (Error e) {
                        warning (e.message);
                    }

                    break;
                case 1:
                    try {
                        AppInfo.launch_default_for_uri ("https://github.com/elementary/granite", null);
                    } catch (Error e) {
                        warning (e.message);
                    }

                    break;
                case 2:
                    try {
                        AppInfo.launch_default_for_uri ("https://www.snippetpixie.com/", null);
                    } catch (Error e) {
                        warning (e.message);
                    }

                    break;
            }
        });
    }
}
