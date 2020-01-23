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
        has Str $.content is multiline(:15rows, :80cols);
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
                        cols => 80
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

done-testing;
