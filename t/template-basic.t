use Cro::WebApp::Template;
use Test;

my constant $base = $*PROGRAM.parent.add('test-data');
my constant $error-base = $*PROGRAM.parent.add('error-data');

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

my class Temperature {
    has $.low = 12;
    has $.high = 18;
}
my class WeatherNested {
    has $.description = 'rainy';
    has Temperature $.temp .= new;
}
is render-template($base.add('multi-level-deref.crotmp'), WeatherNested.new),
        q:to/EXPECTED/, 'Multi-level smart deference';
    Today's weather is rainy, with a low of 12C and a high of 18C.
    EXPECTED

is render-template($base.add('topic-2.crotmp'), { elems => 101 }),
        q:to/EXPECTED/, 'Topic smart deref always prefers hash key';
    Elems is 101.
    EXPECTED

is render-template($base.add('topic-2.crotmp'), { foo => 1, bar => 2 }),
        q:to/EXPECTED/, 'Topic smart falls back to methods on the hash';
    Elems is 2.
    EXPECTED

is render-template($base.add('topic-3.crotmp'), { elems => 101 }),
        q:to/EXPECTED/, 'Can use <.elems()> and <.<elems>> to disamgiguate';
    Elems method is 1. Elems key is 101.
    EXPECTED

class WithMethodArgs {
    method m($x, :$y) {
        "$x and $y"
    }
}
is render-template($base.add('topic-4.crotmp'), WithMethodArgs.new),
        q:to/EXPECTED/, 'Can pass args in <.m(...)> form';
    We have pos and named!
    EXPECTED

is render-template($base.add('deref-array-1.crotmp'), [1..5]),
        q:to/EXPECTED/, 'Can use <.[0]> and <.[2]> array indexing';
    1 and 3
    EXPECTED

is render-template($base.add('deref-array-2.crotmp'), { :a[5..10], b => 3 }),
        q:to/EXPECTED/, 'Can do more complex array indexing';
    5, 8 and 9
    EXPECTED

is render-template($base.add('deref-hash.crotmp'), { :foo<bar>, :x<a>, :xxx<c>, :k<x> }),
        q:to/EXPECTED/, 'Can do indirect hash indexing';
    bar, a, and c
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

throws-like { render-template($error-base.add('iteration-with-named-arg.crotmp'), {}) },
        X::Cro::WebApp::Template::SyntaxError,
        'Cannot use a named parameter as the iteration variable';

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

is render-template($base.add('conditional-tag.crotmp'), { website => 'https://raku.org/' }),
        q:to/EXPECTED/, 'Conditional with tag part (true)';
    <a href="https://raku.org/">Click to visit</a>
    EXPECTED

is render-template($base.add('conditional-tag.crotmp'), { website => Nil }).trim,
        q:to/EXPECTED/.trim, 'Conditional with tag part (false)';
    <span>No website</span>
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

is norm-ws(render-template($base.add('sub-2.crotmp'), { greeting => 'Bonjour' })),
        norm-ws(q:to/EXPECTED/), 'Subs with arguments work';
    <h1>Hello world</h1>
    <h1>Bonjour</h1>
    <h1>Stuff</h1>
    <p>More stuff</p>
    <h1>Bonjour</h1>
    <p>Yet more stuff</p>
    EXPECTED

is norm-ws(render-template($base.add('sub-3.crotmp'), { t => 'b' })),
        norm-ws(q:to/EXPECTED/), 'Sub arguments may be any expression';
    literal and literaler
    43 and 30
    bs and bbb
    F
    T
    EXPECTED

is norm-ws(render-template($base.add('sub-4.crotmp'), { t => 'b' })),
        norm-ws(q:to/EXPECTED/), 'Subs can have named arguments';
    this - is
    43 - 30
    bs - bbb
    Both notnamed and named
    T
    F
    aaa - bbb
    EXPECTED

is norm-ws(render-template($base.add('sub-5.crotmp'), {})),
        norm-ws(q:to/EXPECTED/), 'Parameters can have defaults';
    foo bar
    x bar
    x y
    foo bar
    x bar
    foo y
    x y
    EXPECTED

throws-like { render-template($error-base.add('sub-pos-after-pos-named.crotmp'), {}) },
            X::Cro::WebApp::Template::SyntaxError,
            'Positional argument after named argument at line 1 near \'$a)>';

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

is norm-ws(render-template($base.add('macro-2.crotmp'), {})),
        norm-ws(q:to/EXPECTED/), 'Basic no-argument macro works';
      <html>
        <head>
          <title>Wow a title!</title>
        </head>
        <body>
          <p>This is my body</p>
        </body>
      </html>
    EXPECTED

is norm-ws(render-template($base.add('comments.crotmp'), {})),
        norm-ws(q:to/EXPECTED/), 'No problem with HTML comments';
    <p>Some fine tag</p>
    <!-- HTML comment -->
    <div>Something else</div>
    <!--
        multi-line HTML--comment
        -->
    <p>And that's it<!--really--></p>
    EXPECTED

is norm-ws(render-template($base.add('comments-integration.crotmp'), {})),
        norm-ws(q:to/EXPECTED/), 'Is not confused by HTML bits commented out';
    <html><!--<articleclass="messageis-small"><divclass="message--body">--><!--</div></article>--></html>
    EXPECTED

is norm-ws(render-template($base.add('template-comments-basic.crotmp'), {})),
        norm-ws(q:to/EXPECTED/), 'Template-level comment syntax works';
    Eat a pie! Om nom ARGH!
    EXPECTED

is norm-ws(render-template($base.add('template-comments-tags.crotmp'), {})),
        norm-ws(q:to/EXPECTED/), 'Template-level comment syntax works';
    Stuff before! Stuff after!
    EXPECTED

sub norm-ws($str) {
    $str.subst(:g, /\s+/, '')
}

done-testing;
