use Cro::WebApp::Template;
use Test;

my constant $base = $*PROGRAM.parent.add('test-data');

is render-template($base.add('literal.crotmp'), {}), q:to/EXPECTED/, 'Literal text passed through';
    <div>
      <strong>Hello, I'm a template!</strong>
    </div>
    EXPECTED

is render-template($base.add('topic-1.crotmp'), { description => 'sunny', low => 14, high => 25 }),
        q:to/EXPECTED/, 'Topic smart dereference with hash';
    <div class="weather-info">
      Today's weather is sunny, with a low of 14C and a high of 25C.
    </div>
    EXPECTED

my class Weather {
    has $.description = 'rainy';
    has $.low = 12;
    has $.high = 18;
}
is render-template($base.add('topic-1.crotmp'), Weather.new),
        q:to/EXPECTED/, 'Topic smart deference with object';
    <div class="weather-info">
      Today's weather is rainy, with a low of 12C and a high of 18C.
    </div>
    EXPECTED

is render-template($base.add('topic-2.crotmp'), { elems => 101 }),
        q:to/EXPECTED/, 'Topic smart deref always prefers hash key';
    Elems is 101.
    EXPECTED

is render-template($base.add('topic-2.crotmp'), { foo => 1, bar => 2 }),
        q:to/EXPECTED/, 'Topic smart falls back to methods on the hash';
    Elems is 2.
    EXPECTED

is render-template($base.add('escape.crotmp'),
        { attr-esc => Q/1 & 'a' & "b" not < or >/, body-esc => '1 < 2 < 3 > 2 & so on' }),
        q:to/EXPECTED/, 'Escaping in body and attributes works correctly';
    <div id="1 &amp; &apos;a&apos; &amp; &quot;b&quot; not < or >">
      1 &lt; 2 &lt; 3 &gt; 2 &amp; so on
    </div>
    EXPECTED

is render-template($base.add('iteration-1.crotmp'),
        {
            countries => [
                { name => 'Argentina', alpha2 => 'AR' },
                { name => 'Bhutan', alpha2 => 'BT' },
                { name => 'Czech Republic', alpha2 => 'CZ' },
            ]
        }),
        q:to/EXPECTED/, 'Basic iteration using topic';
    <select name="country">
        <option value="AR">Argentina</option>
        <option value="BT">Bhutan</option>
        <option value="CZ">Czech Republic</option>
    </select>
    EXPECTED

is render-template($base.add('conditional-1.crotmp'), { foo => False, bar => False }),
        q:to/EXPECTED/, 'Basic conditionals behave correctly (1)';
    This is always here.
    This is if bar is false
    This is also always here.
    EXPECTED

is render-template($base.add('conditional-1.crotmp'), { foo => False, bar => True }),
        q:to/EXPECTED/, 'Basic conditionals behave correctly (2)';
    This is always here.
    This is also always here.
    EXPECTED

is render-template($base.add('conditional-1.crotmp'), { foo => True, bar => False }),
        q:to/EXPECTED/, 'Basic conditionals behave correctly (3)';
    This is always here.
    This is if foo is true
    This is if bar is false
    This is also always here.
    EXPECTED

is render-template($base.add('conditional-1.crotmp'), { foo => True, bar => True }),
        q:to/EXPECTED/, 'Basic conditionals behave correctly (4)';
    This is always here.
    This is if foo is true
    This is also always here.
    EXPECTED

is render-template($base.add('sub-1.crotmp'), {}),
        q:to/EXPECTED/, 'Basic no-argument sub works';
      <header>
        <nav>
          blah blabh
        </nav>
      </header>

      <header>
        <nav>
          blah blabh
        </nav>
      </header>

    EXPECTED

is norm-ws(render-template($base.add('macro-1.crotmp'), { foo => 'xxx', bar => 'yyy' })),
        norm-ws(q:to/EXPECTED/), 'Basic no-argument macro works';
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

sub norm-ws($str) {
    $str.subst(:g, /\s+/, '')
}

done-testing;
