use Cro::HTTP::Body;
use Cro::HTTP::MultiValue;

#| A role to be mixed in to Attribute to hold extra form-related properties.
my role FormProperties {
    has $.webapp-form-label is rw;
    has $.webapp-form-placeholder is rw;
    has $.webapp-form-help is rw;
    has Str $.webapp-form-type is rw;
    has Hash $.webapp-form-multiline is rw;
    has Block $.webapp-form-select is rw;
    has Int $.webapp-form-minlength is rw;
    has Int $.webapp-form-maxlength is rw;
    has Real $.webapp-form-min is rw;
    has Real $.webapp-form-max is rw;
    has Bool $.webapp-form-ro is rw;
    has List @.webapp-form-validations;
}

#| Ensure that the attribute has the FormProperties mixin.
sub ensure-attr-state(Attribute $attr --> Nil) {
    unless $attr ~~ FormProperties {
        $attr does FormProperties;
    }
}

#| Customize the label for the form field (without this, the attribute name will be used
#| to generate a label).
multi trait_mod:<is>(Attribute:D $attr, :$label! --> Nil) is export {
    ensure-attr-state($attr);
    $attr.webapp-form-label = $label;
}

#| Provide placeholder text for a form field.
multi trait_mod:<is>(Attribute:D $attr, :$placeholder! --> Nil) is export {
    ensure-attr-state($attr);
    $attr.webapp-form-placeholder = $placeholder;
}

#| Provide help text for a form field.
multi trait_mod:<is>(Attribute:D $attr, :$help! --> Nil) is export {
    ensure-attr-state($attr);
    $attr.webapp-form-help = $help;
}

#| Indicate that this is a hidden form field
multi trait_mod:<is>(Attribute:D $attr, :$hidden! --> Nil) is export {
    ensure-attr-state($attr);
    $attr.webapp-form-type = 'hidden';
}

