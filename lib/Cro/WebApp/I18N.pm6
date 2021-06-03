use Cro::HTTP::Router :plugin;
use POFile;

my $plugin-key = router-plugin-register('cro-webapp-i18n');
my $prefix-key = router-plugin-register('cro-webapp-i18n-prefix');

sub load-translation-file(Str $prefix, $file) is export {
    router-plugin-add-config($plugin-key, $prefix => POFile.load($file));
}

sub _-prefix(Str $prefix) is export {
    router-plugin-add-config($prefix-key, $prefix);
}

proto sub _(|) is export {*}

multi sub _(Str $key) {
    my @prefixes = router-plugin-get-innermost-configs($prefix-key)
            or die "No prefix configured, did you mean to configure _-prefix or use the long form of _?";
    _(@prefixes[*-1], $key);
}

multi sub _(Str $prefix, Str $key) {
    my %config = router-plugin-get-configs($plugin-key);
    with %config{$prefix} {
        ($_{$key} // die "No key $key in $prefix").msgstr;
    } else {
        die "No such translation file: $prefix";
    }
}