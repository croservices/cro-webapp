unit module Cro::WebApp::Template::AST;

role Node {
    method compile() { ... }
}

my role ContainerNode does Node {
    has Node @.children;
}

my class Template does ContainerNode is export {
    method compile() {
        my $children-compiled = @!children.map(*.compile).join(", ");
        use MONKEY-SEE-NO-EVAL;
        EVAL 'sub ($_) { join "", (' ~ $children-compiled ~ ') }';
    }
}

my class Literal does Node is export {
    has Str $.text is required;

    method compile() {
        'Q『' ~ $!text.subst('『', "\\『", :g) ~ '』'
    }
}

my class VariableAccess does Node is export {
    has Str $.name is required;

    method compile() {
        $!name
    }
}

my class SmartDeref does Node is export {
    has Node $.target is required;
    has Str $.symbol is required;

    method compile() {
        '(given (' ~ $!target.compile ~
            ') { .does(Associative) && (.<' ~ $!symbol ~ '>:exists) ?? .<' ~
            $!symbol ~ '> !! .' ~ $!symbol ~ ' })'
    }
}
