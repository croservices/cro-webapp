use Cro::HTTP::Client;
use Cro::HTTP::Router;
use Cro::HTTP::Server;
use Cro::WebApp::Template;
use Cro::UnhandledErrorReporter;
use Test;

use lib $*PROGRAM.parent.add('template-resource-module').Str;
use ResourceRoutes;

my constant TEST_PORT = 30209;

# Suppress any unhandled errors so they don't end up in the test output and
# confuse folks.
set-unhandled-error-reporter -> $ {}

# Global location
template-location $*PROGRAM.parent.add('test-data-global');

class TestAuth is Cro::HTTP::Auth {
    has Str $.user-id is rw;
}
my subset LoggedIn of TestAuth where .user-id.defined;
my subset NotLoggedIn of TestAuth where not .user-id.defined;
my $current-auth = TestAuth.new;

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
        get -> 'transitive-use' {
            template 'transitive-use.crotmp';
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

    include 'part-simple' => route {
        template-location $*PROGRAM.parent.add('test-data');
        template-part 'header', -> {
            'lenka'
        }
        get -> 'use-part' {
            template 'parts-simple.crotmp';
        }
        get -> 'override' {
            template 'parts-simple.crotmp', :parts{ header => 'božena' };
        }
    }

    include 'part-using-auth' => route {
        before-matched { request.auth = $current-auth }
        template-location $*PROGRAM.parent.add('test-data');
        template-part 'header', -> LoggedIn $user {
            $user.user-id
        }
        template-part 'header', -> NotLoggedIn {
            'anonymous'
        }
        get -> 'use-part' {
            template 'parts-simple.crotmp';
        }
    }
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

lives-ok { $resp = await Cro::HTTP::Client.get("http://localhost:{TEST_PORT}/transitive-use") },
        'A route block template-location is used in resolving use';
is norm-ws(await $resp.body-text), norm-ws(q:to/EXPECTED/), 'Correct transitive use template content';
    <html>
    <header>
        Foo bar header
    </header>
    <h1>A heading!</h1>
    <p>Content!</p>
    <footer>
        Foo bar footer
    </footer>
    </html>
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

lives-ok { $resp = await Cro::HTTP::Client.get("http://localhost:{TEST_PORT}/part-simple/use-part") },
        'Request relying on part provider is successful';
is norm-ws(await $resp.body-text), norm-ws(q:to/EXPECTED/), 'Correct value from part provider used';
    Before part
    User lenka is logged in
    After part
    EXPECTED

lives-ok { $resp = await Cro::HTTP::Client.get("http://localhost:{TEST_PORT}/part-simple/override") },
        'Request using part provider override is successful';
is norm-ws(await $resp.body-text), norm-ws(q:to/EXPECTED/), 'Correct value from override used';
    Before part
    User božena is logged in
    After part
    EXPECTED

$current-auth.user-id = Nil;
lives-ok { $resp = await Cro::HTTP::Client.get("http://localhost:{TEST_PORT}/part-using-auth/use-part") },
        'Request relying on auth-aware part provider is successful';
is norm-ws(await $resp.body-text), norm-ws(q:to/EXPECTED/), 'Correct part provider is picked (not logged in)';
    Before part
    User anonymous is logged in
    After part
    EXPECTED

$current-auth.user-id = "noddy";
lives-ok { $resp = await Cro::HTTP::Client.get("http://localhost:{TEST_PORT}/part-using-auth/use-part") },
        'Request relying on auth-aware part provider is successful';
is norm-ws(await $resp.body-text), norm-ws(q:to/EXPECTED/), 'Correct part provider is picked (logged in)';
    Before part
    User noddy is logged in
    After part
    EXPECTED

sub norm-ws($str) {
    $str.subst(:g, /\s+/, '')
}

done-testing;
