project('com.github.bytepixie.snippetpixie', 'vala', 'c')

gnome = import('gnome')
i18n = import('i18n')

add_global_arguments('-DGETTEXT_PACKAGE="@0@"'.format (meson.project_name()), language:'c')

asresources = gnome.compile_resources(
    'as-resources', 'data/' + meson.project_name() + '.gresource.xml',
    source_dir: 'data',
    c_name: 'as'
)

executable(
    meson.project_name(),
    'src/Application.vala',
    'src/Snippet.vala',
    'src/SnippetsManager.vala',
    'src/Utils.vala',
    'src/Settings/CustomShortcutSettings.vala',
    'src/Settings/Shortcut.vala',
    'src/Widgets/FramedTextView.vala',
    'src/Widgets/MainWindowHeader.vala',
    'src/Widgets/SearchAndPasteList.vala',
    'src/Widgets/SearchAndPasteListRow.vala',
    'src/Widgets/ShortcutEntry.vala',
    'src/Widgets/SnippetsList.vala',
    'src/Widgets/SnippetsListItem.vala',
    'src/Widgets/ViewStack.vala',
    'src/Widgets/WelcomeView.vala',
    'src/Windows/MainWindow.vala',
    'src/Windows/SearchAndPasteWindow.vala',
    asresources,
    dependencies: [
        dependency('atspi-2', version: '>=2.0'),
        dependency('gdk-x11-3.0'),
        dependency('gee-0.8'),
        dependency('glib-2.0'),
        dependency('gobject-2.0'),
        dependency('granite', version: '>=5.4'),
        dependency('gtk+-3.0'),
        dependency('ibus-1.0'),
        dependency('json-glib-1.0'),
        dependency('sqlite3'),
        dependency('xtst'),
        dependency('x11', version: '>=1.0'),
        meson.get_compiler('c').find_library('m', required : false)
    ],
    install: true
)
subdir('data')
subdir('po')

meson.add_install_script('meson/post_install.py')

install_man('man/snippetpixie.1')
install_man('man/snippetpixie-placeholders.5')
