use Cro::WebApp::Template::ASTBuilder;
use Cro::WebApp::Template::Parser;
use OO::Monitors;

class X::Cro::WebApp::Template::NotFound is Exception {
    has Str $.template-name;
    method message() {
        "Could not locate template '$!template-name'"
    }
}

class Cro::WebApp::Template::Compiled {
    has &.renderer;

    method render($topic --> Str) {
        &!renderer($topic)
    }
}

monitor Cro::WebApp::Template::Repository {
    has Promise %!abs-path-to-compiled;
    has @!search-paths = '.'.IO;

    method resolve(Str $template-name) {
        for @!search-paths {
            my $path = .add($template-name);
            return self.resolve-absolute($path) if $path.f;
        }
        die X::Cro::WebApp::Template::NotFound.new(:$template-name);
    }

    method resolve-absolute($abs-path --> Promise) {
        with %!abs-path-to-compiled{$abs-path} {
            $_
        }
                else {
            %!abs-path-to-compiled{$abs-path} = start load-template($abs-path);
        }
    }

    method add-location(IO::Path $location --> Nil) {
        @!search-paths.push($location);
    }
}

my $template-repo = Cro::WebApp::Template::Repository.new;
sub get-template-repository() is export {
    $template-repo
}

sub load-template($abs-path) {
    my $source = slurp($abs-path);
    my $ast = Cro::WebApp::Template::Parser.parse($source, actions => Cro::WebApp::Template::ASTBuilder).ast;
    Cro::WebApp::Template::Compiled.new(renderer => $ast.compile)
}
