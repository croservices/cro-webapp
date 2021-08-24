use Cro::WebApp::Form;
use Test;

{
    my class TestForm does Cro::WebApp::Form {
        has Str $.email is required;
        has Str $.password is required is password;
        has Bool $.remember-me;
    }

    is-deeply TestForm.empty.HTML-RENDER-DATA,
            {
                was-validated => False,
                controls => [
                    {
                        type => 'text',
                        name => 'email',
                        label => 'Email',
                        required => True
                    },
                    {
                        type => 'password',
                        name => 'password',
                        label => 'Password',
                        required => True
                    },
                    {
                        type => 'checkbox',
                        name => 'remember-me',
                        label => 'Remember me',
                        required => False
                    },
                ]
            },
            'Basic form produces correct HTML description';
}

{
    my class BlogPost does Cro::WebApp::Form {
        has Str $.title is required;
        has Str $.content is multiline(:15rows, :80cols) is minlength(5) is maxlength(10000);
        has Str $.category will select { 'Coding', 'Photography', 'Trains' };
        has Str @.tags will select { 'Raku', 'Compiler', 'Landscape', 'City', 'Steam' }
    }

    is-deeply BlogPost.empty.HTML-RENDER-DATA,
            {
                was-validated => False,
                controls => [
                    {
                        type => 'text',
                        name => 'title',
                        label => 'Title',
                        required => True
                    },
                    {
                        type => 'textarea',
                        name => 'content',
                        label => 'Content',
                        required => False,
                        rows => 15,
                        cols => 80,
                        minlength => '5',
                        maxlength => '10000',
                    },
                    {
                        type => 'select',
                        name => 'category',
                        label => 'Category',
                        required => False,
                        options => [
                            ('Coding', 'Coding'),
                            ('Photography', 'Photography'),
                            ('Trains', 'Trains'),
                        ],
                        multi => False
                    },
                    {
                        type => 'select',
                        name => 'tags',
                        label => 'Tags',
                        required => False,
                        options => [
                            ('Raku', 'Raku'),
                            ('Compiler', 'Compiler'),
                            ('Landscape', 'Landscape'),
                            ('City', 'City'),
                            ('Steam', 'Steam')
                        ],
                        multi => True
                    },
                ]
            },
            'Form with text area and select controls gets correct HTML description';

    my $post-with-data = BlogPost.new:
            title => 'A title',
            content => 'Content',
            category => 'Trains',
            tags => ['City', 'Steam'];
    is-deeply $post-with-data.HTML-RENDER-DATA,
            {
                was-validated => False,
                controls => [
                    {
                        type => 'text',
                        name => 'title',
                        label => 'Title',
                        required => True,
                        value => 'A title',
                    },
                    {
                        type => 'textarea',
                        name => 'content',
                        label => 'Content',
                        required => False,
                        rows => 15,
                        cols => 80,
                        value => 'Content',
                        minlength => '5',
                        maxlength => '10000',
                    },
                    {
                        type => 'select',
                        name => 'category',
                        label => 'Category',
                        required => False,
                        options => [
                            ('Coding', 'Coding'),
                            ('Photography', 'Photography'),
                            ('Trains', 'Trains', True),
                        ],
                        multi => False
                    },
                    {
                        type => 'select',
                        name => 'tags',
                        label => 'Tags',
                        required => False,
                        options => [
                            ('Raku', 'Raku'),
                            ('Compiler', 'Compiler'),
                            ('Landscape', 'Landscape'),
                            ('City', 'City', True),
                            ('Steam', 'Steam', True)
                        ],
                        multi => True
                    },
                ]
            },
            'Form with data gets correct HTML description';
}

{
    my class DateForm does Cro::WebApp::Form {
        has $.date is required is date;
    }
    is-deeply DateForm.new(date => '2020-12-25').HTML-RENDER-DATA,
            {
                was-validated => False,
                controls => [
                    {
                        type => 'date',
                        name => 'date',
                        label => 'Date',
                        required => True,
                        value => '2020-12-25',
                    },
                ]
            },
            'Form with date gets correct HTML description';
}

{
    my class DateForm does Cro::WebApp::Form {
        has Date $.date is required;
    }
    is-deeply DateForm.new(date => Date.new('2020-12-25')).HTML-RENDER-DATA,
            {
                was-validated => False,
                controls => [
                    {
                        type => 'date',
                        name => 'date',
                        label => 'Date',
                        required => True,
                        value => '2020-12-25',
                    },
                ]
            },
            'Form with Date type attribute renders a date control';
}

