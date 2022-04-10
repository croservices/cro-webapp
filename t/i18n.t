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

is get-response(route {
    load-translation-file('main', 't/resources/main.po');
    _-prefix 'main';

    get -> 'render' {
        is 'b', _('a', :prefix('main'));
        template 'i18n-_.crotmp';
    }
}), "b\nb";

ok get-response(route {
    load-translation-file('main', 't/resources/main.po');
    _-prefix 'main';

    get -> 'render' {
        template 'i18n-form.crotmp', { foo => I18NAwareForm.empty };
    }
}) ~~ /'Your Name'/;

is get-response(route {
    # XXX We currently fuzzy-match `en` and `en-XX`, should we really?
    load-translation-file('main', 't/resources/main.po', :language<en en-GB en-US>);
    load-translation-file('main', 't/resources/main-fr.po', :language<fr fr-FR fr-CH>);
    _-prefix 'main';
    select-language -> @ { 'fr' }

    get -> 'render' {
        template 'i18n-_.crotmp';
    }
}), "b mais en français\nb mais en français";

sub get-response($application) {
    my $server = Cro::HTTP::Server.new(:$application, :host('localhost'), :port(TEST_PORT));
    $server.start;
    LEAVE try $server.stop;
    my $client = Cro::HTTP::Client.new(base-uri => "http://localhost:{ TEST_PORT }", :cookie-jar);

    my $render-response;
    lives-ok { $render-response = await $client.get("/render") };
    ok $render-response.defined;
    return await $render-response.body-text;
}