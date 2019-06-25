use Cro::HTTP::Router;
use Cro::WebApp::Template::Repository;

multi render-template(IO::Path $template-path, $initial-topic) is export {
    (await get-template-repository.resolve-absolute($template-path.absolute)).render($initial-topic)
}

multi render-template(Str $template, $initial-topic) is export {
    (await get-template-repository.resolve($template)).render($initial-topic);
}

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

multi template($template, $initial-topic, :$content-type = 'text/html' --> Nil) is export {
    content $content-type, render-template($template, $initial-topic);
}

multi template($template, :$content-type = 'text/html' --> Nil) is export {
    template($template, Nil, :$content-type);
}
