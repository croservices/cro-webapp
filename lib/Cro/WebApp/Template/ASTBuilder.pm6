use Cro::WebApp::Template::AST;

class Cro::WebApp::Template::ASTBuilder {
    method TOP($/) {
        make Template.new(children => flatten-literals($<sequence-element>.map(*.ast)));
    }

    method sequence-element:sym<sigil-tag>($/) {
        make $<sigil-tag>.ast;
    }

    method sequence-element:sym<literal-text>($/) {
        make Literal.new(text => ~$/);
    }

    method sequence-element:sym<literal-open-tag>($/) {
        my @elements = flatten-literals flat
            Literal.new(text => '<'),
            $<tag-element>.map(*.ast),
            Literal.new(text => '>');
        make @elements == 1 ?? @elements[0] !! Sequence.new(children => @elements);
    }

    method sequence-element:sym<literal-close-tag>($/) {
        make Literal.new(text => ~$/);
    }

    method tag-element:sym<sigil-tag>($/) {
        make $<sigil-tag>.ast;
    }

    method tag-element:sym<literal>($/) {
        make Literal.new(text => ~$/);
    }

    method sigil-tag:sym<topic>($/) {
        my $derefer = $<deref>.ast;
        make escape($derefer(VariableAccess.new(name => '$_')));
    }

    method sigil-tag:sym<iteration>($/) {
        my $derefer = $<deref>.ast;
        make Iteration.new:
            target => $derefer(VariableAccess.new(name => '$_')),
            children => flatten-literals($<sequence-element>.map(*.ast),
                :trim-trailing-horizontal($*lone-end-line)),
            trim-trailing-horizontal-before => $*lone-start-line;
    }

    method sigil-tag:sym<condition>($/) {
        my $derefer = $<deref>.ast;
        make Condition.new:
            negated => $<negate> eq '!',
            condition => $derefer(VariableAccess.new(name => '$_')),
            children => flatten-literals($<sequence-element>.map(*.ast),
                :trim-trailing-horizontal($*lone-end-line)),
            trim-trailing-horizontal-before => $*lone-start-line;
    }

    method sigil-tag:sym<sub>($/) {
        make TemplateSub.new:
            name => ~$<name>,
            children => flatten-literals($<sequence-element>.map(*.ast),
                :trim-trailing-horizontal($*lone-end-line)),
            trim-trailing-horizontal-before => $*lone-start-line;
    }

    method sigil-tag:sym<call>($/) {
        make Call.new: target => ~$<target>;
    }

    method sigil-tag:sym<use>($/) {
        my $template-name = $<name>.ast;
        my $used = await $*TEMPLATE-REPOSITORY.resolve($template-name);
        make Use.new: :$template-name, exported-symbols => $used.exports.keys;
    }

    method deref($/) {
        make -> $target {
            SmartDeref.new: :$target, symbol => ~$<deref>
        };
    }

    method single-quote-string($/) {
        make ~$/;
    }

    sub flatten-literals(@children, :$trim-trailing-horizontal) {
        my @squashed;
        my $last-lit = '';
        for @children {
            when Literal {
                $last-lit ~= .text;
            }
            default {
                if $last-lit {
                    push @squashed, Literal.new:
                        text => .trim-trailing-horizontal-before
                            ?? $last-lit.subst(/\h+$/, '')
                            !! $last-lit;
                    $last-lit = '';
                }
                push @squashed, $_;
            }
        }
        if $last-lit {
            push @squashed, Literal.new:
                text => $trim-trailing-horizontal
                    ?? $last-lit.subst(/\h+$/, '')
                    !! $last-lit;
        }
        return @squashed;
    }

    sub escape($target) {
        $*IN-ATTRIBUTE
            ?? EscapeAttribute.new(:$target)
            !! EscapeText.new(:$target)
    }
}
