use Cro::WebApp::Template::Parser;
use Cro::WebApp::Template::ASTBuilder;
use OO::Monitors;

my monitor TemplateRepository {
    has Promise %!abs-path-to-compiled;

    method resolve-absolute($abs-path --> Promise) {
        with %!abs-path-to-compiled{$abs-path} {
            $_
        }
        else {
            %!abs-path-to-compiled{$abs-path} = start load-template($abs-path);
        }
    }
}
my $template-repo = TemplateRepository.new;

multi render-template(IO::Path $template-path, $initial-topic) is export {
    my $renderer = await $template-repo.resolve-absolute($template-path.absolute);
    $renderer($initial-topic)
}

multi render-template(Str $template, $initial-topic) is export {
    die "Template path resolution NYI";
}

sub load-template($abs-path) {
    my $source = slurp($abs-path);
    my $ast = Cro::WebApp::Template::Parser.parse($source, actions => Cro::WebApp::Template::ASTBuilder).ast;
    $ast.compile
}
