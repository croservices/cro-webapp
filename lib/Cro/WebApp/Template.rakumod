use Cro::HTTP::Router :DEFAULT, :plugin, :resource-plugin;
use Cro::WebApp::Template::Location;
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

# Another router plugin is used for data providers for template parts. This will
# will have a hash per route block, mapping part names into providers.
my $template-part-plugin = router-plugin-register("template-part");

#| Render the template at the specified path using the specified data, and
#| return the result as a C<Str>.
multi render-template(IO::Path $template-path, $initial-topic, :%parts --> Str) is export {
    my $compiled-template = await get-template-repository.resolve-absolute($template-path.absolute);
    Cro::WebApp::LogTimeline::RenderTemplate.log: :template($template-path), {
        render-internal($compiled-template, $initial-topic, %parts)
    }
}

#| Render the template at the specified path, which will be resolved either in the
#| resources or via the file system, as configured by C<template-location> or
#| C<templates-from-resources>.
multi render-template(Str $template, $initial-topic, :%parts --> Str) is export {
    # Gather the route-specific locations and turn them into location descriptors
    # for the resolver to use.
    my @route-locations := try { router-plugin-get-configs($template-location-plugin) } // ();
    my Cro::WebApp::Template::Location @locations = @route-locations.map: {
        when TemplateResourcesLocation {
            my &resource-resolver = route-resource-resolver(error-sub => 'render-template');
            Cro::WebApp::Template::Location::Resource.new(:prefix(.prefix), :&resource-resolver)
        }
        when TemplateFileSystemLocation {
            Cro::WebApp::Template::Location::FileSystem.new(:location(.location))
        }
        default {
            Empty
        }
    }

    # Use the template repository to do the resolution.
    my $repo = get-template-repository;
    my $compiled-template = await $repo.resolve($template, @locations);

    # Finally, render it.
    Cro::WebApp::LogTimeline::RenderTemplate.log: :$template, {
        render-internal($compiled-template, $initial-topic, %parts)
    }
}

sub render-internal($compiled-template, $initial-topic, %parts) {
    my $*CRO-TEMPLATE-MAIN-PART := $initial-topic;
    my %*CRO-TEMPLATE-EXPLICIT-PARTS := %parts;
    my %*WARNINGS;
    my $result = $compiled-template.render($initial-topic);
    if %*WARNINGS {
        for %*WARNINGS.kv -> $text, $number {
            warn "$text ($number time{ $number == 1 ?? '' !! 's' })";
        }
    }
    $result;
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

#| Thrown when a template part provider is registered in a C<route> block that
#| is identical to an existing part provider for the same name.
class X::Cro::WebApp::Template::DuplicatePartProvider is Exception {
    has Str $.name is required;
    method message() {
        "Duplicate template-part provider for '$!name'"
    }
}

#| Thrown when a part provider has an unsupported signature (anything other than a
#| single authorization parameter is reserved).
class X::Cro::WebApp::Template::BadPartProviderParameters is Exception {
    method message() {
        "A template-part provider should have either no parameters or a single parameter of type Cro::HTTP::Auth or marked with the `is auth` trait"
    }
}

#| Specify a data provider for a template part. Parts are typically used for
#| common page elements that appear on all or many pages and need some data.
#| For example, a page header may wish to show the name of the currently logged
#| in user. The part provider may either take zero or one arguments; the one
#| argument must either be of type C<Cro::HTTP::Auth> or marked with the `is auth`
#| trait, and will be passed the value of `request.auth` so long as it matches
#| any type constraint. This allows, for example, writing different providers for
#| logged in and not logged in users.
sub template-part(Str $name, &provider --> Nil) is export {
    # We use a hash per route block to store the parts that it contributes.
    my @current-configs = router-plugin-get-innermost-configs($template-part-plugin);
    my %parts := do if @current-configs {
        @current-configs[0]
    }
    else {
        my Array %new-hash;
        router-plugin-add-config($template-part-plugin, %new-hash);
        %new-hash
    }

    # It must be either zero arity or arity one but expecting a Cro::Auth of
    # some kind.
    my $signature = &provider.signature;
    if $signature.arity == 1 {
        my Parameter $param = $signature.params[0];
        unless $param ~~ Cro::HTTP::Router::Auth || $param.type ~~ Cro::HTTP::Auth {
            die X::Cro::WebApp::Template::BadPartProviderParameters.new;
        }
    }
    elsif $signature.arity > 1 {
        die X::Cro::WebApp::Template::BadPartProviderParameters.new;
    }

    # Detect conflicts. It is allowed to have multiple so long as they have
    # distinct signatures.
    if %parts{$name} -> @existing {
        if any(@existing).signature eqv $signature {
            die X::Cro::WebApp::Template::DuplicatePartProvider.new(:$name);
        }
    }

    # All is well, so add the part.
    %parts{$name}.push(&provider);
}

#| Used in a Cro::HTTP::Router route handler to render a template and set it as
#| the response body. The initial topic is passed to the template to render. The
#| content type will default to text/html, but can be set explicitly also.
multi template($template, $initial-topic, :%parts, :$content-type = 'text/html' --> Nil) is export {
    my @*CRO-TEMPLATE-PART-PROVIDERS := router-plugin-get-configs($template-part-plugin, error-sub => 'template');
    content $content-type, render-template($template, $initial-topic, :%parts);
}

#| Used in a Cro::HTTP::Router route handler to render a template and set it as
#| the response body. The content type will default to text/html, but can be set
#| explicitly also.
multi template($template, :%parts, :$content-type = 'text/html' --> Nil) is export {
    template($template, Nil, :%parts, :$content-type);
}
