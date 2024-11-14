use Cro::WebApp::LogTimelineSchema;
use Cro::WebApp::Template::ASTBuilder;
use Cro::WebApp::Template::Location;
use Cro::WebApp::Template::Parser;
use OO::Monitors;

#| Thrown when the requested template cannot be found.
class X::Cro::WebApp::Template::NotFound is Exception {
    has Str $.template-name;
    method message() {
        "Could not locate template '$!template-name'"
    }
}

#| A compiled template, which can be rendered.
class Cro::WebApp::Template::Compiled is implementation-detail {
    #| The repository that compiled this template.
    has $.repository;

    #| The source file for the template, if available.
    has IO::Path $.path;

    #| Files that are used by this template.
    has Cro::WebApp::Template::Compiled @.used-files;

    # Implementation details.
    has &.renderer;
    has %.exports;

    #| Renders the template, setting the provided argument as the topic.
    method render($topic, :$fragment --> Str) {
        my $*TEMPLATE-REPOSITORY = $!repository;
        &!renderer($topic)
    }
}

#| A template repository is used to resolve template names/paths into instances
#| of C<Cro::WebApp::Template::Compiled>, which are in turn used to render the
#| template. This role is implemented by the template repositories included in
#| C<Cro::WebApp>. Custom implementations should use the C<load-template>
#| function to turn an C<IO::Path> into a C<Cro::WebApp::Template::Compiled>.
role Cro::WebApp::Template::Repository {
    #| a Promise that resolves to the loaded prelude. Populated upon first
    #| request for the prelude.
    has Promise $!prelude;

    #| Resolve a template name into a C<Promise> that will be kept with a
    #| C<Cro::WebApp::Template::Compiled>.
    method resolve(Str $template-name, Cro::WebApp::Template::Location @locations? --> Promise) { ... }

    #| Resolve an absolute path into a C<Promise> that will be kept with a
    #| C<Cro::WebApp::Template::Compiled>.
    method resolve-absolute(IO() $abs-path, :@locations --> Promise) { ... }

    #| Resolve the template prelude, which contains various built-ins.
    method resolve-prelude(--> Promise) is implementation-detail {
        $!prelude //= start {
            my $*COMPILING-PRELUDE = True;
            load-template(%?RESOURCES<prelude.crotmp>.IO)
        }
    }
}

#| A template repository that looks for templates in the filesystem. The default
#| search path is the current working directory, however further locations may be
#| added. Once a template has been loaded, its compilation will be cached, and any
#| changes to the file on disk will not be considered.
monitor Cro::WebApp::Template::Repository::FileSystem does Cro::WebApp::Template::Repository {
    has Promise %!abs-path-to-compiled;
    has @!global-search-paths = '.'.IO;

    #| Looks through the search paths and locates the first matching template.
    #| Returns a Promise that will be kept with the template. The method
    #| C<resolve-absolute> is called to load the located template.
    method resolve(Str $template-name, Cro::WebApp::Template::Location @locations? --> Promise) {
        for @locations {
            with .try-resolve($template-name) {
                return self.resolve-absolute($_, :@locations);
            }
        }
        for @!global-search-paths {
            my $path = .add($template-name);
            return self.resolve-absolute($path.absolute.IO, :@locations) if $path.f;
        }
        die X::Cro::WebApp::Template::NotFound.new(:$template-name);
    }

    #| Loads a template from an absolute path, and caches the compilation of
    #| that template for future requests.
    method resolve-absolute(IO() $abs-path, :@locations --> Promise) {
        with %!abs-path-to-compiled{$abs-path} {
            $_
        }
        else {
            %!abs-path-to-compiled{$abs-path} = start load-template($abs-path, :@locations);
        }
    }

    #| Removes the template with the specified absolute path from the cache.
    method refresh(IO() $abs-path) {
        %!abs-path-to-compiled{$abs-path}:delete;
        Nil
    }

    #| Prepends a directory to the global template search locations.
    method add-global-location(IO::Path $location --> Nil) {
        @!global-search-paths.unshift($location);
    }
}

