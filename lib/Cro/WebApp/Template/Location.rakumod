use v6.d;

#| Base role for template search locations added at route level
role Cro::WebApp::Template::Location {
    #| Try to resolve the specified template name in the provided location.
    #| Should return a type object if resolution is not possible.
    method try-resolve(Str $template --> IO::Path) { ... }
}

#| A file system location to search for templates in.
class Cro::WebApp::Template::Location::FileSystem does Cro::WebApp::Template::Location {
    has IO::Path $.location is required;

    method try-resolve(Str $template --> IO::Path) {
        my $file = $!location.add($template);
        $file.e && $file.f ?? $file.absolute.IO !! IO::Path
    }
}

#| A location corresponding to the routes lexically available in the current
#| route handler.
class Cro::WebApp::Template::Location::Resource does Cro::WebApp::Template::Location {
    has Str $.prefix is required;
    has &.resource-resolver is required;

    method try-resolve(Str $template --> IO::Path) {
        my $name = $!prefix
                ?? $!prefix ~ ($!prefix.ends-with('/') ?? '' !! '/') ~ $template
                !! $template;
        with &!resource-resolver($name) {
            .absolute.IO
        }
        else {
            IO::Path
        }
    }
}
