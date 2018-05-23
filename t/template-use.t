use Cro::WebApp::Template;
use Test;

template-location $*PROGRAM.parent.add('test-data');

is norm-ws(render-template('use-test-1.crotmp', {})),
        norm-ws(q:to/EXPECTED/), 'Can call a sub from a used template';
    <header>
        Foo bar header
    </header>
    Content
    <footer>
        Foo bar footer
    </footer>
    EXPECTED

is norm-ws(render-template('use-test-2.crotmp', {})),
        norm-ws(q:to/EXPECTED/), 'Can apply a macro from a used template';
    <html>
    <header>
        Foo bar header
    </header>
    Here is some body
    <footer>
        Foo bar footer
    </footer>
    </html>
    EXPECTED

sub norm-ws($str) {
    $str.subst(:g, /\s+/, '')
}

done-testing;
