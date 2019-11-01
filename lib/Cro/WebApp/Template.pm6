use Cro::HTTP::Router;
use Cro::WebApp::Template::Repository;

#| Render the template at the specified path using the specified data, and
#| return the result as a string
multi render-template(IO::Path $template-path, $initial-topic --> Str) is export {
    (await get-template-repository.resolve-absolute($template-path.absolute)).render($initial-topic)
}

#| Render the template at the specified path using the specified data
multi render-template(Str $template, $initial-topic --> Str) is export {
    (await get-template-repository.resolve($template)).render($initial-topic);
}

#| Add a path to search for templates. This will be used by both the template and
#| render-template functions. If the compile-all flag is passed, then all of the
#| templates will be compiled up front before the function returns. Otherwise, they
#| will be compiled on first use.
sub template-location(IO() $location, :$compile-all --> Nil) is export {
    my $template-repo = get-template-repository;
    $template-repo.add-location($location);
    compile-dir($template-repo, $location) if $compile-all;
}

sub compile-dir(Cro::WebApp::Template::Repository $template-repo, IO::Path $location --> Nil) {
    for dir($location) {
        when .f {
            await $template-repo.resolve-absolute($_);
        }
        when .d {
            compile-dir($template-repo, $_);
        }
    }
}

#| Used in a Cro::HTTP::Router route handler to render a template and set it as
#| the response body. The initial topic is passed to the template to render. The
#| content type will default to text/html, but can be set explicitly also.
multi template($template, $initial-topic, :$content-type = 'text/html' --> Nil) is export {
    content $content-type, render-template($template, $initial-topic);
}

#| Used in a Cro::HTTP::Router route handler to render a template and set it as
#| the response body. The content type will default to text/html, but can be set
#| explicitly also.
multi template($template, :$content-type = 'text/html' --> Nil) is export {
    template($template, Nil, :$content-type);
}
