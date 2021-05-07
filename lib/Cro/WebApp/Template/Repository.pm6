use Cro::WebApp::LogTimelineSchema;
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
    has %.exports;
    has $.repository;

    method render($topic --> Str) {
        my $*TEMPLATE-REPOSITORY = $!repository;
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

    method refresh($abs-path) {
        %!abs-path-to-compiled{$abs-path}:delete;
        Nil
    }

    method resolve-prelude(--> Promise) {
        my $*COMPILING-PRELUDE = True;
        self.resolve-absolute(%?RESOURCES<prelude.crotmp>.IO);
    }

    method add-location(IO::Path $location --> Nil) {
        @!search-paths.push($location);
    }
}

monitor Cro::WebApp::Template::ReloadingRepository is Cro::WebApp::Template::Repository {
    has %!abs-path-to-mtime;

    method resolve-absolute($abs-path --> Promise) {
        my $modified = $abs-path.IO.modified;
        if (%!abs-path-to-mtime{$abs-path} // 0) != $modified {
            self.refresh($abs-path)
        }
        %!abs-path-to-mtime{$abs-path} = $modified;
        callsame
    }

}

my $template-repo = %*ENV<CRO_DEV> ?? Cro::WebApp::Template::ReloadingRepository.new !! Cro::WebApp::Template::Repository.new;
sub get-template-repository(--> Cro::WebApp::Template::Repository) is export {
    $template-repo
}

sub set-template-repository(Cro::WebApp::Template::Repository $repository --> Nil) is export {
    $template-repo = $repository;
}

sub load-template(IO() $abs-path --> Cro::WebApp::Template::Compiled) {
    Cro::WebApp::LogTimeline::CompileTemplate.log: :template($abs-path.relative), {
        my $*TEMPLATE-REPOSITORY = $template-repo;
        my $source = slurp($abs-path);
        my $*TEMPLATE-FILE = $abs-path;
        my $ast = Cro::WebApp::Template::Parser.parse($source, actions => Cro::WebApp::Template::ASTBuilder).ast;
        Cro::WebApp::Template::Compiled.new(|$ast.compile, repository => $template-repo)
    }
}
