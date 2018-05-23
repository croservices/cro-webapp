use Cro::WebApp::Template;
use Test;

template-location $*PROGRAM.parent.add('test-data');

is norm-ws(render-template('use-test.crotmp', {})),
        norm-ws(q:to/EXPECTED/), 'Can render a template found my location';
    <header>
        Foo bar header
    </header>
    Content
    <footer>
        Foo bar footer
    </footer>
    EXPECTED

sub norm-ws($str) {
    $str.subst(:g, /\s+/, '')
}

done-testing;
