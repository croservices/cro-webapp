use Cro::WebApp::Template::Parser;
use Cro::WebApp::Template::ASTBuilder;

#| Compile all of the templates, and flatten their exports out into a single,
#| flat, view.
sub template-library(*@resources) is export {
    my %exports;
    for @resources {
        my $source = .slurp;
        my $*TEMPLATE-FILE = .relative;
        my $ast = Cro::WebApp::Template::Parser.parse($source, actions => Cro::WebApp::Template::ASTBuilder).ast;
        my %template-exports := $ast.compile()<exports>;
        for %template-exports.kv -> $sym, $sub {
            my $mangled = "&__TEMPLATE__$sym";
            if %exports{$mangled}:exists {
                die "Duplicate export of symbol '$sym' in $*TEMPLATE-FILE";
            }
            %exports{$mangled} := $sub;
        }
    }
    return %exports;
}
