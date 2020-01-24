use Cro::HTTP::Body;
use Cro::HTTP::MultiValue;

#| A role to be mixed in to Attribute to hold extra form-related properties.
my role FormProperties {
    has Str $.webapp-form-type is rw;
    has Hash $.webapp-form-multiline is rw;
    has Block $.webapp-form-select is rw;
    has Int $.webapp-form-minlength is rw;
    has Int $.webapp-form-maxlength is rw;
    has Real $.webapp-form-min is rw;
    has Real $.webapp-form-max is rw;
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
    $attr.webapp-form-type = 'password';
}

#| Indicate that this is a number form field
multi trait_mod:<is>(Attribute:D $attr, :$number! --> Nil) is export {
    ensure-attr-state($attr);
    $attr.webapp-form-type = 'number';
}

#| Indicate that this is a color form field
multi trait_mod:<is>(Attribute:D $attr, :$color! --> Nil) is export {
    ensure-attr-state($attr);
    $attr.webapp-form-type = 'color';
}

#| Indicate that this is a date form field
multi trait_mod:<is>(Attribute:D $attr, :$date! --> Nil) is export {
    ensure-attr-state($attr);
    $attr.webapp-form-type = 'date';
}

#| Indicate that this is a local date/time form field
multi trait_mod:<is>(Attribute:D $attr, :datetime(:$datetime-local)! --> Nil) is export {
    ensure-attr-state($attr);
    $attr.webapp-form-type = 'datetime-local';
}

#| Indicate that this is an email form field
multi trait_mod:<is>(Attribute:D $attr, :$email! --> Nil) is export {
    ensure-attr-state($attr);
    $attr.webapp-form-type = 'email';
}

#| Indicate that this is a month form field
multi trait_mod:<is>(Attribute:D $attr, :$month! --> Nil) is export {
    ensure-attr-state($attr);
    $attr.webapp-form-type = 'month';
}

#| Indicate that this is a telephone form field
multi trait_mod:<is>(Attribute:D $attr, :telephone(:$tel)! --> Nil) is export {
    ensure-attr-state($attr);
    $attr.webapp-form-type = 'tel';
}

#| Indicate that this is a search form field
multi trait_mod:<is>(Attribute:D $attr, :$search! --> Nil) is export {
    ensure-attr-state($attr);
    $attr.webapp-form-type = 'search';
}

#| Indicate that this is a time form field
multi trait_mod:<is>(Attribute:D $attr, :$time! --> Nil) is export {
    ensure-attr-state($attr);
    $attr.webapp-form-type = 'time';
}

#| Indicate that this is a URL form field
multi trait_mod:<is>(Attribute:D $attr, :$url! --> Nil) is export {
    ensure-attr-state($attr);
    $attr.webapp-form-type = 'url';
}

