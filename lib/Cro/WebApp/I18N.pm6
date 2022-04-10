use Cro::HTTP::Router :DEFAULT, :plugin;
use POFile;

my $plugin-key = router-plugin-register('cro-webapp-i18n-files');
my $prefix-key = router-plugin-register('cro-webapp-i18n-prefix');

my class TranslationFile {
    has Str:D $.prefix is required;
    has POFile:D $.file is required;
    has Str @.languages;
}

#| Load a translation file and store it with a given prefix and a given (set of) language
sub load-translation-file(Str:D $prefix, $file, :language(:languages(@languages))) is export {
    my $pofile = POFile.load($file);
    my $translation-file = TranslationFile.new(:@languages, :$prefix, file => $pofile);
    router-plugin-add-config($plugin-key, $translation-file);
}

#| Configure the default prefix `_` should use.
#| This is useful for reducing duplication, especially in templates.
sub _-prefix(Str $prefix) is export {
    router-plugin-add-config($prefix-key, $prefix);
}

#| Install a language selection handler.
#| That handler will receive a list of languages accepted by the client (from the Accept-Language header),
#| and should return a language that will be used to filter against the loaded translation files.
sub select-language(Callable $fn) is export {
    # XXX We might register multiple `before-matched`, which is LTA
    before-matched {
        my @languages = get-languages(request.header('accept-language'));
        request.annotations<language> = $fn(@languages);
    }
}

#| Look up key and return its associated translation
sub _(Str $key, Str :$prefix is copy, Str :$default) is export {
    without $prefix {
        my @prefixes = router-plugin-get-innermost-configs($prefix-key)
                or die "No prefix configured, did you forget to call `_-prefix` or pass the prefix to _?";
        $prefix = @prefixes[*- 1];
    }
    my $language = guess-language;
    my %files = router-plugin-get-configs($plugin-key)
            .grep(*.prefix eq $prefix)
            .classify({ match-language(.languages, $language) });
    for |(%files{"1"} // ()), |(%files{"2"} // ()), |(%files{"3"} // ()) {
        with .file{$key} {
            return .msgstr;
        }
    }
    $default // die "No key $key in $prefix";
}

sub match-language(Str @languages, Str $accept --> Int) {
    if +@languages && $accept.defined {
        return 1 if any(@languages) eq $accept;
        return 2 if $accept ~~ /^@languages'-'/;
        # XXX is this fuzzy matching really necessary
        return 4
    } else {
        return 3
    }
}

sub guess-language(--> Str) {
    try { request.annotations<language> } // Str
}

# TODO move this to Request
sub get-languages($header) {
    with $header {
        # TODO q sort
        # TODO move this to a request method
        $header.split(',')>>.trim.map(*.split(';')[0].trim)
    } else {
        ()
    }
}