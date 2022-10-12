use Cro::WebApp::Form;
use Cro::WebApp::Template::Repository;
use Test;

class Search does Cro::WebApp::Form { has $.query is search }
class Upload does Cro::WebApp::Form { has $.photo is file   }

constant template = parse-template ｢<&form($_, :method('get'))>｣;

with template.render: Search.empty {
    like $_, / 'method="get"' /, 'Form method is GET';

    unlike $_, / '__CSRF_TOKEN' /, 'CSRF token is omitted';
}

throws-like { template.render: Upload.empty },
    X::Cro::WebApp::Form::FileInGET,
    :message("Form 'Upload' cannot contain element 'photo' with 'GET' method"),
    'File element in a GET form dies';

done-testing;
