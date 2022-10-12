use Cro::HTTP::Body;
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

    given TestForm.empty {
        nok .is-valid,
                'Empty form with required inputs is not valid';
        is .validation-state.errors.elems, 2,
                'There are two errors';
        given .validation-state.errors[0] {
            is .input, 'email',
                    'First error has correct field';
            is .problem, Cro::WebApp::Form::ValidationState::Problem::ValueMissing,
                    'First error has correct problem';
        }
        given .validation-state.errors[1] {
            is .input, 'password',
                    'Second error has correct field';
            is .problem, Cro::WebApp::Form::ValidationState::Problem::ValueMissing,
                    'Second error has correct problem';
        }
    }
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

{
    # We parse from a body for these tests, to ensure we can test the invalid value
    # handling semantics.

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
        ok TestNumbers.parse($body).is-valid,
                'If we can parse all the numbers and they are in range, then the form is valid';
    }

    {
        my $body = Cro::HTTP::Body::WWWFormUrlEncoded.new: :pairs[
            i => 'omg',
            n => '0.5',
            r => '0.23',
            s => '15'
        ];
        given TestNumbers.parse($body) {
            nok .is-valid,
                    'Form is invalid if we cannot parse an Int input';
            is .validation-state.errors.elems, 1,
                    'Have a single error';
            is .validation-state.errors[0].input, 'i',
                    'Correct input in error';
            is .validation-state.errors[0].problem, Cro::WebApp::Form::ValidationState::Problem::BadInput,
                    'The problem is a bad input';
        }
    }

    {
        my $body = Cro::HTTP::Body::WWWFormUrlEncoded.new: :pairs[
            i => '42',
            n => 'wtf',
            r => '0.23',
            s => '15'
        ];
        given TestNumbers.parse($body) {
            nok .is-valid,
                    'Form is invalid if we cannot parse a Num input';
            is .validation-state.errors.elems, 1,
                    'Have a single error';
            is .validation-state.errors[0].input, 'n',
                    'Correct input in error';
            is .validation-state.errors[0].problem, Cro::WebApp::Form::ValidationState::Problem::BadInput,
                    'The problem is a bad input';
        }
    }

    {
        my $body = Cro::HTTP::Body::WWWFormUrlEncoded.new: :pairs[
            i => '42',
            n => '0.5',
            r => 'bbq',
            s => '15'
        ];
        given TestNumbers.parse($body) {
            nok .is-valid,
                    'Form is invalid if we cannot parse a Rat input';
            is .validation-state.errors.elems, 1,
                    'Have a single error';
            is .validation-state.errors[0].input, 'r',
                    'Correct input in error';
            is .validation-state.errors[0].problem, Cro::WebApp::Form::ValidationState::Problem::BadInput,
                    'The problem is a bad input';
        }
    }

    {
        my $body = Cro::HTTP::Body::WWWFormUrlEncoded.new: :pairs[
            i => '42',
            n => '0.5',
            r => '0.23',
            s => 'sauce'
        ];
        nok TestNumbers.parse($body).is-valid,
                'Form is invalid if we cannot parse an Str input marked with `is number`';
    }

    {
        my $body = Cro::HTTP::Body::WWWFormUrlEncoded.new: :pairs[
            i => '142',
            n => '1.5',
            r => '-2.3',
            s => '5'
        ];
        given TestNumbers.parse($body) {
            nok .is-valid,
                    'Form is invalid if numbers are out of min/max range';
            is .validation-state.errors.elems, 4,
                    'Have four errors';
            given .validation-state.errors[0] {
                is .input, 'i', 'Correct input on Int input error';
                is .problem, Cro::WebApp::Form::ValidationState::Problem::RangeOverflow,
                        'Correct problem (too high)';
            }
            given .validation-state.errors[1] {
                is .input, 'n', 'Correct input on Num input error';
                is .problem, Cro::WebApp::Form::ValidationState::Problem::RangeOverflow,
                        'Correct problem (too high)';
            }
            given .validation-state.errors[2] {
                is .input, 'r', 'Correct input on Rat input error';
                is .problem, Cro::WebApp::Form::ValidationState::Problem::RangeUnderflow,
                        'Correct problem (too low)';
            }
            given .validation-state.errors[3] {
                is .input, 's', 'Correct input on Str input error';
                is .problem, Cro::WebApp::Form::ValidationState::Problem::RangeUnderflow,
                        'Correct problem (too low)';
            }
        }
    }
}

{
    class CustomValidation does Cro::WebApp::Form {
        has Str $.isbn is validated(/^[97[8|9]]?\d**9(\d|X)$/, 'Must be a valid ISBN');
        has Int $.prime is validated(*.is-prime, 'Must be a prime number');
    }

    ok CustomValidation.empty.is-valid,
            'Custom validations not triggered on not present inputs';
    ok CustomValidation.new(isbn => '123456789X', prime => 101).is-valid,
            'Custom validations pass when all inputs meet the requirements';

    given CustomValidation.new(isbn => '1234', prime => 42) {
        nok .is-valid, 'Validation fails when custom validations are not met';
        is .validation-state.errors.elems, 2,
                'Have two errors';
        given .validation-state.errors[0] {
            is .input, 'isbn', 'Correct input on first error';
            is .problem, Cro::WebApp::Form::ValidationState::Problem::CustomError,
                    'Problem is a custom error';
            is .message, 'Must be a valid ISBN',
                    'Correct message attached';
        }
        given .validation-state.errors[1] {
            is .input, 'prime', 'Correct input on second error';
            is .problem, Cro::WebApp::Form::ValidationState::Problem::CustomError,
                    'Problem is a custom error';
            is .message, 'Must be a prime number',
                    'Correct message attached';
        }
    }
}

{
    class Signup is Cro::WebApp::Form {
        has Str $.username is required is minlength(5);
        has Str $.password is required is minlength(8);
        has Str $.verify-password is required;

        method validate-form(--> Nil) {
            if $!password ne $!verify-password {
                self.add-validation-error("Passowrd and verify password do not match");
            }
        }
    }

    given Signup.empty {
        nok .is-valid, 'Empty form is not valid';
        is .validation-state.errors.elems, 3, 'Have 3 errors';
        is all(.validation-state.errors>>.problem),
                Cro::WebApp::Form::ValidationState::Problem::ValueMissing,
                'All errors are about missing values';
    }

    given Signup.new(username => 'foobar', password => 'ninechars', verify-password => 'ninechars') {
        ok .is-valid, 'Form with all correct fields validates';
    }

    given Signup.new(username => 'foobar', password => 'ninechars', verify-password => '') {
        nok .is-valid, 'Form with missing required input does not validate';
        is .validation-state.errors.elems, 1,
                'Only one error is present';
        is .validation-state.errors[0].problem,
                Cro::WebApp::Form::ValidationState::Problem::ValueMissing,
                'Error is about missing field; we did not bother trying form-level';
    }

    given Signup.new(username => 'foobar', password => 'ninechars', verify-password => 'notmatching') {
        nok .is-valid, 'Form is not valid if form-level validation adds errors';
        is .validation-state.errors.elems, 1,
                'There is one error';
        given .validation-state.errors[0] {
            nok .input.defined,
                    'The error is not associated with a particular input';
            is .problem, Cro::WebApp::Form::ValidationState::Problem::CustomError,
                    'Error is about missing field; we did not bother trying form-level';
            is .message, 'Passowrd and verify password do not match',
                    'Correct message';
        }
    }
}

done-testing;
