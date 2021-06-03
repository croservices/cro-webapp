use Cro::WebApp::I18N;
use Cro::HTTP::Router;
use Cro::HTTP::Client;
use Cro::HTTP::Server;
use Cro::WebApp::Form;
use Cro::WebApp::Template;
use Test;

my constant TEST_PORT = 30210;

template-location $*PROGRAM.parent.add('test-data');

my class I18NAwareForm is Cro::WebApp::Form {
    has $.name is rw is i18n-label('name-field');
}

my $application = route {
    load-translation-file('main', 't/resources/test.po');
    _-prefix 'main';
    get -> 'render' {
        is 'b', _('a', :prefix('main'));
        template 'i18n-_.crotmp';
    }

    get -> 'form' {
        template 'i18n-form.crotmp', { foo => I18NAwareForm.empty };
    }
}
my $server = Cro::HTTP::Server.new(:$application, :host('localhost'), :port(TEST_PORT));
$server.start;
LEAVE try $server.stop;
my $client = Cro::HTTP::Client.new(base-uri => "http://localhost:{ TEST_PORT }", :cookie-jar);

my $render-response;
lives-ok { $render-response = await $client.get("/render") },
        'Can use _ in a template';
ok $render-response.defined;
is await($render-response.body-text), "b\nb";

lives-ok { $render-response = await $client.get("/form") },
        'Can render a form in a template';
ok $render-response.defined;
ok await($render-response.body-text) ~~ /'Your Name'/;