{
    my class DateTimeForm does Cro::WebApp::Form {
        has DateTime $.when is required;
    }
    is-deeply DateTimeForm.new(when => DateTime.new('2020-12-25T10:00:00Z')).HTML-RENDER-DATA,
            {
                was-validated => False,
                controls => [
                    {
                        type => 'datetime-local',
                        name => 'when',
                        label => 'When',
                        required => True,
                        value => '2020-12-25T10:00:00Z',
                    },
                ]
            },
            'Form with DateTime type attribute renders a datetime-local control';

    my $dt = DateTime.now.utc;
    my $formatted-now = sprintf(
        '%4d-%02d-%02dT%02d:%02d:%02dZ',
        .year, .month, .day, .hour, .minute, .second
    ) given $dt;
    is-deeply DateTimeForm.new(when => $dt).HTML-RENDER-DATA,
            {
                was-validated => False,
                controls => [
                    {
                        type => 'datetime-local',
                        name => 'when',
                        label => 'When',
                        required => True,
                        value => $formatted-now
                    },
                ]
            },
            'Form with DateTime.utc type attribute renders a datetime-local control';
}

{
    my class TestLengths does Cro::WebApp::Form {
        has Str $.a is minlength(5);
        has $.b is maxlength(10);
    }

    is-deeply TestLengths.empty.HTML-RENDER-DATA,
            {
                was-validated => False,
                controls => [
                    {
                        type => 'text',
                        name => 'a',
                        label => 'A',
                        required => False,
                        minlength => '5',
                    },
                    {
                        type => 'text',
                        name => 'b',
                        label => 'B',
                        required => False,
                        maxlength => '10',
                    },
                ]
            },
            'Minimum and maximum lengths appear in HTML description';
}

{
    my class TestNumbers does Cro::WebApp::Form {
        has Int $.i is required is min(1) is max(100);
        has Num $.n is required is min(-1e0) is max(1e0);
        has Rat $.r is required is min(0) is max(1);
        has Str $.s is required is number is min(10) is max(20);
    }

    is-deeply TestNumbers.empty.HTML-RENDER-DATA,
            {
                was-validated => False,
                controls => [
                    {
                        type => 'number',
                        name => 'i',
                        label => 'I',
                        required => True,
                        min => '1',
                        max => '100',
                    },
                    {
                        type => 'number',
                        name => 'n',
                        label => 'N',
                        required => True,
                        min => '-1',
                        max => '1',
                    },
                    {
                        type => 'number',
                        name => 'r',
                        label => 'R',
                        required => True,
                        min => '0',
                        max => '1',
                    },
                    {
                        type => 'number',
                        name => 's',
                        label => 'S',
                        required => True,
                        min => '10',
                        max => '20',
                    },
                ]
            },
            'Numeric fields produce correct HTML description';
}

{
    my class FormattedInputTypes does Cro::WebApp::Form {
        has Str $.c is required is color;
        has Str $.d is required is date;
        has Str $.dtl is required is datetime-local;
        has Str $.e is required is email;
        has Str $.m is required is month;
        has Str $.t is required is tel;
        has Str $.s is required is search;
        has Str $.tm is required is time;
        has Str $.u is required is url;
        has Str $.w is required is week;
        has Str $.h is required is hidden;
        has $.f is required is file;
    }

    is-deeply FormattedInputTypes.empty.HTML-RENDER-DATA,
            {
                was-validated => False,
                enctype => 'multipart/form-data',
                controls => [
                    {
                        type => 'color',
                        name => 'c',
                        label => 'C',
                        required => True,
                    },
                    {
                        type => 'date',
                        name => 'd',
                        label => 'D',
                        required => True,
                    },
                    {
                        type => 'datetime-local',
                        name => 'dtl',
                        label => 'Dtl',
                        required => True,
                    },
                    {
                        type => 'email',
                        name => 'e',
                        label => 'E',
                        required => True,
                    },
                    {
                        type => 'month',
                        name => 'm',
                        label => 'M',
                        required => True,
                    },
                    {
                        type => 'tel',
                        name => 't',
                        label => 'T',
                        required => True,
                    },
                    {
                        type => 'search',
                        name => 's',
                        label => 'S',
                        required => True,
                    },
                    {
                        type => 'time',
                        name => 'tm',
                        label => 'Tm',
                        required => True,
                    },
                    {
                        type => 'url',
                        name => 'u',
                        label => 'U',
                        required => True,
                    },
                    {
                        type => 'week',
                        name => 'w',
                        label => 'W',
                        required => True,
                    },
                    {
                        type => 'hidden',
                        name => 'h',
                        label => 'H',
                        required => True,
                    },
                    {
                        type => 'file',
                        name => 'f',
                        label => 'F',
                        required => True,
                    },
                ]
            },
            'Various formatted input types render the correct type';
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
            i => 'omg',
            n => 'wtf',
            r => 'bbq',
            s => 'sauce'
        ];
        is-deeply TestNumbers.parse($body).HTML-RENDER-DATA,
                {
                    was-validated => False,
                    controls => [
                        {
                            type => 'number',
                            name => 'i',
                            label => 'I',
                            required => True,
                            min => '1',
                            max => '100',
                            value => 'omg'
                        },
                        {
                            type => 'number',
                            name => 'n',
                            label => 'N',
                            required => True,
                            min => '-1',
                            max => '1',
                            value => 'wtf'
                        },
                        {
                            type => 'number',
                            name => 'r',
                            label => 'R',
                            required => True,
                            min => '0',
                            max => '1',
                            value => 'bbq'
                        },
                        {
                            type => 'number',
                            name => 's',
                            label => 'S',
                            required => True,
                            min => '10',
                            max => '20',
                            value => 'sauce'
                        },
                    ]
                },
                'Unparseable number values are round-tripped';
    }
}

