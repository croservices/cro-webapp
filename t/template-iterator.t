use Cro::WebApp::Template;
use Test;

my constant $base = $*PROGRAM.parent.add('test-data');
my constant $error-base = $*PROGRAM.parent.add('error-data');

is norm-ws(render-template($base.add('iteration-2.crotmp'), %{ countries => [
                { name => 'Argentina', alpha2 => 'AR' },
                { name => 'Bhutan', alpha2 => 'BT' },
                { name => 'Czech Republic', alpha2 => 'CZ' },
            ]})),
        norm-ws(q:to/EXPECTED/), 'Iteration over custom variable';
    <select name="country">
        <option value="AR">Argentina</option>
        <option value="BT">Bhutan</option>
        <option value="CZ">Czech Republic</option>
    </select>
    EXPECTED

is norm-ws(render-template($base.add('iteration-3.crotmp'), %{ countries => [
    { name => 'Argentina', alpha2 => 'AR' },
    { name => 'Bhutan', alpha2 => 'BT' },
    { name => 'Czech Republic', alpha2 => 'CZ' },]})),
        norm-ws(q:to/EXPECTED/), 'Can use @$foo syntax to iterate';
    <select name="country">
        <option value="AR">Argentina</option>
        <option value="BT">Bhutan</option>
        <option value="CZ">Czech Republic</option>
    </select>
    EXPECTED

is norm-ws(render-template($base.add('iteration-4.crotmp'), %{ countries => [
    { name => 'Argentina', alpha2 => 'AR' },
    { name => 'Bhutan', alpha2 => 'BT' },
    { name => 'Czech Republic', alpha2 => 'CZ' },]})),
        norm-ws(q:to/EXPECTED/), 'Can use @$foo.deref syntax to iterate';
    <select name="country">
        <option value="AR">Argentina</option>
        <option value="BT">Bhutan</option>
        <option value="CZ">Czech Republic</option>
    </select>
    EXPECTED

sub norm-ws($str) {
    $str.subst(:g, /\s+/, '')
}

is norm-ws(render-template($base.add('iteration-5.crotmp'), %{ countries => [
                { name => 'Argentina', alpha2 => 'AR' },
                { name => 'Bhutan', alpha2 => 'BT' },
                { name => 'Czech Republic', alpha2 => 'CZ' },
            ]})),
        norm-ws(q:to/EXPECTED/), 'Can use @.foo syntax to iterate';
    <select name="country">
        <option value="AR">Argentina</option>
        <option value="BT">Bhutan</option>
        <option value="CZ">Czech Republic</option>
    </select>
    EXPECTED

is norm-ws(render-template($base.add('iteration-6.crotmp'), { :things['foo', 'bar', 'baz'] })),
        norm-ws(q:to/EXPECTED/), 'Separator syntax works';
    foo
    <hr>
    bar
    <hr>
    baz
    EXPECTED

throws-like { render-template($error-base.add('misplaced-separator.crotmp'), {}) },
        X::Cro::WebApp::Template::SyntaxError,
        'Can only use separator inside of iteration';

throws-like { render-template($error-base.add('duplicate-separator.crotmp'), {}) },
        X::Cro::WebApp::Template::SyntaxError,
        'Can only have one separator';

done-testing;
