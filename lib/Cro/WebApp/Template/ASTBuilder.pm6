use Cro::WebApp::Template::AST;

class Cro::WebApp::Template::ASTBuilder {
    method TOP($/) {
        make Template.new(children => flatten-literals($<sequence-element>.map(*.ast)));
    }

    method sequence-element:sym<topic>($/) {
        make SmartDeref.new:
            target => VariableAccess.new(name => '$_'),
            symbol => ~$<deref>;
    }

    method sequence-element:sym<literal-text>($/) {
        make Literal.new(text => ~$/);
    }

    method sequence-element:sym<literal-tag>($/) {
        make Literal.new(text => ~$/);
    }

    sub flatten-literals(@children) {
        my @squashed;
        my $last-lit = '';
        for @children {
            when Literal {
                $last-lit ~= .text;
            }
            default {
                if $last-lit {
                    push @squashed, Literal.new(text => $last-lit);
                    $last-lit = '';
                }
                push @squashed, $_;
            }
        }
        if $last-lit {
            push @squashed, Literal.new(text => $last-lit);
        }
        return @squashed;
    }
}
