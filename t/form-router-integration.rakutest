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
            if $form.is-valid {
                content 'text/plain', qq:to/DUMP/;
                    title: $form.title()
                    content: $form.content()
                    category: $form.category()
                    tags: $form.tags().join(", ")
                    DUMP
            }
            else {
                content 'text/plain', "Invalid\n";
            }
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

my $client = Cro::HTTP::Client.new(base-uri => "http://localhost:{TEST_PORT}", :cookie-jar);

my $render-response;
lives-ok { $render-response = await $client.get("/render") },
        'Can render a form in a template';

my $csrf-token = $client.cookie-jar.contents.first(*.cookie.name eq '__CSRF_TOKEN').cookie.value;
ok $csrf-token, 'Have a CSRF token set as a cookie';
like await($render-response.body-text), /$csrf-token/, 'CSRF token appaers in form body too';

subtest 'Form data is parsed from a application/x-www-form-urlencoded submission' => {
    my $resp;
    lives-ok
            {
                my $body = Cro::HTTP::Body::WWWFormUrlEncoded.new: :pairs[
                    title => 'Hello world',
                    content => 'say "Hello, world"',
                    category => 'Coding',
                    tags => 'Raku',
                    tags => 'Compiler',
                    '__CSRF_TOKEN' => $csrf-token,
                ];
                $resp = await $client.post("http://localhost:{TEST_PORT}/simple/post", :$body)
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

subtest 'Request with missing CSRF token is not valid' => {
    my $resp;
    lives-ok
            {
                my $body = Cro::HTTP::Body::WWWFormUrlEncoded.new: :pairs[
                    title => 'Hello world',
                    content => 'say "Hello, world"',
                    category => 'Coding',
                    tags => 'Raku',
                    tags => 'Compiler',
                ];
                $resp = await $client.post("http://localhost:{TEST_PORT}/simple/post", :$body)
            },
            'Request without CSRF token returned a response';
    is $resp.content-type.type-and-subtype, 'text/plain', 'Got expected content type';
    is await($resp.body-text), qq:to/EXPECTED/, 'Body contents is as expected (shows invalid)';
        Invalid
        EXPECTED
}

subtest 'Request without CSRF cookie is invalid' => {
    my $resp;
    lives-ok
            {
                my $body = Cro::HTTP::Body::WWWFormUrlEncoded.new: :pairs[
                    title => 'Hello world',
                    content => 'say "Hello, world"',
                    category => 'Coding',
                    tags => 'Raku',
                    tags => 'Compiler',
                    '__CSRF_TOKEN' => $csrf-token,
                ];
                # We use a fresh client without our cookie jar
                $resp = await Cro::HTTP::Client.post("http://localhost:{TEST_PORT}/simple/post", :$body)
            },
            'Simple request was successful';
    is $resp.content-type.type-and-subtype, 'text/plain', 'Got expected content type';
    is await($resp.body-text), qq:to/EXPECTED/, 'Body contents is as expected (shows invalid)';
        Invalid
        EXPECTED
}

done-testing;
