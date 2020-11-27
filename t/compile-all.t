use Cro::WebApp::Template;
use Test;

lives-ok
        { template-location $*PROGRAM.parent.add('test-data'), :compile-all },
        'Compiling all templates successfully lives';

throws-like
        { template-location $*PROGRAM.parent.add('compile-all-error'), :compile-all },
        X::Cro::WebApp::Template::SyntaxError,
        file => /'problem.crotmp'$/,
        line => 2,
        'Compilation errors reported by compile-all (top-level of directory)';

throws-like
        { template-location $*PROGRAM.parent.add('compile-all-error-deep'), :compile-all },
        X::Cro::WebApp::Template::SyntaxError,
        file => /'broken.crotmp'$/,
        line => 3,
        'Compilation errors reported by compile-all (nested directory)';

lives-ok
        { template-location $*PROGRAM.parent.add('compile-all-error-deep'), :compile-all, test => { $_ !~~ / 'broken' | 'problem' / } },
        'Can ignore files';

done-testing;
