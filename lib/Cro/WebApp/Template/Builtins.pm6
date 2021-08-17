use Cro::HTTP::Router :plugin;
use Cro::HTTP::Router :link;

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

sub __TEMPLATE_SUB__link(*@args, *%args) is export {
    my ($route-name, @rest) = |@args;
    my $maker = router-plugin-get-configs($link-plugin);
    my @options;
    for @$maker -> $links {
        with $links.link-generators{$route-name} {
            return $_(|@rest, |%args);
        }
        @options.push: |$links.link-generators.keys;
    }
    warn "Called the make-link subroutine with $route-name but no such route defined, options are: @options.join('/')";
    "";
}
