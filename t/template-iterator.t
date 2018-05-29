use Cro::WebApp::Template;
use Test;

my constant $base = $*PROGRAM.parent.add('test-data');

is norm-ws(render-template($base.add('iteration-2.crotmp'), { countries => [
                { name => 'Argentina', alpha2 => 'AR' },
                { name => 'Bhutan', alpha2 => 'BT' },
                { name => 'Czech Republic', alpha2 => 'CZ' },
            ]})),
        norm-ws(q:to/EXPECTED/), 'Conditional expressions on topic with simple infix (1)';
    <select name="country">
        <option value="AR">Argentina</option>
        <option value="BT">Bhutan</option>
        <option value="CZ">Czech Republic</option>
    </select>
    EXPECTED

sub norm-ws($str) {
    $str.subst(:g, /\s+/, '')
}

done-testing;
