use Cro::WebApp::Template;
use Test;

my constant $base = $*PROGRAM.parent.add('test-data');

is norm-ws(render-template($base.add('cond-expr-1.crotmp'), { foo => 42, bar => 'golden anchor' })),
        norm-ws(q:to/EXPECTED/), 'Conditional expressions on topic with simple infix (1)';
    The answer!
    Small
    Beer!
    EXPECTED

is norm-ws(render-template($base.add('cond-expr-1.crotmp'), { foo => 142, bar => 'golden wheel' })),
        norm-ws(q:to/EXPECTED/), 'Conditional expressions on topic with simple infix (2)';
    Big
    EXPECTED

is norm-ws(render-template($base.add('cond-expr-2.crotmp'), { a => 2, b => 2 })),
        norm-ws(q:to/EXPECTED/), 'Conditional expressions on variable with multiple infixes (1)';
    Both two!
    EXPECTED

is norm-ws(render-template($base.add('cond-expr-2.crotmp'), { a => 2, b => 3 })),
        norm-ws(q:to/EXPECTED/), 'Conditional expressions on variable with multiple infixes (2)';
    At least one three
    EXPECTED

is norm-ws(render-template($base.add('cond-expr-2.crotmp'), { a => 3, b => 1 })),
        norm-ws(q:to/EXPECTED/), 'Conditional expressions on variable with multiple infixes (3)';
    At least one three
    EXPECTED

is norm-ws(render-template($base.add('cond-expr-2.crotmp'), { a => 1, b => 1 })),
        norm-ws(q:to/EXPECTED/), 'Conditional expressions on variable with multiple infixes (4)';
    EXPECTED

sub norm-ws($str) {
    $str.subst(:g, /\s+/, '')
}

done-testing;
