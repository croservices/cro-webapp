grammar Cro::WebApp::Template::Parser {
    token TOP {
        <sequence-element>*
    }

    proto token sequence-element { * }

    token sequence-element:sym<topic> {
        '<.'
        $<deref>=<.ident>
        [ '>' || <.panic: 'malformed topic tag'> ]
    }

    token sequence-element:sym<literal-text> {
        <-[<]>+
    }

    token sequence-element:sym<literal-tag> {
        '<' <!tag-sigil> <-[>]>+ '>'
    }

    token tag-sigil {
        # Single characters we can always take as a tag sigil
        | <[.$@&:]>
        # The ? and ! for boolification must be followed by a . or $ tag sigil;
        # <!DOCTYPE> and <?xml> style things must be considered literal.
        | <[?!]> <[.$]>
    }
}
