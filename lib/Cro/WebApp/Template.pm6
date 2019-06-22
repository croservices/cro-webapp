use Cro::HTTP::Router;
use Cro::WebApp::Template::Repository;

multi render-template(IO::Path $template-path, $initial-topic) is export {
    (await get-template-repository.resolve-absolute($template-path.absolute)).render($initial-topic)
}

multi render-template(Str $template, $initial-topic) is export {
    (await get-template-repository.resolve($template)).render($initial-topic);
}

sub template-location(IO() $location --> Nil) is export {
    get-template-repository.add-location($location);
}

multi template($template, $initial-topic, :$content-type = 'text/html' --> Nil) is export {
    content $content-type, render-template($template, $initial-topic);
}

multi template($template, :$content-type = 'text/html' --> Nil) is export {
    template($template, Nil, :$content-type);
}
