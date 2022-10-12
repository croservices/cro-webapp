use Cro::WebApp::Template;
use Test;

my constant $base = $*PROGRAM.parent.add('test-data');

my $html = '<p>Foo bar baz!</p>';
my $script-a = '<script>alert("XSS")</script>';
my $script-b = '<a href="javascript:alert(42)">totally safe</a>';

is render-template($base.add('html.crotmp'), { :$html }), q:to/EXPECTED/, 'HTML builtin works';
    <p>Foo bar baz!</p>
    EXPECTED

throws-like { render-template($base.add('html.crotmp'), { html => $script-a }) },
        X::Cro::WebApp::Template::XSS,
        '<script> disallowed in HTML';

throws-like { render-template($base.add('html.crotmp'), { html => $script-b }) },
        X::Cro::WebApp::Template::XSS,
        'javascript: in attribute disallowed in HTML';

is render-template($base.add('html-js.crotmp'), { :$html }), q:to/EXPECTED/, 'HTML-AND-JAVASCRIPT builtin works';
    <p>Foo bar baz!</p>
    EXPECTED

is render-template($base.add('html-js.crotmp'), { html => $script-a }), q:to/EXPECTED/, 'HTML-AND-JAVASCRIPT allows JS (1)';
    <script>alert("XSS")</script>
    EXPECTED

is render-template($base.add('html-js.crotmp'), { html => $script-b }), q:to/EXPECTED/, 'HTML-AND-JAVASCRIPT allows JS (2)';
    <a href="javascript:alert(42)">totally safe</a>
    EXPECTED

done-testing;
