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

is norm-ws(render-template($base.add('cond-expr-3.crotmp'), { a => 5, b => 6, c => 11 })),
        norm-ws(q:to/EXPECTED/), 'Conditional expressions with parens for grouping (1)';
    EXPECTED

is norm-ws(render-template($base.add('cond-expr-3.crotmp'), { a => 2, b => 6, c => 11 })),
        norm-ws(q:to/EXPECTED/), 'Conditional expressions with parens for grouping (2)';
    It's a match!
    EXPECTED

is norm-ws(render-template($base.add('cond-expr-4.crotmp'), { a => 3.5, b => 0.3e1 })),
        norm-ws(q:to/EXPECTED/), 'Conditional expressions with Rat/Num literals (1)';
    Foo
    EXPECTED

is norm-ws(render-template($base.add('cond-expr-4.crotmp'), { a => -3.5, b => 0.3e5 })),
        norm-ws(q:to/EXPECTED/), 'Conditional expressions with Rat/Num literals (2)';
    Bar
    Baz
    EXPECTED

is norm-ws(render-template($base.add('cond-expr-5.crotmp'), { x => {} })),
        norm-ws(q:to/EXPECTED/), 'Variables and derefs in conditions (1)';
    EXPECTED

is norm-ws(render-template($base.add('cond-expr-5.crotmp'), { x => { key => 0 } })),
        norm-ws(q:to/EXPECTED/), 'Variables and derefs in conditions (2)';
    Obj
    EXPECTED

is norm-ws(render-template($base.add('cond-expr-5.crotmp'), { x => { key => 2 } })),
        norm-ws(q:to/EXPECTED/), 'Variables and derefs in conditions (3)';
    Obj
    Key
    EXPECTED

is norm-ws(render-template($base.add('cond-expr-6.crotmp'), { foo => 'a' })),
        norm-ws(q:to/EXPECTED/), 'String comparison operators (1)';
    ltg
    leg
    neg
    EXPECTED

is norm-ws(render-template($base.add('cond-expr-6.crotmp'), { foo => 'z' })),
        norm-ws(q:to/EXPECTED/), 'String comparison operators (2)';
    gtg
    geg
    neg
    EXPECTED

is norm-ws(render-template($base.add('cond-expr-6.crotmp'), { foo => 'g' })),
        norm-ws(q:to/EXPECTED/), 'String comparison operators (3)';
    leg
    geg
    EXPECTED

is norm-ws(render-template($base.add('cond-var.crotmp'), {})),
        norm-ws(q:to/EXPECTED/), 'Conditionals used directly with variables work';
    Var 1 is true
    Var 0 is false
    EXPECTED

is norm-ws(render-template($base.add('cond-var-deref.crotmp'), { x => { :foo }, y => { :!foo } })),
        norm-ws(q:to/EXPECTED/), 'Conditionals that dereference variables work';
    foo
    not foo
    EXPECTED

is norm-ws(render-template($base.add('cond-var-deref.crotmp'), { x => { :foo }, y => { } })),
        norm-ws(q:to/EXPECTED/), 'Conditionals do not blow up over missing hash keys';
    foo
    not foo
    EXPECTED

is norm-ws(render-template($base.add('cond-if-else.crotmp'), { :foo })),
        norm-ws(q:to/EXPECTED/), 'if/else works correctly (true case)';
    foo
    EXPECTED

is norm-ws(render-template($base.add('cond-if-else.crotmp'), { :!foo })),
        norm-ws(q:to/EXPECTED/), 'if/else works correctly (true case)';
    not foo
    EXPECTED

is norm-ws(render-template($base.add('cond-if-elsif-else.crotmp'), { :x(10) })),
        norm-ws(q:to/EXPECTED/), 'if/elsif/else works correctly (if true)';
    over five
    EXPECTED

is norm-ws(render-template($base.add('cond-if-elsif-else.crotmp'), { :x(5) })),
        norm-ws(q:to/EXPECTED/), 'if/elsif/else works correctly (elsif true)';
    over zero
    EXPECTED

is norm-ws(render-template($base.add('cond-if-elsif-else.crotmp'), { :x(0) })),
        norm-ws(q:to/EXPECTED/), 'if/elsif/else works correctly (no branches true)';
    zero or less
    EXPECTED

is norm-ws(render-template($base.add('cond-if-elsif-else-tag.crotmp'), { :x(10) })),
        norm-ws(q:to/EXPECTED/), 'if/elsif/else works correctly (if true)';
    <div>over five</div>
    EXPECTED

is norm-ws(render-template($base.add('cond-if-elsif-else-tag.crotmp'), { :x(5) })),
        norm-ws(q:to/EXPECTED/), 'if/elsif/else works correctly (elsif true)';
    <p>over zero</p>
    EXPECTED

is norm-ws(render-template($base.add('cond-if-elsif-else-tag.crotmp'), { :x(0) })),
        norm-ws(q:to/EXPECTED/), 'if/elsif/else works correctly (no branches true)';
    <span>zero or less</span>
    EXPECTED

sub norm-ws($str) {
    $str.subst(:g, /\s+/, '')
}

done-testing;
