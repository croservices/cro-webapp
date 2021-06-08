use Cro::HTTP::Client;
use Cro::HTTP::Router;
use Cro::HTTP::Server;
use Cro::WebApp::Template;
use Test;

use lib $*PROGRAM.parent.add('template-resource-module').Str;
use ResourceRoutes;

my constant TEST_PORT = 30209;

# Global location
template-location $*PROGRAM.parent.add('test-data-global');

my $application = route {
    include route {
        # Route-block local location
        template-location $*PROGRAM.parent.add('test-data');

        get -> {
            template 'macro-1.crotmp', { foo => 'xxx', bar => 'yyy' };
        }
        get -> 'nodata' {
            template 'literal.crotmp';
        }
        get -> 'ct1' {
            template 'macro-1.crotmp', { foo => 'abc', bar => 'def' },
                    content-type => 'text/plain';
        }
        get -> 'ct2' {
            template 'literal.crotmp', content-type => 'text/plain';
        }
        get -> 'global-inner' {
            template 'global.crotmp';
        }
    }

    get -> 'no-location' {
        template 'literal.crotmp';
    }
    get -> 'global-outer' {
        template 'global.crotmp';
    }

    include test-resource-template-without-prefix();
    include test-resource-template-with-prefix();
    include test-resource-template-with-prefix-with-slash();
}
my $server = Cro::HTTP::Server.new(:$application, :host('localhost'), :port(TEST_PORT));
$server.start;
LEAVE try $server.stop;

my $resp;
lives-ok { $resp = await Cro::HTTP::Client.get("http://localhost:{TEST_PORT}/") };
is $resp.content-type.type-and-subtype, 'text/html',
        'Got expected default content type';
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

lives-ok { $resp = await Cro::HTTP::Client.get("http://localhost:{TEST_PORT}/nodata") };
is $resp.content-type.type-and-subtype, 'text/html',
        'Got expected default content type';
is norm-ws(await $resp.body-text), norm-ws(q:to/EXPECTED/), 'Can use template without data';
      <div>
        <strong>Hello, I'm a template!</strong>
      </div>
    EXPECTED

lives-ok { $resp = await Cro::HTTP::Client.get("http://localhost:{TEST_PORT}/ct1") };
is $resp.content-type.type-and-subtype, 'text/plain',
        'Got explicitly set content type when data';
is norm-ws(await $resp.body-text), norm-ws(q:to/EXPECTED/), 'Template rendered OK';
      <ul>
        <li>
        <strong>abc</strong>
          def
        </li>
        <li>
          <strong>abc</strong>
          def
        </li>
      </ul>
    EXPECTED

lives-ok { $resp = await Cro::HTTP::Client.get("http://localhost:{TEST_PORT}/ct2") };
is $resp.content-type.type-and-subtype, 'text/plain',
        'Got explicitly set content type when no data';
is norm-ws(await $resp.body-text), norm-ws(q:to/EXPECTED/), 'Template rendered OK';
      <div>
        <strong>Hello, I'm a template!</strong>
      </div>
    EXPECTED

throws-like { await Cro::HTTP::Client.get("http://localhost:{TEST_PORT}/no-location") },
        X::Cro::HTTP::Error::Server,
        'Template locations do not leak from inner route block to outer';

lives-ok { $resp = await Cro::HTTP::Client.get("http://localhost:{TEST_PORT}/global-inner") },
        'A global template location is available in the inner route block';
is norm-ws(await $resp.body-text), norm-ws(q:to/EXPECTED/), 'Correct global template content';
    I am everywhere
    EXPECTED

lives-ok { $resp = await Cro::HTTP::Client.get("http://localhost:{TEST_PORT}/global-outer") },
        'A global template location is available in the outer route block';
is norm-ws(await $resp.body-text), norm-ws(q:to/EXPECTED/), 'Correct global template content';
    I am everywhere
    EXPECTED

lives-ok { $resp = await Cro::HTTP::Client.get("http://localhost:{TEST_PORT}/res-without-prefix") },
        'Templates located via resources work (no prefix)';
is norm-ws(await $resp.body-text), norm-ws(q:to/EXPECTED/), 'Correct resource template content';
    I am a resource
    EXPECTED

lives-ok { $resp = await Cro::HTTP::Client.get("http://localhost:{TEST_PORT}/res-with-prefix") },
        'Templates located via resources work (prefix without trailing slash)';
is norm-ws(await $resp.body-text), norm-ws(q:to/EXPECTED/), 'Correct resource template content';
    I am a resource
    EXPECTED

lives-ok { $resp = await Cro::HTTP::Client.get("http://localhost:{TEST_PORT}/res-with-prefix-with-slash") },
        'Templates located via resources work (prefix with trailing slash)';
is norm-ws(await $resp.body-text), norm-ws(q:to/EXPECTED/), 'Correct resource template content';
    I am a resource
    EXPECTED

sub norm-ws($str) {
    $str.subst(:g, /\s+/, '')
}

done-testing;
