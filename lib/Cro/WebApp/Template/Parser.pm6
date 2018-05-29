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
        <-[<>]>+
    }

    proto token sigil-tag { * }

    token sigil-tag:sym<topic> {
        '<.'
        <deref>
        [ '>' || <.panic: 'malformed topic tag'> ]
    }

    token sigil-tag:sym<variable> {
        '<$'
        <identifier>
        [ ['.' <attribute=.identifier>]? '>' || <.panic: 'malformed variable tag'> ]
    }

    token sigil-tag:sym<iteration> {
        :my $*lone-start-line = False;
        '<@'
        [ <?after [^ | $ | \n] \h* '<@'> { $*lone-start-line = True } ]?
        [
        | <deref>
        ]
        [ \h* [':' \h* <iteration-variable=.parameter>]? '>' || <.panic('malformed iteration tag')> ]
        [ <?{ $*lone-start-line }> [ \h* \n | { $*lone-start-line = False } ] ]?

        <sequence-element>*

        :my $*lone-end-line = False;
        '</@'
        [ <?after \n \h* '</@'> { $*lone-end-line = True } ]?
        <close-ident=.ident>?
        [ \h* '>' || <.panic('malformed iteration closing tag')> ]
        [ <?{ $*lone-end-line }> [ \h* \n | { $*lone-end-line = False } ] ]?
    }

    token sigil-tag:sym<condition> {
        :my $*lone-start-line = False;
        '<' $<negate>=<[?!]>
        [ <?after [^ | $ | \n] \h* '<' <[?!]>> { $*lone-start-line = True } ]?
        [
        | '.' <deref>
        | '{' <expression> '}'
        ]
        [ \h* '>' || <.panic('malformed condition tag')> ]
        [ <?{ $*lone-start-line }> [ \h* \n | { $*lone-start-line = False } ] ]?

        <sequence-element>*

        :my $*lone-end-line = False;
        '</' $<negate>
        [ <?after \n \h* '</' <[?!]>> { $*lone-end-line = True } ]?
        <close-ident=.ident>?
        [ \h* '>' || <.panic('malformed conditional closing tag')> ]
        [ <?{ $*lone-end-line }> [ \h* \n | { $*lone-end-line = False } ] ]?
    }

    token sigil-tag:sym<call> {
        '<&'
        <target=.identifier> \h* <arglist>? \h*
        [ '>' || <.panic: 'malformed call tag'> ]
    }

    token sigil-tag:sym<sub> {
        :my $*lone-start-line = False;
        '<:sub'
        [ <?after [^ | $ | \n] \h* '<:sub'> { $*lone-start-line = True } ]?
        \h+
        [
        || <name=.identifier> \h* <signature>? '>'
        || <.panic('malformed sub declaration tag')>
        ]
        [ <?{ $*lone-start-line }> [ \h* \n | { $*lone-start-line = False } ] ]?

        <sequence-element>*

        :my $*lone-end-line = False;
        '</:'
        [ <?after \n \h* '</:'> { $*lone-end-line = True } ]?
        [ 'sub'? \h* '>' || <.panic('malformed sub declaration closing tag')> ]
        [ <?{ $*lone-end-line }> [ \h* \n | { $*lone-end-line = False } ] ]?
    }

    token sigil-tag:sym<macro> {
        :my $*lone-start-line = False;
        '<:macro'
        [ <?after [^ | $ | \n] \h* '<:macro'> { $*lone-start-line = True } ]?
        \h+
        [
        || <name=.identifier> \h* <signature>? '>'
        || <.panic('malformed macro declaration tag')>
        ]
        [ <?{ $*lone-start-line }> [ \h* \n | { $*lone-start-line = False } ] ]?

        :my $*IN-MACRO = True;
        <sequence-element>*

        :my $*lone-end-line = False;
        '</:'
        [ <?after \n \h* '</:'> { $*lone-end-line = True } ]?
        [ 'macro'? \h* '>' || <.panic('malformed macro declaration closing tag')> ]
        [ <?{ $*lone-end-line }> [ \h* \n | { $*lone-end-line = False } ] ]?
    }

    token sigil-tag:sym<body> {
        [{ $*IN-MACRO } || <.panic('Use of <:body> outside of a macro')>]
        '<:body' \h* '>'
    }

    token sigil-tag:sym<apply> {
        :my $*lone-start-line = False;
        '<|'
        [ <?after [^ | $ | \n] \h* '<|'> { $*lone-start-line = True } ]?
        <target=.identifier>
        [ \h* <arglist>? \h* '>' || <.panic('malformed macro application tag')> ]
        [ <?{ $*lone-start-line }> [ \h* \n | { $*lone-start-line = False } ] ]?

        <sequence-element>*

        :my $*lone-end-line = False;
        '</|'
        [ <?after \n \h* '</|'> { $*lone-end-line = True } ]?
        <close-ident=.ident>?
        [ \h* '>' || <.panic('malformed macro application closing tag')> ]
        [ <?{ $*lone-end-line }> [ \h* \n | { $*lone-end-line = False } ] ]?
    }

    token sigil-tag:sym<use> {
        '<:use' \h+ <name=.single-quote-string> \h* '>'
    }

    token signature {
        '(' \s* <parameter>* % [\s* ',' \s*] \s* ')' \h*
    }

    token parameter {
        '$' <.identifier>
    }

    token arglist {
        '(' \s* <argument>* % [\s* ',' \s*] \s* ')' \h*
    }

    proto token argument { * }

    token argument:sym<single-quote-string> {
        <single-quote-string>
    }

    token argument:sym<integer> {
        \d+
    }

    token argument:sym<variable> {
        '$' <.identifier>
    }

    token argument:sym<deref> {
        '.' <deref>
    }

    rule expression {
        <?>
        [ <term> || <.panic('unrecognized term')> ]
        [ <infix> [ <term> || <.panic('missing or unrecognized term')> ] ]*
    }

    proto token term { * }
    token term:sym<argument> { <argument> }

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
        $<deref>=<.identifier>
    }

    token single-quote-string {
        "'" <( <-[']>* )> "'"
    }

    token sigil {
        # Single characters we can always take as a tag sigil
        | <[.$@&:|]>
        # The ? and ! for boolification must be followed by a . or $ tag sigil or
        # { expression. <!DOCTYPE> and <?xml> style things must be considered literal.
        | <[?!]> <[.$>{]>
    }

    token identifier {
        <.ident> [ <[-']> <.ident> ]*
    }

    method panic($reason) {
        die "Template parse failed: $reason near '" ~ self.orig.substr(self.pos, 40) ~ "'";
    }
}
