use Cro::HTTP::Body;
use Cro::HTTP::Client;
use Cro::HTTP::Router;
use Cro::HTTP::Server;
use Test;

my constant TEST_PORT = 30210;

my $application = route {
    use Cro::WebApp::Form;
    use Cro::WebApp::Template;

    my class BlogPost does Cro::WebApp::Form {
        has Str $.title is required;
        has Str $.content is multiline;
        has Str $.category will select { 'Coding', 'Photography', 'Trains' };
        has Str @.tags will select { 'Raku', 'Compiler', 'Landscape', 'City', 'Steam' }
    }

    post -> 'simple', 'post' {
        form-data -> BlogPost $form {
            content 'text/plain', qq:to/DUMP/;
                title: $form.title()
                content: $form.content()
                category: $form.category()
                tags: $form.tags().join(", ")
                DUMP
        }
    }

    template-location $*PROGRAM.parent.add('test-data');

    get -> 'render' {
        template 'form.crotmp', { form => BlogPost.empty }
    }
}
my $server = Cro::HTTP::Server.new(:$application, :host('localhost'), :port(TEST_PORT));
$server.start;
LEAVE try $server.stop;

lives-ok { await Cro::HTTP::Client.get("http://localhost:{TEST_PORT}/render") },
        'Can render a form in a template';

subtest 'Form data is parsed from a application/x-www-form-urlencoded submission' => {
    my $resp;
    lives-ok
            {
                my $body = Cro::HTTP::Body::WWWFormUrlEncoded.new: :pairs[
                    title => 'Hello world',
                    content => 'say "Hello, world"',
                    category => 'Coding',
                    tags => 'Raku',
                    tags => 'Compiler'
                ];
                $resp = await Cro::HTTP::Client.post("http://localhost:{TEST_PORT}/simple/post", :$body)
            },
            'Simple request was successful';
    is $resp.content-type.type-and-subtype, 'text/plain', 'Got expected content type';
    is await($resp.body-text), qq:to/EXPECTED/, 'Got expected body content';
        title: Hello world
        content: say "Hello, world"
        category: Coding
        tags: Raku, Compiler
        EXPECTED
}

done-testing;
