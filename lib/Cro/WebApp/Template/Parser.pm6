use Cro::WebApp::Template::Error;

class X::Cro::WebApp::Template::SyntaxError does X::Cro::WebApp::Template {
    has Str $.reason is required;
    has Cursor $.cursor is required;

    method message() {
        "Template parse failed: $!reason at line $.line near '$.near'"
    }

    method line() {
        $!cursor.orig.substr(0, $!cursor.pos).split(/\n/).elems
    }

    method near() {
        $!cursor.orig.substr($!cursor.pos, 40)
    }
}

grammar Cro::WebApp::Template::Parser {
    token TOP {
        :my $*IN-ATTRIBUTE = False;
        :my $*IN-MACRO = False;
        <sequence-element>*
        [ $ || <.panic: 'confused'> ]
    }

    proto token sequence-element { * }

    token sequence-element:sym<sigil-tag> {
        <sigil-tag>
    }

    token sequence-element:sym<literal-text> {
        <-[<]>+
    }

    token sequence-element:sym<literal-open-tag> {
        :my $*IN-ATTRIBUTE = True;
        '<' <![/]> <!sigil>
        <tag-element>+
        [ '>' || <.panic: "malformed tag"> ]
    }

    token sequence-element:sym<literal-close-tag> {
        '</' <!sigil>
        <-[>]>+
        [ '>' || <.panic: "malformed closing tag"> ]
    }

    proto token tag-element { * }

    token tag-element:sym<sigil-tag> {
        <sigil-tag>
    }

    token tag-element:sym<literal> {
        | '!--' .*? '--' <?before '>'>
        | <-[<>]>+
    }

    proto token sigil-tag { * }

    token sigil-tag:sym<topic> {
        '<.'
        [ <deref> || <.malformed: 'topic tag'> ]
        [ '>' || <.malformed: 'topic tag'> ]
    }

    token sigil-tag:sym<variable> {
        '<$'
        [ <identifier> || <.malformed: 'variable tag'> ]
        [ '.' <deref> ]?
        [ '>' || <.malformed: 'variable tag'> ]
    }

    token sigil-tag:sym<iteration> {
        :my $opener = $¢.clone;
        :my $*lone-start-line = False;
        '<@'
        [ <?after [^ | $ | \n] \h* '<@'> { $*lone-start-line = True } ]?
        [
        | '.'? <deref>
        | $<variable>=['$' <.identifier>] ['.' <deref>]?
        || <.malformed: 'iteration tag'>
        ]
        \h*
        [
        ||  [':' \h* <iteration-variable=.parameter(:!allow-named, :!allow-default)>]? \h* '>'
        || <.malformed('iteration tag')>
        ]
        [ <?{ $*lone-start-line }> [ \h* \n | { $*lone-start-line = False } ] ]?

        <sequence-element>*

        :my $*lone-end-line = False;
        [ '</@' || { $opener.unclosed('iteration tag') } ]
        [ <?after \n \h* '</@'> { $*lone-end-line = True } ]?
        <close-ident=.ident>?
        [ \h* '>' || <.malformed: 'iteration closing tag'> ]
        [ <?{ $*lone-end-line }> [ \h* \n | { $*lone-end-line = False } ] ]?
    }

    token sigil-tag:sym<condition> {
        <!before '<!-'>
        :my $opener = $¢.clone;
        :my $*lone-start-line = False;
        '<' $<negate>=<[?!]>
        [ <?after [^ | $ | \n] \h* '<' <[?!]>> { $*lone-start-line = True } ]?
        [
        | '.' <deref>
        | '$' <identifier> ['.' <deref>]?
        | '{' <expression> [ '}' || <.panic('malformed expression')> ]
        || <.malformed: 'condition tag'>
        ]
        [ \h* '>' || <.malformed: 'condition tag'> ]
        [ <?{ $*lone-start-line }> [ \h* \n | { $*lone-start-line = False } ] ]?

        <sequence-element>*

        :my $*lone-end-line = False;
        [ '</' $<negate> || { $opener.unclosed('condition tag') } ]
        [ <?after \n \h* '</' <[?!]>> { $*lone-end-line = True } ]?
        <close-ident=.ident>?
        [ \h* '>' || <.malformed: 'condition closing tag'> ]
        [ <?{ $*lone-end-line }> [ \h* \n | { $*lone-end-line = False } ] ]?
    }

    token sigil-tag:sym<call> {
        '<&'
        [
        || <target=.identifier> \h* <arglist>? \h*
        || <.malformed: 'call tag'>
        ]
        [ '>' || <.malformed: 'call tag'> ]
    }

    token sigil-tag:sym<sub> {
        :my $opener = $¢.clone;
        :my $*lone-start-line = False;
        '<:sub'
        [ <?after [^ | $ | \n] \h* '<:sub'> { $*lone-start-line = True } ]?
        \h+
        [
        || <name=.identifier> \h* <signature>? '>'
        || <.malformed: 'sub declaration tag'>
        ]
        [ <?{ $*lone-start-line }> [ \h* \n | { $*lone-start-line = False } ] ]?

        <sequence-element>*

        :my $*lone-end-line = False;
        [ '</:' || { $opener.unclosed('sub declaration tag') } ]
        [ <?after \n \h* '</:'> { $*lone-end-line = True } ]?
        [ 'sub'? \h* '>' || <.malformed: 'sub declaration closing tag'> ]
        [ <?{ $*lone-end-line }> [ \h* \n | { $*lone-end-line = False } ] ]?
    }

    token sigil-tag:sym<macro> {
        :my $opener = $¢.clone;
        :my $*lone-start-line = False;
        '<:macro'
        [ <?after [^ | $ | \n] \h* '<:macro'> { $*lone-start-line = True } ]?
        \h+
        [
        || <name=.identifier> \h* <signature>? '>'
        || <.maformed: 'macro declaration tag'>
        ]
        [ <?{ $*lone-start-line }> [ \h* \n | { $*lone-start-line = False } ] ]?

        :my $*IN-MACRO = True;
        <sequence-element>*

        :my $*lone-end-line = False;
        [ '</:' || { $opener.unclosed('macro declaration tag') } ]
        [ <?after \n \h* '</:'> { $*lone-end-line = True } ]?
        [ 'macro'? \h* '>' || <.malformed: 'macro declaration closing tag'> ]
        [ <?{ $*lone-end-line }> [ \h* \n | { $*lone-end-line = False } ] ]?
    }

    token sigil-tag:sym<body> {
        [{ $*IN-MACRO } || <.panic('Use of <:body> outside of a macro')>]
        '<:body' \h* '>'
    }

    token sigil-tag:sym<part> {
        :my $opener = $¢.clone;
        :my $*lone-start-line = False;
        '<:part'
        [ <?after [^ | $ | \n] \h* '<:part'> { $*lone-start-line = True } ]?
        \h+
        [
        || <name=.identifier> \h* <signature>? '>'
        || <.malformed: 'part declaration tag'>
        ]
        [ <?{ $*lone-start-line }> [ \h* \n | { $*lone-start-line = False } ] ]?

        <sequence-element>*

        :my $*lone-end-line = False;
        [ '</:' || { $opener.unclosed('part declaration tag') } ]
        [ <?after \n \h* '</:'> { $*lone-end-line = True } ]?
        [ 'part'? \h* '>' || <.malformed: 'part declaration closing tag'> ]
        [ <?{ $*lone-end-line }> [ \h* \n | { $*lone-end-line = False } ] ]?
    }

    token sigil-tag:sym<apply> {
        :my $*lone-start-line = False;
        '<|'
        [ <?after [^ | $ | \n] \h* '<|'> { $*lone-start-line = True } ]?
        [
        || <target=.identifier> \h* <arglist>? \h* '>'
        || <.malformed: 'macro application tag'>
        ]
        [ <?{ $*lone-start-line }> [ \h* \n | { $*lone-start-line = False } ] ]?

        <sequence-element>*

        :my $*lone-end-line = False;
        '</|'
        [ <?after \n \h* '</|'> { $*lone-end-line = True } ]?
        <close-ident=.ident>?
        [ \h* '>' || <.malformed: 'macro application closing tag'> ]
        [ <?{ $*lone-end-line }> [ \h* \n | { $*lone-end-line = False } ] ]?
    }

    token sigil-tag:sym<use> {
        '<:use' \h+
        [
        | <file=.single-quote-string>
        | <library=.module-name>
        || <.malformed: 'use tag'>
        ]
        \h* '>'
    }

    token module-name {
        <.identifier>+ % '::'
    }

    token signature {
        :my $*seen-by-name-arguments = False;
        '(' \s* <parameter>* % [\s* ',' \s*] \s*
        [ ')' || <.malformed: 'signature'> ] \h*
    }

    token parameter(:$allow-named = True, :$allow-default = True) {
        [
        || $<named>=':'
           [ <?{ $allow-named }> || <.panic('Canot use a named parameter here')> ]
           { $*seen-by-name-arguments = True; }
        || <?{ $*seen-by-name-arguments }> <.panic('Positional argument after named argument')>
        ]?
        $<name>=['$' <.identifier>]
        [ <?{ $allow-default }> \s* '=' \s* <default=.expression> ]?
    }

    token arglist {
        '(' \s* <arg>* % [\s* ',' \s*] \s* ')' \h*
    }

    proto token arg { * }

    token arg:by-pos { <expression> }

    token arg:by-name {
        :my $negated = False;
        ':'
        [
        | $<var-name>=['$' <identifier>]
        | [ $<negated>='!' { $negated = True} ]?
          <identifier>
          [
          '(' ~ ')' <expression>
          [ <!{$negated}> || <.panic('Negated named argument may not have a value')> ]
          ]?
        ]


    }

    rule expression {
        <!before ')'>
        [ <term> || <.panic('unrecognized term')> ]
        [ <infix> [ <term> || <.panic('missing or unrecognized term')> ] ]*
    }

    proto token term { * }

    token term:sym<single-quote-string> {
        <single-quote-string>
    }

    token term:sym<integer> {
        '-'? \d+
    }

    token term:sym<rational> {
        '-'? \d* '.' \d+
    }

    token term:sym<num> {
        '-'? \d* '.' \d+ <[eE]> '-'? \d+
    }

    token term:sym<bool> {
        True | False
    }

    token term:sym<variable> {
        $<name>=[ '$' <.identifier> ] [ '.' <deref> ]?
    }

    token term:sym<deref> {
        '.' <deref>
    }

    rule term:sym<parens> { '(' <expression> ')' }

    proto token infix { * }
    token infix:sym<==> { <sym> }
    token infix:sym<!=> { <sym> }
    token infix:sym<< < >> { <sym> }
    token infix:sym<< <= >> { <sym> }
    token infix:sym<< > >> { <sym> }
    token infix:sym<< >= >> { <sym> }
    token infix:sym<eq> { <sym> }
    token infix:sym<ne> { <sym> }
    token infix:sym<lt> { <sym> }
    token infix:sym<gt> { <sym> }
    token infix:sym<le> { <sym> }
    token infix:sym<ge> { <sym> }
    token infix:sym<===> { <sym> }
    token infix:sym<!===> { <sym> }
    token infix:sym<&&> { <sym> }
    token infix:sym<||> { <sym> }
    token infix:sym<and> { <sym> }
    token infix:sym<or> { <sym> }
    token infix:sym<+> { <sym> }
    token infix:sym<-> { <sym> }
    token infix:sym<*> { <sym> }
    token infix:sym</> { <sym> }
    token infix:sym<%> { <sym> }
    token infix:sym<~> { <sym> }
    token infix:sym<x> { <sym> }

    token deref {
        <deref-item>+ % '.'
    }

    proto token deref-item { * }
    token deref-item:sym<method> {
        <identifier> <arglist>
    }
    token deref-item:sym<smart> {
        <.identifier>
    }
    token deref-item:sym<hash-literal> {
        '<' <( <-[>]>* )> '>'
    }
    token deref-item:sym<array> {
        '[' <index=.expression> ']'
    }
    token deref-item:sym<hash> {
        '{' <key=.expression> '}'
    }

    token single-quote-string {
        "'" <( <-[']>* )> "'"
    }

    token sigil {
        # Single characters we can always take as a tag sigil
        | <[.$@&:|]>
        # The ? and ! for boolification must be followed by a . or $ tag sigil or
        # { expression. <!DOCTYPE>, <?xml>, and <!--comment--> style things
        # must be considered literal.
        | <[?!]> <[.$>{]>
    }

    token identifier {
        <.ident> [ <[-']> <.ident> ]*
    }

    method malformed($what) {
        self.panic("malformed $what")
    }

    method unclosed($what) {
        self.panic("unclosed $what")
    }

    method panic($reason) {
        die X::Cro::WebApp::Template::SyntaxError.new:
                :$reason, :cursor(self), :file($*TEMPLATE-FILE // '<unknown>'.IO);
    }
}