#| Indicate that this is a file form field
multi trait_mod:<is>(Attribute:D $attr, :$file! --> Nil) is export {
    ensure-attr-state($attr);
    $attr.webapp-form-type = 'file';
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

multi trait_mod:<is>(Attribute:D $attr, Bool :$form-read-only! --> Nil) is export {
    ensure-attr-state($attr);
    $attr.webapp-form-ro = $form-read-only;
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

#| Describe how a field is validated. Two arguments are expected to the
#| trait: something the value will be smart-matched against, and the
#| error message for if the validation fails.
multi trait_mod:<is>(Attribute:D $attr, :$validated! --> Nil) is export {
    ensure-attr-state($attr);
    unless $validated ~~ List && $validated.elems == 2 {
        die "Trait 'is validated' on attribute '$attr.name()' requires two arguments " ~
                "(one to smart-match the value against, one with the error message)";
    }
    $attr.webapp-form-validations.push($validated);
}

#| The set of validation issues relating to a form.
class Cro::WebApp::Form::ValidationState {
    enum Problem <
        BadInput CustomError RangeOverflow RangeUnderflow
        StepMismatch TooLong TooShort TypeMismatch ValueMissing
    >;

    class Error {
        has Str $.input is required;
        has Problem $.problem is required;
        has $.message;
    }

    has Error @.errors;

    #| Adds an error indicating that a required value is missing.
    method add-value-missing-error(Str $input --> Nil) {
        @!errors.push: Error.new(:$input, :problem(ValueMissing));
    }

    #| Adds an error indicating that a value is too short.
    method add-too-short-error(Str $input --> Nil) {
        @!errors.push: Error.new(:$input, :problem(TooShort));
    }

    #| Adds an error indicating that a value is too long.
    method add-too-long-error(Str $input --> Nil) {
        @!errors.push: Error.new(:$input, :problem(TooLong));
    }

    #| Adds an error indicating that a value was greater than the allowed
    #| maximum.
    method add-range-overflow-error(Str $input --> Nil) {
        @!errors.push: Error.new(:$input, :problem(RangeOverflow));
    }

    #| Adds an error indicating that a value was less than the allowed
    #| minimum.
    method add-range-underflow-error(Str $input --> Nil) {
        @!errors.push: Error.new(:$input, :problem(RangeUnderflow));
    }

    #| Adds an error indicating that a value is a bad input (could not be parsed into
    #| the desired type).
    method add-bad-input-error(Str $input --> Nil) {
        @!errors.push: Error.new(:$input, :problem(BadInput));
    }

    #| Add a custom validation error on a particular field.
    multi method add-custom-error(Str $input, $message --> Nil) {
        @!errors.push: Error.new(:$input, :problem(CustomError), :$message);
    }

    #| Add a form-level error (one not connected to a particular field).
    multi method add-custom-error($message --> Nil) {
        @!errors.push: Error.new(:input(Str), :problem(CustomError), :$message);
    }

    #| Check if the form is valid. If there are validation failures, this
    #| returns False.
    method is-valid(--> Bool) {
        not @!errors
    }
}

#| A role to be composed into Cro web application form objects, providing the key form
#| functionality.
role Cro::WebApp::Form {
    #| The CSRF token hidden field name and cookie name.
    my constant CSRF-TOKEN-NAME = '__CSRF_TOKEN';

    #| Cached rendered data, in case it is asked for multiple times.
    has $!cached-render-data;

    #| Computed validation state.
    has Cro::WebApp::Form::ValidationState $!validation-state;

    #| Unparseable values (for if a form was submitted with a value that could not be
    #| parsed into the required type).
    has %!unparseable;

    #| The received CSRF token.
    has Str $!received-csrf-token;

    #| Create an empty instance of the form without any data in it.
    method empty() {
        self.CREATE
    }

    #| Return the form data as a hash
    method form-data() {
        my %values;
        for self.^attributes.grep(*.has_accessor) -> Attribute $attr {
            my $name = $attr.name.substr(2);
            %values{$name} = $attr.get_value(self);
        }
        %values
    }

    my subset Form where Cro::HTTP::Body::WWWFormUrlEncoded | Cro::HTTP::Body::MultiPartFormData;

    multi sub get-value(Cro::HTTP::Body::MultiPartFormData::Part $p) { $p.body-blob.decode('utf-8') }
    multi sub get-value($s) { $s }

    #| Take a application/x-www-form-urlencoded or multipart/form-data body and populate the form values based
    #| upon it.
    multi method parse(Form $body) {
        my %form-data := $body.hash;
        my %values;
        my %unparseable;

        for self.^attributes.grep(*.has_accessor) -> Attribute $attr {
            my $name = $attr.name.substr(2);
            my $value := %form-data{$name};

            if $attr.type ~~ Positional {
                my $value-type = $attr.type.of;
                my @values := $value ~~ Cro::HTTP::MultiValue ?? $value.list !!
                        $value.defined ?? (get-value($value),) !! ();
                %values{$name} := @values.map({ self!parse-one-value($name, $value-type, $_, %unparseable) }).list;
            }
            elsif defined($attr.?webapp-form-type) and $attr.webapp-form-type eq 'file' {
                if $body ~~ Cro::HTTP::Body::MultiPartFormData {
                    %values{$name} = %form-data{$name};
                } else {
                    %unparseable{$name} = "Invalid";
                    %values{$name} = Nil;
                }
            } else {
                %values{$name} := self!parse-one-value($name, $attr.type, get-value($value), %unparseable);
            }
        }
        given self.bless(|%values) -> Cro::WebApp::Form $parsed {
            for %unparseable.kv -> $input, $value {
                $parsed.add-unparseable-form-value($input, $value);
            }
            with $body{CSRF-TOKEN-NAME} {
                my $csrf-token = get-value($_);
                $parsed.set-received-csrf-token($csrf-token);
            }
            $parsed
        }
    }

    method !parse-one-value(Str $name, Mu $declared-type, Mu $value, %unparseable) {
        my $type = Any ~~ $declared-type ?? Str !! $declared-type;
        given $type {
            when Str {
                $value.defined ?? $value.Str !! ''
            }
            when Bool {
                ?$value
            }
            when Int {
                $value.defined
                        ?? ($value.Int // unparseable($name, $value, %unparseable, Int))
                        !! Int
            }
            when Num {
                $value.defined
                        ?? ($value.Num // unparseable($name, $value, %unparseable, Num))
                        !! Num
            }
            when Rat {
                $value.defined
                        ?? ($value.Rat // unparseable($name, $value, %unparseable, Rat))
                        !! Rat
            }
            when Date {
                $value.defined
                        ?? (Date.new($value) // unparseable($name, $value, %unparseable, Date))
                        !! Date
            }
            when DateTime {
                $value.defined
                        ?? (DateTime.new($value) // unparseable($name, $value, %unparseable, DateTime))
                        !! DateTime
            }
            default {
                die "Don't know how to parse form data into a $type.^name()";
            }
        }
    }

    sub unparseable(Str $name, Str $value, %unparseable, $void) {
        %unparseable{$name} = $value;
        $void
    }

    #| Sets the CSRF token that was received in the form.
    method set-received-csrf-token(Str $!received-csrf-token --> Nil) {}

    #| Produce a description of the form and its content for use in rendering
    #| the form to HTML.
    method HTML-RENDER-DATA(--> Hash) {
        .return with $!cached-render-data;
        my @controls;
        my %validation-by-control;
        with $!validation-state {
            for .errors {
                %validation-by-control{.input // ''}.push($_);
            }
        }
        for self.^attributes.grep(*.has_accessor) -> Attribute $attr {
            my ($control-type, %properties) = self!calculate-control-type($attr);
            my $name = $attr.name.substr(2);
            my %control =
                    :$name,
                    label => self!calculate-label($attr),
                    (with $attr.?webapp-form-help { help => $_ }),
                    (with $attr.?webapp-form-placeholder { placeholder => $_ }),
                    required => ?$attr.required,
                    type => $control-type,
                    read-only => $attr.?webapp-form-ro,
                    %properties;
            if %validation-by-control{$name} -> @errors {
                self!set-control-validation(%control, @errors)
            }
            @controls.push(%control);
        }
        self!add-csrf-protection(@controls);
        my %enctype = any(self.^attributes.map(*.?webapp-form-type).grep(*.defined)) eq 'file' ?? enctype => "multipart/form-data" !! Empty;
        my %rendered := { :@controls, was-validated => $!validation-state.defined, |%enctype };
        if %validation-by-control{''} -> @errors {
            %rendered<validation-errors> = [@errors.map(*.message)];
        }
        return $!cached-render-data := %rendered;
    }

    method !calculate-control-type(Attribute $attr) {
        # See if we've been explicitly told what it is.
        with $attr.?webapp-form-type {
            # Some of these are are special, some not just text-like.
            when 'number' {
                return self!calculate-numeric-control-type($attr);
            }
            when 'email' | 'search' | 'tel' | 'url' | 'password' {
                ensure-acceptable-type($attr);
                return self!calculate-text-control-type($attr, $_);
            }
            default {
                ensure-acceptable-type($attr);
                return $_, self!add-current-value($attr);
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
            if $attr.type ~~ Date {
                return 'date', self!add-current-value($attr);
            }
            if $attr.type ~~ DateTime {
                return 'datetime-local', self!add-current-value($attr);
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
            when Date { %properties<value> = .yyyy-mm-dd; }

            when DateTime { %properties<value> .= Str }

            default { %properties<value> = $_; }
        }
        orwith %!unparseable{$attr.name.substr(2)} {
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
        unless $type ~~ Str || $type ~~ Real || $type ~~ Date || $type ~~ DateTime || Any ~~ $type {
            die "Don't know how to handle type '$type.^name()' of '$attr.name()' in a form";
        }
    }

    method !calculate-label($attr) {
        with $attr.?webapp-form-label {
            # Explicitly provided label
            $_
        }
        else {
            # Fall back to mangling the attribute name.
            my @words = $attr.name.substr(2).split('-');
            @words[0] .= tclc;
            @words.join(' ')
        }
    }

    #| Add validation errors to a control.
    method !set-control-validation(%control, @errors --> Nil) {
        # TODO i18n support
        my @messages;
        for @errors -> $error {
            @messages.push: do with $error.message {
                $_
            }
            else {
                given $error.problem {
                    when Cro::WebApp::Form::ValidationState::Problem::ValueMissing {
                        'Please fill in this field'
                    }
                    when Cro::WebApp::Form::ValidationState::Problem::RangeOverflow {
                        "Must not be greater than %control<max>"
                    }
                    when Cro::WebApp::Form::ValidationState::Problem::RangeUnderflow {
                        "Must not be less than %control<min>"
                    }
                    when Cro::WebApp::Form::ValidationState::Problem::TooLong {
                        "Must not be longer than %control<maxlength> characters"
                    }
                    when Cro::WebApp::Form::ValidationState::Problem::TooShort {
                        "Must not be shorter than %control<minlength> characters"
                    }
                    default {
                        given %control<type> // '' {
                            when 'email' { 'Must be an email address' }
                            when 'number' { 'Must be a number' }
                            when 'url' { 'Must be a URL' }
                            default { 'This value is not appropriate' }
                        }
                    }
                }
            }
        }
        %control<validation-errors> = @messages;
    }

    #| Adds CSRF protection if we've a visible request/response.
    method !add-csrf-protection(@controls) {
        use Cro::HTTP::Cookie;
        use Cro::HTTP::Router;
        with try response -> Cro::HTTP::Response $response {
            my $token = $response.request.cookie-value(CSRF-TOKEN-NAME) //
                    $response.cookies.first(*.name eq CSRF-TOKEN-NAME).?value;
            without $token {
                my constant @CHARS = flat 'A'..'Z', 'a'..'z', '0'..'9';
                $token = @CHARS.roll(64).join;
                try $response.set-cookie(CSRF-TOKEN-NAME, $token, path => '/');
            }
            @controls.unshift: {
                name => CSRF-TOKEN-NAME,
                type => 'hidden',
                value => $token
            };
        }
    }

    #| Generate a default name for this form.
    method GENERATE-NAME() {
        self.^shortname
    }

    #| Stores a string value for a form input that could not be parsed into the desired
    #| data type, for the purpose of validation.
    method add-unparseable-form-value(Str $input, Str $value --> Nil) {
        %!unparseable{$input} = $value;
    }

    #| Checks if the form meets all validation constraints. Returns Ture if so.
    method is-valid(--> Bool) {
        self.validation-state.is-valid
    }

    #| Get the validation state of the form.
    method validation-state(--> Cro::WebApp::Form::ValidationState) {
        self!ensure-validation-state();
        $!validation-state
    }

    method !ensure-validation-state(--> Nil) {
        # If we already calculated the validation state, don't do it again.
        return with $!validation-state;

        # Add any CSRF errors.
        $!validation-state .= new;
        self!check-csrf-token();

        # Add per field validation errors.
        for self.^attributes.grep(*.has_accessor) -> Attribute $attr {
            my $name = $attr.name.substr(2);
            my $value = $attr.get_value(self);
            my $type = $attr.type;
            $type = Str if Any ~~ $type;

            # We check for unparseables first, so we don't have to consider them in any
            # further validation logic.
            if %!unparseable{$name} {
                $!validation-state.add-bad-input-error($name);
                next;
            }

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

            # Only do further checks if we have a value to check (if we get to here
            # with no value, then it was not a required value).
            next without $value;
            next if $value ~~ Str && $value eq '';

            with $attr.?webapp-form-type {
                when 'number' {
                    # We may have already parsed it into a numeric value, in which
                    # case it's obviously fine, so only check the string case.
                    if $type !~~ Real {
                        without $value.Real {
                            $!validation-state.add-bad-input-error($name);
                            next;
                        }
                    }
                }
            }

            with $attr.?webapp-form-minlength -> $min {
                if $value.chars < $min {
                    $!validation-state.add-too-short-error($name);
                    next;
                }
            }
            with $attr.?webapp-form-maxlength -> $max {
                if $value.chars > $max {
                    $!validation-state.add-too-long-error($name);
                    next;
                }
            }

            with $attr.?webapp-form-min -> $min {
                if $value ~~ Real {
                    if $value < $min {
                        $!validation-state.add-range-underflow-error($name);
                        next;
                    }
                }
                orwith $value.Real {
                    if $_ < $min {
                        $!validation-state.add-range-underflow-error($name);
                        next;
                    }
                }
            }
            with $attr.?webapp-form-max -> $max {
                if $value ~~ Real {
                    if $value > $max {
                        $!validation-state.add-range-overflow-error($name);
                        next;
                    }
                }
                orwith $value.Real {
                    if $_ > $max {
                        $!validation-state.add-range-overflow-error($name);
                        next;
                    }
                }
            }

            with $attr.?webapp-form-validations -> @validations {
                for @validations -> [$check, $message] {
                    if $value !~~ $check {
                        $!validation-state.add-custom-error($name, $message);
                        last;
                    }
                }
            }
        }

        # If it's valid at this point, perform form-level validation. (Don't
        # bother if there's per-field problems. Doing it this way means the
        # validation logic at form level can assume all the per-input constraints
        # are met, and so be simpler.)
        if $!validation-state.is-valid {
            self.?validate-form();
        }
    }

    #| Checks that we have the required CSRF token and it matches.
    method !check-csrf-token() {
        use Cro::HTTP::Router;
        with try request -> Cro::HTTP::Request $request {
            with $request.cookie-value(CSRF-TOKEN-NAME) -> $expected {
                if ($!received-csrf-token // '') ne $expected {
                    $!validation-state.add-custom-error('CSRF form token missing or invalid');
                }
            }
            else {
                $!validation-state.add-custom-error('CSRF cookie missing');
            }
        }
    }

    #| Add a form-level validation error.
    method add-validation-error($message --> Nil) {
        $!validation-state.add-custom-error($message);
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
