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
    my class TestLengths does Cro::WebApp::Form {
        has Str $.a is minlength(5);
        has $.b is maxlength(10);
    }

    is-deeply TestLengths.empty.HTML-RENDER-DATA,
            {
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
    }

    is-deeply FormattedInputTypes.empty.HTML-RENDER-DATA,
            {
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
                ]
            },
            'Various formatted input types render the correct type';
}

done-testing;
