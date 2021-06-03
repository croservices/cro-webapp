use Cro::WebApp::I18N;

class X::Cro::WebApp::Template::XSS is Exception {
    has Str $.content is required;
    method message() {
        "Potential XSS attack detected in content '$!content' being rendered using <\&HTML(...)> in template"
    }
}

sub __TEMPLATE_SUB__HTML(Str() $html) is export {
    if $html ~~ /:i '<' \s* script \W | \" \s* javascript \s* ':'/ {
        die X::Cro::WebApp::Template::XSS.new(content => ~$/);
    }
    $html
}

sub __TEMPLATE_SUB__HTML-AND-JAVASCRIPT(Str() $html) is export {
    $html
}

multi sub __TEMPLATE_SUB___(Str $key) is export {
    _($key);
}
multi sub __TEMPLATE_SUB___(Str $prefix, Str $key) is export {
    _($prefix, $key);
}