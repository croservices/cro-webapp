use Cro::HTTP::Client;
use Cro::HTTP::Router;
use Cro::HTTP::Server;
use Cro::WebApp::Template;
use Test;

my constant TEST_PORT = 30209;

template-location $*PROGRAM.parent.add('test-data');

my $application = route {
    get -> {
        template 'macro-1.crotmp', { foo => 'xxx', bar => 'yyy' };
    }
}
my $server = Cro::HTTP::Server.new(:$application, :host('localhost'), :port(TEST_PORT));
$server.start;
LEAVE try $server.stop;

my $resp;
lives-ok { $resp = await Cro::HTTP::Client.get("http://localhost:{TEST_PORT}/") };
is norm-ws(await $resp.body-text), norm-ws(q:to/EXPECTED/), 'Request to a template-served route works';
      <ul>
        <li>
        <strong>xxx</strong>
          yyy
        </li>
        <li>
          <strong>xxx</strong>
          yyy
        </li>
      </ul>
    EXPECTED

sub norm-ws($str) {
    $str.subst(:g, /\s+/, '')
}

done-testing;
