use Cro::HTTP::Router :DEFAULT, :plugin, :resource-plugin;
use Cro::WebApp::LogTimelineSchema;
use Cro::WebApp::Template::Repository;

# We'll use a router plugin to keep track of route block template locations,
# either from the file system or from resources.
my $template-location-plugin = router-plugin-register("template-locations");
my class TemplateFileSystemLocation {
    has IO::Path $.location is required;
}
my class TemplateResourcesLocation {
    has Str $.prefix is required;
}

#| Render the template at the specified path using the specified data, and
#| return the result as a C<Str>.
multi render-template(IO::Path $template-path, $initial-topic --> Str) is export {
    my $compiled-template = await get-template-repository.resolve-absolute($template-path.absolute);
    Cro::WebApp::LogTimeline::RenderTemplate.log: :template($template-path), {
        $compiled-template.render($initial-topic)
    }
}

#| Render the template at the specified path, which will be resolved either in the
#| resources or via the file system, as configured by C<template-location> or
#| C<templates-from-resources>.
multi render-template(Str $template, $initial-topic --> Str) is export {
    # First try to resolve it using the the route-specific locations.
    my $repo = get-template-repository;
    my @locations := try { router-plugin-get-configs($template-location-plugin) } // ();
    my $compiled-template;
    for @locations {
        when TemplateResourcesLocation {
            my $name = .prefix
                    ?? .prefix ~ (.prefix.ends-with('/') ?? '' !! '/') ~ $template
                    !! $template;
            with resolve-route-resource($name, error-sub => 'render-template') {
                $compiled-template = await $repo.resolve-absolute(.absolute.IO);
                last;
            }
        }
        when TemplateFileSystemLocation {
            my $file = .location.add($template);
            if $file.e && $file.f {
                $compiled-template = await $repo.resolve-absolute($file.absolute.IO);
                last;
            }
        }
    }

    # Fall back on the resolving it with the template repository globals.
    $compiled-template //= await $repo.resolve($template);

    # Finally, render it.
    Cro::WebApp::LogTimeline::RenderTemplate.log: :$template, {
        $compiled-template.render($initial-topic)
    }
}

#| Add a file system path to search for templates. This will be used by both the
#| C<template> and C<render-template> functions. If placed inside of a C<route>
#| block, the location will only be applicable to routes inside of that block.
#| If not, it will have global effect.
#|
#| If the compile-all flag is passed, then all of the templates will be compiled up
#| front before the function returns. Otherwise, they will be compiled on first use.
#| If using compile-all, a test parameter can be set to limit the templates to
#| compile. By default it will exclude entries whose name has a leading dot (a
#| "hidden" file in a UNIX system). This can be overridden if necessary by setting
#| the test parameter to *.
sub template-location(IO() $location, :$compile-all, :$test = { .IO.basename !~~ / ^ '.' / } --> Nil) is export {
    my $template-repo = get-template-repository;
    try {
        # First try to add it locally.
        router-plugin-add-config $template-location-plugin,
                TemplateFileSystemLocation.new(:$location);
        CATCH {
            when X::Cro::HTTP::Router::OnlyInRouteBlock {
                # Failed locally, so do it globally.
                $template-repo.add-global-location($location);
            }
        }
    }

    compile-dir($template-repo, $location, :$test) if $compile-all;
}

sub compile-dir(Cro::WebApp::Template::Repository $template-repo, IO::Path $location, :$test --> Nil) {
    for dir($location).grep($test) {
        when .f {
            await $template-repo.resolve-absolute($_);
        }
        when .d {
            compile-dir($template-repo, $_, :$test);
        }
    }
}

#| Specify that calls to C<template> or C<render-template> in the current
#| C<route> block should be taken from the resources. The resources must have
#| already been associated with the C<route> block using C<resources-from>.
#| The optional prefix will be prepended to the template name; this is useful
#| if there are many resources, and all templates are in a particular location.
sub templates-from-resources(:$prefix = '' --> Nil) is export {
    router-plugin-add-config $template-location-plugin,
            TemplateResourcesLocation.new(:$prefix),
            error-sub => 'templates-from-resources';
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
