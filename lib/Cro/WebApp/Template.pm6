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
