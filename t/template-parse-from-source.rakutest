use Test;
use Cro::WebApp::Template::Repository;

my Cro::WebApp::Template::Compiled $parsed;
lives-ok { $parsed = parse-template('<.foo>, <.bar>') },
        'Can parse a template from a string';
is $parsed.render({ foo => 'hello', bar => 'world', }),
        'hello, world',
        'Can render template parsed from source';

done-testing;
