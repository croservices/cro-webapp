use Cro::WebApp::Template::Builtins;

unit module Cro::WebApp::Template::AST;

role Node {
    has Bool $.trim-trailing-horizontal-before = False;
    method compile() { ... }
}

my role ContainerNode does Node {
    has Node @.children;
}

my class Template does ContainerNode is export {
    method compile() {
        my $*IN-SUB = False;
        my $children-compiled = @!children.map(*.compile).join(", ");
        use MONKEY-SEE-NO-EVAL;
        sub trait_mod:<is>(Routine $r, :$TEMPLATE-EXPORT!) {
            %*TEMPLATE-EXPORTS{$r.name.substr('__TEMPLATE__'.chars)} = $r;
        }
        my %*TEMPLATE-EXPORTS;
        my $renderer = EVAL 'sub ($_) { join "", (' ~ $children-compiled ~ ') }';
        return { :$renderer, exports => %*TEMPLATE-EXPORTS };
    }
}

my class Literal does Node is export {
    has Str $.text is required;

    method compile() {
        'Q『' ~ $!text.subst('『', "\\『", :g) ~ '』'
    }
}

my class IntLiteral does Node is export {
    has Int $.value is required;

    method compile() {
        ~$!value
    }
}

my class RatLiteral does Node is export {
    has Rat $.value is required;

    method compile() {
        $!value.perl
    }
}

my class NumLiteral does Node is export {
    has Num $.value is required;

    method compile() {
        $!value.perl
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

my class LiteralMethodDeref does Node is export {
    has Node $.target is required;
    has Str $.symbol is required;

    method compile() {
        '(' ~ $!target.compile ~ ').' ~ $!symbol ~ '()'
    }
}

my class ArrayIndexDeref does Node is export {
    has Node $.target is required;
    has Node $.index is required;

    method compile() {
        '(' ~ $!target.compile ~ ')[' ~ $!index.compile ~ ']'
    }
}

my class HashKeyDeref does Node is export {
    has Node $.target is required;
    has Node $.key is required;

    method compile() {
        '(' ~ $!target.compile ~ '){' ~ $!key.compile ~ '}'
    }
}

my class Iteration does ContainerNode is export {
    has Node $.target is required;
    has $.iteration-variable;

    method compile() {
        $!iteration-variable //= '$_';
        my $children-compiled = @!children.map(*.compile).join(", ");
        '(' ~ $!target.compile ~ ').map(-> ' ~ $!iteration-variable  ~ ' { join "", (' ~ $children-compiled ~ ') }).join'
    }
}

my class Condition does ContainerNode is export {
    has Node $.condition is required;
    has Bool $.negated = False;

    method compile() {
        my $cond = '(' ~ $!condition.compile ~ ')';
        my $if-true = '(' ~ @!children.map(*.compile).join(", ") ~ ').join';
        $!negated
            ?? "$cond ?? '' !! $if-true"
            !! "$cond ?? $if-true !! ''"
    }
}

my class TemplateSub does ContainerNode is export {
    has Str $.name is required;
    has Str @.parameters;

    method compile() {
        my $should-export = !$*IN-SUB;
        {
            my $*IN-SUB = True;
            my $params = @!parameters.join(", ");
            my $trait = $should-export ?? 'is TEMPLATE-EXPORT' !! '';
            '(sub __TEMPLATE__' ~ $!name ~ "($params) $trait \{\n" ~
                'join "", (' ~ @!children.map(*.compile).join(", ") ~ ')' ~
            "} && '')\n"
        }
    }
}

my class Call does Node is export {
    has Str $.target is required;
    has Node @.arguments;

    method compile() {
        '__TEMPLATE__' ~ $!target ~ '(' ~ @!arguments.map(*.compile).join(", ") ~ ')'
    }
}

my class TemplateMacro does ContainerNode is export {
    has Str $.name is required;
    has Str @.parameters;

    method compile() {
        my $should-export = !$*IN-SUB;
        {
            my $*IN-SUB = True;
            my $params = ('&__MACRO_BODY__', |@!parameters).join(", ");
            my $trait = $should-export ?? 'is TEMPLATE-EXPORT' !! '';
            '(sub __TEMPLATE__' ~ $!name ~ "($params) $trait \{\n" ~
                    'join "", (' ~ @!children.map(*.compile).join(", ") ~ ')' ~
                    "} && '')\n"
        }
    }
}

my class MacroBody does ContainerNode is export {
    method compile() {
        '__MACRO_BODY__()'
    }
}

my class MacroApplication does ContainerNode is export {
    has Str $.target is required;
    has Node @.arguments;

    method compile() {
        my $args = @!arguments ?? ", " ~ @!arguments.map(*.compile).join(", ") !! '';
        '__TEMPLATE__' ~ $!target ~ '({ join "", (' ~ @!children.map(*.compile).join(", ") ~ ') }' ~ $args ~ ')'
    }
}

my class Sequence does ContainerNode is export {
    method compile() {
        '(join "", (' ~ @!children.map(*.compile).join(", ") ~ '))'
    }
}

my class Use does Node is export {
    has Str $.template-name is required;
    has @.exported-symbols;

    method compile() {
        my $decls = join ",", @!exported-symbols.map: -> $sym {
            '(my &__TEMPLATE__' ~ $sym ~ ' = .<' ~ $sym ~ '>)'
        }
        '(((' ~ $decls ~ ') given await($*TEMPLATE-REPOSITORY.resolve(\'' ~
                $!template-name ~ '\')).exports) && "")'
    }
}

my class Expression does Node is export {
    has Node @.terms;
    has Str @.infixes;

    method compile() {
        my @terms = @!terms;
        my @infixes = @!infixes;
        my $compiled = '(' ~ @terms.shift.compile();
        while @infixes {
            $compiled ~= ' ' ~ @infixes.shift() ~ ' ' ~ @terms.shift.compile();
        }
        return $compiled ~ ')';
    }
}

my class EscapeText does Node is export {
    has Node $.target;

    method compile() {
        'escape-text(' ~ $!target.compile() ~ ')'
    }
}

my class EscapeAttribute does Node is export {
    has Node $.target;

    method compile() {
        'escape-attribute(' ~ $!target.compile() ~ ')'
    }
}

my constant %escapes = %(
    '&' => '&amp;',
    '<' => '&lt;',
    '>' => '&gt;',
    '"' => '&quot;',
    "'" => '&apos;',
);

sub escape-text(Str() $text) {
    $text.subst(/<[<>&]>/, { %escapes{.Str} }, :g)
}

sub escape-attribute(Str() $attr) {
    $attr.subst(/<[&"']>/, { %escapes{.Str} }, :g)
}
