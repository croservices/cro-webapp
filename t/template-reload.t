BEGIN %*ENV<CRO_DEV> = True;
use Test;
use Cro::WebApp::Template;
plan 4;

my $test-file = $*PROGRAM.parent.add('test-data').add('reload.crotmp');
END try unlink $test-file;
$test-file.spurt: 'Hello <.name>.';
is render-template($test-file, {name => "World"}), 'Hello World.',
    'Correct rendering before change';

$test-file.spurt: 'Goodbye <.name>!';
is render-template($test-file, {name => "dlroW"}), 'Goodbye dlroW!',
        'Change was detected';

my $used-file = $*PROGRAM.parent.add('test-data').add('reload-used.crotmp');
END try unlink $used-file;
$used-file.spurt: "<:sub foo>yes!</:>";
my $using-file = $*PROGRAM.parent.add('test-data').add('reload-using.crotmp');
END try unlink $using-file;
$using-file.spurt: "<:use 'reload-used.crotmp'><&foo>";
template-location $*PROGRAM.parent.add('test-data');
is render-template($using-file, {}), 'yes!',
        'Correct rendering involving `use` before change';

$used-file.spurt: "<:sub foo>no!</:>";
is render-template($using-file, {}), 'no!',
        'Change in used module was detected';
