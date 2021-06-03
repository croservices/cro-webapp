use Cro::WebApp::I18N;
use Cro::HTTP::Router;
use Cro::HTTP::Client;
use Cro::HTTP::Server;
use Cro::WebApp::Template;
use Test;

my constant TEST_PORT = 30210;

template-location $*PROGRAM.parent.add('test-data');

my $application = route {
    load-translation-file('main', 't/resources/test.po');
    _-prefix 'main';
    get -> 'render' {
        is 'b', _('main', 'a');
        template 'i18n.crotmp';
    }
}
my $server = Cro::HTTP::Server.new(:$application, :host('localhost'), :port(TEST_PORT));
$server.start;
LEAVE try $server.stop;
my $client = Cro::HTTP::Client.new(base-uri => "http://localhost:{ TEST_PORT }", :cookie-jar);

my $render-response;
lives-ok { $render-response = await $client.get("/render") },
        'Can render a form in a template';
is await($render-response.body-text), 'b';