#| Indicate that this is a week form field
multi trait_mod:<is>(Attribute:D $attr, :$week! --> Nil) is export {
    ensure-attr-state($attr);
    $attr.webapp-form-type = 'week';
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

#| Set the minimum length of an input field
multi trait_mod:<is>(Attribute:D $attr, Int :min-length(:$minlength)! --> Nil) is export {
    ensure-attr-state($attr);
    $attr.webapp-form-minlength = $minlength;
}

#| Set the maximum length of an input field
multi trait_mod:<is>(Attribute:D $attr, Int :max-length(:$maxlength)! --> Nil) is export {
    ensure-attr-state($attr);
    $attr.webapp-form-maxlength = $maxlength;
}

#| Set the minimum numeric value of an input field
multi trait_mod:<is>(Attribute:D $attr, Real :$min! --> Nil) is export {
    ensure-attr-state($attr);
    $attr.webapp-form-min = $min;
}

#| Set the maximum numeric value of an input field
multi trait_mod:<is>(Attribute:D $attr, Real :$max! --> Nil) is export {
    ensure-attr-state($attr);
    $attr.webapp-form-max = $max;
}

#| Provide code that will be run in order to produce the values to select from. Should
#| return a list of Pair objects, where the key is the selected value and the value is
#| the text to display. If non-Pairs are in the list, a Pair with the same key and value
#| will be formed from them.
multi trait_mod:<will>(Attribute:D $attr, &block, :$select! --> Nil) is export {
    ensure-attr-state($attr);
    $attr.webapp-form-select = &block;
}

#| The set of validation issues relating to a form.
class Cro::WebApp::Form::ValidationState {
    has @!failures;

    #| Adds an error indicating that a required value is missing.
    method add-value-missing-error(Str $input --> Nil) {
        @!failures.push: 'XXX';
    }

    #| Adds an error indicating that a value is too short.
    method add-too-short-error(Str $input --> Nil) {
        @!failures.push: 'XXX';
    }

    #| Adds an error indicating that a value is too long.
    method add-too-long-error(Str $input --> Nil) {
        @!failures.push: 'XXX';
    }

    #| Check if the form is valid. If there are validation failures, this
    #| returns False.
    method is-valid(--> Bool) {
        not @!failures
    }
}

#| A role to be composed into Cro web application form objects, providing the key form
#| functionality.
role Cro::WebApp::Form {
    #| Cached rendered data, in case it is asked for multiple times.
    has $!cached-render-data;

    #| Computed validation state.
    has Cro::WebApp::Form::ValidationState $!validation-state;

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
        with $attr.?webapp-form-type {
            # Some of these are are special, some not just text-like.
            when 'number' {
                return self!calculate-numeric-control-type($attr);
            }
            when 'email' | 'search' | 'tel' | 'url' {
                ensure-acceptable-type($attr);
                return self!calculate-text-control-type($attr, $_);
            }
            default {
                ensure-acceptable-type($attr);
                return $_;
            }
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
            return self!calculate-text-control-type($attr, 'textarea', $_);
        }

        # Otherwise, look at the type-specific cases; booleans become checkboxes, and
        # numerics become number.
        unless $attr.type =:= Mu {
            if $attr.type ~~ Bool {
                return 'checkbox', self!add-current-value($attr);
            }
            if $attr.type ~~ Real {
                return self!calculate-numeric-control-type($attr);
            }
        }

        # Otherwise, we're looking at a text property.
        ensure-acceptable-type($attr);
        return self!calculate-text-control-type($attr);
    }

    method !calculate-text-control-type(Attribute $attr, $type = 'text', %properties? is copy) {
        with $attr.?webapp-form-minlength {
            %properties<minlength> = ~$_;
        }
        with $attr.?webapp-form-maxlength {
            %properties<maxlength> = ~$_;
        }
        return $type, self!add-current-value($attr, %properties)
    }

    method !calculate-numeric-control-type(Attribute $attr) {
        my %min-max;
        with $attr.?webapp-form-min {
            %min-max<min> = ~$_;
        }
        with $attr.?webapp-form-max {
            %min-max<max> = ~$_;
        }
        return 'number', self!add-current-value($attr, %min-max);
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
    multi sub ensure-acceptable-type(Attribute $attr, Mu $type --> Nil) {
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

    #| Checks if the form meets all validation constraints. Returns Ture if so.
    method is-valid(--> Bool) {
        self!ensure-validation-state();
        $!validation-state.is-valid
    }

    method !ensure-validation-state(--> Nil) {
        # If we already calculated the validation state, don't do it again.
        return with $!validation-state;

        # Add per field validation errors.
        $!validation-state .= new;
        for self.^attributes.grep(*.has_accessor) -> Attribute $attr {
            my $name = $attr.name.substr(2);
            my $value = $attr.get_value(self);
            my $type = $attr.type;

            if $attr.required {
                my $is-set = do given $type {
                    when Str { $value.defined && $value.trim ne '' }
                    when Positional { $value.elems > 0 }
                    default { $value.defined }
                }
                unless $is-set {
                    # Don't validate this attribute further if it's missing.
                    $!validation-state.add-value-missing-error($name);
                    next;
                }
            }

            with $attr.?webapp-form-minlength -> $min {
                if $value.defined && $value ne '' {
                    if $value.chars < $min {
                        $!validation-state.add-too-short-error($name);
                        next;
                    }
                }
            }
            with $attr.?webapp-form-maxlength -> $max {
                if $value.defined && $value ne '' {
                    if $value.chars > $max {
                        $!validation-state.add-too-long-error($name);
                        next;
                    }
                }
            }
        }
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
