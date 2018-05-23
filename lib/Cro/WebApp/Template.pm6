use Cro::WebApp::Template::Parser;
use Cro::WebApp::Template::ASTBuilder;
use OO::Monitors;

class X::Cro::WebApp::Template::NotFound is Exception {
    has Str $.template-name;
    method message() {
        "Could not locate template '$!template-name'"
    }
}

my monitor TemplateRepository {
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
my $template-repo = TemplateRepository.new;

multi render-template(IO::Path $template-path, $initial-topic) is export {
    my $renderer = await $template-repo.resolve-absolute($template-path.absolute);
    $renderer($initial-topic)
}

multi render-template(Str $template, $initial-topic) is export {
    my $renderer = await $template-repo.resolve($template);
    $renderer($initial-topic)
}

sub template-location(IO() $location --> Nil) is export {
    $template-repo.add-location($location);
}

sub load-template($abs-path) {
    my $source = slurp($abs-path);
    my $ast = Cro::WebApp::Template::Parser.parse($source, actions => Cro::WebApp::Template::ASTBuilder).ast;
    $ast.compile
}