#| A subclass of C<Cro::WebApp::Template::Repository::FileSystem> that checks
#| the modified time of template files and refreshes them if the template on
#| disk changes. Ideal for development time.
monitor Cro::WebApp::Template::Repository::FileSystem::Reloading is Cro::WebApp::Template::Repository::FileSystem {
    has %!abs-path-to-mtime;
    has %!dependencies;

    #| Loads a template from an absolute path. If the file at that path didn't
    #| change since the last template compilation, nor any of the templates
    #| that it depends on, then the cached compilation of the template is
    #| returned. Otherwise, it is recompiled.
    method resolve-absolute(IO() $abs-path, :@locations --> Promise) {
        my $modified = $abs-path.modified;
        if (%!abs-path-to-mtime{$abs-path} // 0) != $modified {
            self.refresh($abs-path)
        }
        elsif %!dependencies{$abs-path} -> @deps {
            for @deps -> $dep-path {
                my $dep-modified = $dep-path.modified;
                if (%!abs-path-to-mtime{$dep-path} // 0) != $dep-modified {
                    self.refresh($abs-path);
                    last;
                }
            }
        }
        %!abs-path-to-mtime{$abs-path} = $modified;
        my Promise $compiled-promise = callsame;
        $compiled-promise.then: {
            if $compiled-promise.status == Kept {
                self.update-dependencies($compiled-promise.result);
            }
        }
        $compiled-promise
    }

    method update-dependencies($compiled) {
        sub collect-deps(Cro::WebApp::Template::Compiled $compiled) {
            for $compiled.used-files -> $used {
                take .absolute.IO with $used.path;
                collect-deps($used);
            }
        }
        %!dependencies{$compiled.path.absolute} = eager gather collect-deps($compiled);
    }
}

my $template-repo = %*ENV<CRO_DEV>
        ?? Cro::WebApp::Template::Repository::FileSystem::Reloading.new
        !! Cro::WebApp::Template::Repository::FileSystem.new;

#| Gets the currently active template repository. By default, this is
#| C<Cro::WebApp::Template::Repository::FileSystem>, however if the C<CRO_DEV>
#| environment variable is set, it will instead default to
#| C<Cro::WebApp::Template::Repository::FileSystem::Reloading>.
sub get-template-repository(--> Cro::WebApp::Template::Repository) is export {
    $template-repo
}

#| Set the template repository to a custom one. Currently considered an experimental API.
sub set-template-repository(Cro::WebApp::Template::Repository $repository --> Nil) is export {
    $template-repo = $repository;
}

#| Load a template from the given C<IO>.
sub load-template(IO() $abs-path, :@locations --> Cro::WebApp::Template::Compiled) is export {
    Cro::WebApp::LogTimeline::CompileTemplate.log: :template($abs-path.relative), {
        my $*TEMPLATE-REPOSITORY = $template-repo;
        my Cro::WebApp::Template::Location @*TEMPLATE-LOCATIONS = @locations;
        my $*TEMPLATE-FILE = $abs-path;
        my $source = $abs-path.slurp;
        my $ast = Cro::WebApp::Template::Parser.parse($source, actions => Cro::WebApp::Template::ASTBuilder).ast;
        #iamerejh
        Cro::WebApp::Template::Compiled.new(|$ast.compile, repository => $template-repo, :path($abs-path))
    }
}

#| Parse a template from a source string. An optional path may be passed for
#| use in error reporting.
sub parse-template(Str $source, IO() :$path = 'anon'.IO, :@locations --> Cro::WebApp::Template::Compiled) is export {
    Cro::WebApp::LogTimeline::CompileTemplate.log: :template($path.relative), {
        my $*TEMPLATE-REPOSITORY = $template-repo;
        my Cro::WebApp::Template::Location @*TEMPLATE-LOCATIONS = @locations;
        my $*TEMPLATE-FILE = $path;
        my $ast = Cro::WebApp::Template::Parser.parse($source, actions => Cro::WebApp::Template::ASTBuilder).ast;
        Cro::WebApp::Template::Compiled.new(|$ast.compile, repository => $template-repo, :$path)
    }
}
