use Cro::WebApp::Template;
use Test;

my constant $base = $*PROGRAM.parent.add('test-data');

is render-template($base.add('parts-simple.crotmp'), {}, :parts{ header => \('dave') }),
        q:to/EXPECTED/, 'Can render a part with an explicit capture (value provided)';
    Before part
        User dave is logged in
    After part
    EXPECTED

is render-template($base.add('parts-simple.crotmp'), {}, :parts{ header => \(Nil) }),
        q:to/EXPECTED/, 'Can render a part with an explicit capture (undefined value provided)';
    Before part
        Not logged in
    After part
    EXPECTED

is render-template($base.add('parts-simple.crotmp'), {}, :parts{ header => 'dave' }),
        q:to/EXPECTED/, 'When the part value is a single value it becomes one argument';
    Before part
        User dave is logged in
    After part
    EXPECTED

is render-template($base.add('parts-main.crotmp'), \(:greeting<ahoj>, :name<dave>)),
        q:to/EXPECTED/, 'The MAIN part gets the initial topic (catpure case)';
      ahoj, dave!
    EXPECTED

template-location $*PROGRAM.parent.add('test-data');
is render-template($base.add('parts-use.crotmp'), {}, :parts{ header => 'ann' }).trim,
        q:to/EXPECTED/.trim, 'Correct interaction of parts, macros, and use';
        Logged in as ann
        Hello world
    EXPECTED

done-testing;
