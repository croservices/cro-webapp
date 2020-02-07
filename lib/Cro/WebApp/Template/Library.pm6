use Cro::WebApp::Template::Parser;
use Cro::WebApp::Template::ASTBuilder;
use Cro::WebApp::Template::Repository;

#| Compile all of the templates, and flatten their exports out into a single,
#| flat, view.
sub template-library(*@resources) is export {
    my %exports;
    my $*TEMPLATE-REPOSITORY = get-template-repository;
    for @resources {
        my $source = .slurp;
        my $*TEMPLATE-FILE = .IO;
        my $ast = Cro::WebApp::Template::Parser.parse($source, actions => Cro::WebApp::Template::ASTBuilder).ast;
        my %template-exports := $ast.compile()<exports>;
        for %template-exports<sub>.kv -> $sym, $sub {
            my $mangled = "&__TEMPLATE_SUB__$sym";
            if %exports{$mangled}:exists {
                die "Duplicate export of sub '$sym' in $*TEMPLATE-FILE";
            }
            %exports{$mangled} := $sub;
        }
        for %template-exports<macro>.kv -> $sym, $sub {
            my $mangled = "&__TEMPLATE_MACRO__$sym";
            if %exports{$mangled}:exists {
                die "Duplicate export of macro '$sym' in $*TEMPLATE-FILE";
            }
            %exports{$mangled} := $sub;
        }
    }
    return %exports;
}
