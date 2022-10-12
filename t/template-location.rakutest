use Cro::WebApp::Template;
use Test;

lives-ok { template-location $*PROGRAM.parent.add('test-data') }, 'Can specify template include location';

is render-template('topic-1.crotmp', { description => 'sunny', low => 14, high => 25 }),
        q:to/EXPECTED/, 'Can render a template found my location';
    <div class="weather-info">
      Today's weather is sunny, with a low of 14C and a high of 25C.
    </div>
    EXPECTED

throws-like { render-template('no-such-template', {}) },
        X::Cro::WebApp::Template::NotFound,
        template-name => 'no-such-template',
        'Correct exception when template not found';

done-testing;
