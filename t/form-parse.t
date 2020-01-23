use Cro::HTTP::Body;
use Cro::WebApp::Form;
use Test;

{
    my class TestForm does Cro::WebApp::Form {
        has Str $.email is required;
        has Str $.password is required is password;
        has Bool $.remember-me;
    }

    subtest 'Basic text fields and unticked check box' => {
        my $body = Cro::HTTP::Body::WWWFormUrlEncoded.new: :pairs[
            email => 'foo@bar.com',
            password => 'correcthorsebatterystaple',
        ];
        given TestForm.parse($body) {
            is-deeply .email, 'foo@bar.com', 'Correct text input value when provided';
            is-deeply .password, 'correcthorsebatterystaple', 'Correct password input value when provided';
            is-deeply .remember-me, False, 'Correct boolean value when nothing provided';
        }
    }

    subtest 'Missing text field and ticked check box' => {
        my $body = Cro::HTTP::Body::WWWFormUrlEncoded.new: :pairs[
            remember-me => 'filled',
        ];
        given TestForm.parse($body) {
            is-deeply .email, '', 'Correct text input value when not provided';
            is-deeply .password, '', 'Correct password input value when not provided';
            is-deeply .remember-me, True, 'Correct boolean value when box was ticked';
        }
    }
}

{
    my class BlogPost does Cro::WebApp::Form {
        has Str $.title is required;
        has Str $.content is multiline(:15rows, :80cols);
        has Str $.category will select { 'Coding', 'Photography', 'Trains' };
        has Str @.tags will select { 'Raku', 'Compiler', 'Landscape', 'City', 'Steam' }
    }

    subtest 'Select and multi-select with many values' => {
        my $body = Cro::HTTP::Body::WWWFormUrlEncoded.new: :pairs[
            title => 'Hello world',
            content => 'say "Hello, world"',
            category => 'Coding',
            tags => 'Raku',
            tags => 'Compiler'
        ];
        given BlogPost.parse($body) {
            is-deeply .title, 'Hello world', 'Correct text input value when provided';
            is-deeply .content, 'say "Hello, world"', 'Correct textarea input value when provided';
            is-deeply .category, 'Coding', 'Correct select value when provided';
            is-deeply .tags, Array[Str].new("Raku", "Compiler"), 'Correct multiple select value when many items';
        }
    }

    {
        my $body = Cro::HTTP::Body::WWWFormUrlEncoded.new: :pairs[
            title => 'Hello world',
            content => 'say "Hello, world"',
            category => 'Coding',
            tags => 'Raku',
        ];
        given BlogPost.parse($body) {
            is-deeply .tags, Array[Str].new("Raku"), 'Correct multiple select value when one item';
        }
    }

    {
        my $body = Cro::HTTP::Body::WWWFormUrlEncoded.new: :pairs[
            title => 'Hello world',
            content => 'say "Hello, world"',
            category => 'Coding',
        ];
        given BlogPost.parse($body) {
            is-deeply .tags, Array[Str].new, 'Correct multiple select value when no items';
        }
    }
}

done-testing;
