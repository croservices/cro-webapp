use Cro::HTTP::Body;
use Cro::HTTP::MultiValue;

#| A role to be mixed in to Attribute to hold extra form-related properties.
my role FormProperties {
    has Bool $.webapp-form-is-password is rw;
    has Hash $.webapp-form-multiline is rw;
    has Block $.webapp-form-select is rw;
}

#| Ensure that the attribute has the FormProperties mixin.
sub ensure-attr-state(Attribute $attr --> Nil) {
    unless $attr ~~ FormProperties {
        $attr does FormProperties;
    }
}

#| Indicate that this is a password form field
multi trait_mod:<is>(Attribute:D $attr, :$password! --> Nil) is export {
    ensure-attr-state($attr);
    $attr.webapp-form-is-password = True;
}

#| Indicate that this is a multi-line form field. Optionally, the number of
#| rows and cols can be provided.
multi trait_mod:<is>(Attribute:D $attr, :$multiline! --> Nil) is export {
    ensure-attr-state($attr);
    my %multiline = $multiline ~~ List && all($multiline) ~~ Pair ?? $multiline.hash !! ();
    with %multiline.keys.first(* !~~ 'rows' | 'cols') {
        die "Unknown option '$_' for multiline trait on attribute '$attr.name()'";
    }
    $attr.webapp-form-multiline = %multiline;
}

#| Provide code that will be run in order to produce the values to select from. Should
#| return a list of Pair objects, where the key is the selected value and the value is
#| the text to display. If non-Pairs are in the list, a Pair with the same key and value
#| will be formed from them.
multi trait_mod:<will>(Attribute:D $attr, &block, :$select! --> Nil) is export {
    ensure-attr-state($attr);
    $attr.webapp-form-select = &block;
}

#| A role to be composed into Cro web application form objects, providing the key form
#| functionality.
role Cro::WebApp::Form {
    #| We cache the render data, in case it is asked for multiple times.
    has $!cached-render-data;

    #| Create an empty instance of the form without any data in it.
    method empty() {
        self.CREATE
    }

    #| Take a application/x-www-form-urlencoded body and populate the form values based
    #| upon it.
    multi method parse(Cro::HTTP::Body::WWWFormUrlEncoded $body) {
        my %form-data := $body.hash;
        my %values;
        for self.^attributes.grep(*.has_accessor) -> Attribute $attr {
            my $name = $attr.name.substr(2);
            my $value := %form-data{$name};
            if $attr.type ~~ Positional {
                my $value-type = $attr.type.of;
                my @values := $value ~~ Cro::HTTP::MultiValue ?? $value.list !!
                        $value.defined ?? ($value,) !! ();
                %values{$name} := @values.map({ self!parse-one-value($value-type, $_) }).list;
            }
            else {
                %values{$name} := self!parse-one-value($attr.type, $value);
            }
        }
        self.bless(|%values)
    }

    method !parse-one-value(Mu $declared-type, Mu $value) {
        my $type = Any ~~ $declared-type ?? Str !! $declared-type;
        given $type {
            when Str {
                $value.defined ?? $value.Str !! ''
            }
            when Bool {
                ?$value
            }
        }
    }

    #| Produce a description of the form and its content for use in rendering
    #| the form to HTML.
    method HTML-RENDER-DATA(--> Hash) {
        .return with $!cached-render-data;
        my @controls;
        for self.^attributes.grep(*.has_accessor) -> Attribute $attr {
            my ($control-type, %properties) = self!calculate-control-type($attr);
            my %control =
                    name => $attr.name.substr(2),
                    label => self!calculate-label($attr),
                    required => ?$attr.required,
                    type => $control-type,
                    %properties;
            @controls.push(%control);
        }
        return $!cached-render-data := { :@controls };
    }

    method !calculate-control-type(Attribute $attr) {
        # See if we've been explicitly told what it is.
        with $attr.?webapp-form-is-password {
            ensure-acceptable-type($attr);
            return 'password';
        }
        with $attr.?webapp-form-select {
            my %properties = options => self!calculate-options($attr, $_);
            if $attr.type ~~ Positional {
                ensure-acceptable-type($attr, $attr.type.of);
                %properties<multi> = True;
            }
            else {
                ensure-acceptable-type($attr);
                %properties<multi> = False;
            }
            return 'select', %properties;
        }
        with $attr.?webapp-form-multiline {
            ensure-acceptable-type($attr);
            return 'textarea', self!add-current-value($attr, $_);
        }

        # Otherwise, go by type; booleans become checkboxes, and Str, numeric, or untyped
        # become basic inputs.
        if $attr.type ~~ Bool {
            return 'checkbox', self!add-current-value($attr);
        }
        ensure-acceptable-type($attr);
        return 'text', self!add-current-value($attr);
    }

    method !add-current-value(Attribute $attr, %properties? is copy) {
        with $attr.get_value(self) {
            %properties<value> = $_;
        }
        return %properties;
    }

    method !calculate-options(Attribute $attr, &option-producer) {
        my @current := $attr.get_value(self).list;
        [option-producer(self).list.map: -> $opt {
            my ($key, $value);
            if $opt ~~ Pair {
                $key = $opt.key;
                $value = $opt.value;
            }
            else {
                $key = $value = $opt;
            }
            $value (elem) @current ?? ($key, $value, True) !! ($key, $value)
        }]
    }

    multi sub ensure-acceptable-type(Attribute $attr --> Nil) {
        ensure-acceptable-type($attr, $attr.type);
    }
    multi sub ensure-acceptable-type(Attribute $attr, $type --> Nil) {
        unless $type ~~ Str || $type ~~ Real || Any ~~ $type {
            die "Don't know how to handle type '$type.^name()' of '$attr.name()' in a form";
        }
    }

    method !calculate-label($attr) {
        # Fall back to mangling the attribute name.
        my @words = $attr.name.substr(2).split('-');
        @words[0] .= tclc;
        @words.join(' ')
    }
}

#| Take the submitted data in the request body and parse it into a form object of
#| the type specified in the callback. Example use: form-data -> BlogPost $form { }
sub form-data(&handler --> Nil) is export {
    use Cro::HTTP::Router;
    my @params = &handler.signature.params;
    if @params.elems != 1 {
        die "form-data requires a block taking a single parameter";
    }
    my $form-type = @params[0].type;
    if $form-type =:= Mu {
        die "The form-data block parameter must specify the expected form type";
    }
    unless $form-type ~~ Cro::WebApp::Form {
        die "The form-data block parameter is of type $form-type.^name(), which does not " ~
                "do the Cro::WebApp::Form role";
    }
    request-body -> $body {
        handler($form-type.parse($body));
    }
}
