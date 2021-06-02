use Cro::HTTP::Router;
use Cro::WebApp::Template;

sub test-resource-template-without-prefix() is export {
    route {
        resources-from %?RESOURCES;
        templates-from-resources;
        get -> 'res-without-prefix' {
            template 'templates/restest.crotmp'
        }
    }
}

sub test-resource-template-with-prefix() is export {
    route {
        resources-from %?RESOURCES;
        templates-from-resources prefix => 'templates';
        get -> 'res-with-prefix' {
            template 'restest.crotmp'
        }
    }
}

sub test-resource-template-with-prefix-with-slash() is export {
    route {
        resources-from %?RESOURCES;
        templates-from-resources prefix => 'templates/';
        get -> 'res-with-prefix-with-slash' {
            template 'restest.crotmp'
        }
    }
}

