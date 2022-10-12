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
            is-deeply .form-data, %(email => 'foo@bar.com', password => 'correcthorsebatterystaple', remember-me => False),
              'Can get the object data as a hash';
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

{
    my class TestNumbers does Cro::WebApp::Form {
        has Int $.i is required is min(1) is max(100);
        has Num $.n is required is min(-1e0) is max(1e0);
        has Rat $.r is required is min(0) is max(1);
        has Str $.s is required is number is min(10) is max(20);
    }

    {
        my $body = Cro::HTTP::Body::WWWFormUrlEncoded.new: :pairs[
            i => '42',
            n => '0.5',
            r => '0.23',
            s => '15'
        ];
        given TestNumbers.parse($body) {
            is-deeply .i, 42, 'Can parse 42 value into an Int';
            is-deeply .n, 0.5e0, 'Can parse 0.5 value into a Num';
            is-deeply .r, 0.23, 'Can parse 0.23 value into a Rat';
            is-deeply .s, '15', 'String number is left alone';
        }
    }

    {
        my $body = Cro::HTTP::Body::WWWFormUrlEncoded.new: :pairs[
            i => '42e3',
            n => '0.5e2',
            r => '0.23e1',
            s => '15e0'
        ];
        given TestNumbers.parse($body) {
            is-deeply .i, 42000, 'Can parse 42e3 value into an Int';
            is-deeply .n, 0.5e2, 'Can parse 0.5e2 value into a Num';
            is-deeply .r, 2.3, 'Can parse 0.23e1 value into a Rat';
            is-deeply .s, '15e0', 'String number is left alone';
        }
    }

    {
        my $body = Cro::HTTP::Body::WWWFormUrlEncoded.new: :pairs[
            i => 'omg',
            n => 'wtf',
            r => 'bbq',
            s => 'sauce'
        ];
        given TestNumbers.parse($body) {
            is-deeply .i, Int, 'Unparseable leads to Int type object';
            is-deeply .n, Num, 'Unparseable leads to Num type object';
            is-deeply .r, Rat, 'Unparseable leads to Rat type object';
            is-deeply .s, 'sauce', 'String number is left alone even if not parseable as a number';
        }
    }
}

{
    my class TestDate does Cro::WebApp::Form {
        has Date $.date is required;
        has DateTime $.datetime is required;
    }
    my $body = Cro::HTTP::Body::WWWFormUrlEncoded.new: :pairs[
        date => '2020-02-21',
        datetime => '2020-02-21T10:20:00'
    ];
    given TestDate.parse($body) {
        is-deeply .date, Date.new(2020, 2, 21), 'Date is parsed correctly';
        is-deeply .datetime, DateTime.new(2020, 2, 21, 10, 20, 0), 'DateTime is parsed correctly';
    }
}

{
    my class TestFile is Cro::WebApp::Form {
        has $.f is required is file;
    }
    {
        my $body = Cro::HTTP::Body::WWWFormUrlEncoded.new;
        given TestFile.parse($body) {
            is-deeply .f, Any, 'WWWFormUrlEncoded cannot produce a body part form nothing';
        }
    }
    {
        my $body = Cro::HTTP::Body::MultiPartFormData.new: :parts[
            Cro::HTTP::Body::MultiPartFormData::Part.new(name => 'f', filename => 'a.txt', body-blob => "Ohai".encode('utf-8')),
        ];
        given TestFile.parse($body) {
            ok .f.defined, 'WWWFormUrlEncoded can produce a body part for the file';
            is .f.filename, 'a.txt', 'WWWFormUrlEncoded can produce a body part for the file';
            is .f.body-blob.decode('utf-8'), 'Ohai', 'Body roundtrips';
        }
    }
}

done-testing;
