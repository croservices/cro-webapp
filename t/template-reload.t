BEGIN %*ENV<CRO_DEV> = True;
use Test;
use Cro::WebApp::Template;
plan 2;

my $test-file = $*PROGRAM.parent.add('test-data').add('reload.crotmp');
END try unlink $test-file;
$test-file.spurt: 'Hello <.name>.';
is render-template($test-file, {name => "World"}), 'Hello World.';

$test-file.spurt: 'Goodbye <.name>!';
is render-template($test-file, {name => "dlroW"}), 'Goodbye dlroW!';
