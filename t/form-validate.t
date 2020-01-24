use Cro::WebApp::Form;
use Test;

{
    my class TestForm does Cro::WebApp::Form {
        has Str $.some-optional-field;
        has Str $.some-optional-select will select { <foo bar baz> }
    }

    ok TestForm.empty.is-valid,
            'Empty form that is all optional is valid';
    ok TestForm.new(:some-optional-field<xxx>, :some-optional-select<foo>),
            'Form with values filled when all optional is valid';
}

{
    my class TestForm does Cro::WebApp::Form {
        has Str $.email is required;
        has Str $.password is required is password;
        has Bool $.remember-me;
    }

    nok TestForm.empty.is-valid,
            'Empty form with required inputs is not valid';
    nok TestForm.new(email => 'foo@bar.com', password => '').is-valid,
            'Form with missing required input is not valid';
    ok TestForm.new(email => 'foo@bar.com', password => 's3cr3t').is-valid,
            'Form with required inputs provided is valid';
}

{
    my class TestForm does Cro::WebApp::Form {
        has Str $.a is minlength(5);
        has Str $.b is maxlength(10);
        has Str $.c is min-length(5) is max-length(10);
    }

    ok TestForm.empty.is-valid,
            'Empty form is not invalid due to min/max length if field not required';
    ok TestForm.new(:a(''), :b(''), :c('')).is-valid,
            'Form with empty strings not invalid due to min/max length if field not required';

    nok TestForm.new(:a('foo')).is-valid,
            'Minimum length is enforced';
    ok TestForm.new(:a('fooba')).is-valid,
            'Minimum length can be satisfied';

    nok TestForm.new(:b('foobarbazwat')).is-valid,
            'Maximum length is enforced';
    ok TestForm.new(:b('foobarbaz0')).is-valid,
            'Maximum length can be satisfied';

    nok TestForm.new(:c('foo')).is-valid,
            'Minimum and maximum length together enforced (short)';
    nok TestForm.new(:c('foobarbazwat')).is-valid,
            'Minimum and maximum length together enforced (long)';
    ok TestForm.new(:a('fooba')).is-valid,
            'Minimum and maximum length together can be satisfied';
}

done-testing;