{
    class TestValidation does Cro::WebApp::Form {
        has $.name is required;
        has $.bio is required is minlength(10) is maxlength(1000);
        has Int $.age is required is min(18) is max(150);
        has Str $.isbn is required is validated(/^[97[8|9]]?\d**9(\d|X)$/, 'Must be a valid ISBN');
    }

    given TestValidation.new(:name(''), :bio('short'), :age(5), :isbn('9999')) {
        nok .is-valid, 'Test form for validation errors is not valid';
        is-deeply .HTML-RENDER-DATA,
                {
                    was-validated => True,
                    controls => [
                        {
                            type => 'text',
                            name => 'name',
                            label => 'Name',
                            required => True,
                            value => '',
                            validation-errors => ['Please fill in this field'],
                        },
                        {
                            type => 'text',
                            name => 'bio',
                            label => 'Bio',
                            required => True,
                            value => 'short',
                            minlength => '10',
                            maxlength => '1000',
                            validation-errors => ["Must not be shorter than 10 characters"],
                        },
                        {
                            type => 'number',
                            name => 'age',
                            label => 'Age',
                            required => True,
                            value => 5,
                            min => '18',
                            max => '150',
                            validation-errors => ["Must not be less than 18"],
                        },
                        {
                            type => 'text',
                            name => 'isbn',
                            label => 'Isbn',
                            required => True,
                            value => '9999',
                            validation-errors => ['Must be a valid ISBN'],
                        },
                    ]
                },
                'Input level validation results are included in the form output';
    }
}

{
    class Signup is Cro::WebApp::Form {
        has Str $.username is required is minlength(5);
        has Str $.password is required is password is minlength(8);
        has Str $.verify-password is password is required;

        method validate-form(--> Nil) {
            if $!password ne $!verify-password {
                self.add-validation-error("Passowrd and verify password do not match");
            }
        }
    }

    given Signup.new(username => 'foobar', password => 'ninechars', verify-password => 'notmatching') {
        nok .is-valid, 'Form is not valid if form-level validation adds errors';
        is-deeply .HTML-RENDER-DATA,
                {
                    was-validated => True,
                    validation-errors => ["Passowrd and verify password do not match"],
                    controls => [
                        {
                            type => 'text',
                            name => 'username',
                            label => 'Username',
                            required => True,
                            minlength => '5',
                            value => 'foobar',
                        },
                        {
                            type => 'password',
                            name => 'password',
                            label => 'Password',
                            required => True,
                            minlength => '8',
                            value => 'ninechars',
                        },
                        {
                            type => 'password',
                            name => 'verify-password',
                            label => 'Verify password',
                            required => True,
                            value => 'notmatching',
                        },
                    ],
                },
                'Form-level validation errors are included in render output';
    }
}

{
    my class CustomTexts does Cro::WebApp::Form {
        has Str $.foo is label('Some custom label') is help('Just a hint') is placeholder('type here');
    }

    is-deeply CustomTexts.empty.HTML-RENDER-DATA,
            {
                was-validated => False,
                controls => [
                    {
                        type => 'text',
                        name => 'foo',
                        label => 'Some custom label',
                        placeholder => 'type here',
                        help => 'Just a hint',
                        required => False,
                    },
                ]
            },
            'Custom label, placeholder, and hint are included in rendering description';
}

done-testing;
