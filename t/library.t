use Cro::WebApp::Template;
use Test;
use lib $*PROGRAM.parent.add('library-module').Str;

my constant $base = $*PROGRAM.parent.add('library-test-data');

is render-template($base.add('use-only.crotmp'), {}), q:to/EXPECTED/, 'Use of a library compiles';

    Everything is OK
    EXPECTED

is render-template($base.add('call-sub.crotmp'), {}), q:to/EXPECTED/, 'Can call a library subroutine';

    Library: hell and damnation
    EXPECTED

is render-template($base.add('call-macro.crotmp'), {}), q:to/EXPECTED/, 'Can call a library macro';

    <div class="container">Contained</div>
    EXPECTED

done-testing;
