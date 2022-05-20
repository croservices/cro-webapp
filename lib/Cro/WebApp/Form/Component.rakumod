use v6.d;
use Cro::WebApp::Template::Repository;

#| The object received by custom control containing the data it uses to render
#| itself.
class Cro::WebApp::Form::Component::Data {
    #| The name of the control.
    has Str $.name is required;

    #| The label of the control.
    has Str $.label is required;

    #| Help message for the control, if any.
    has $.help;

    #| Validation errors, if any.
    has @.validation-errors;

    #| The current value of the control, if any.
    has $.value;

    #| The CSS class for input groups, if any.
    has $.input-group-class;

    #| The CSS class for labels, if any.
    has $.input-label-class;

    #| The CSS class for help messages, if any.
    has $.help-class;

    #| The CSS class for validation errors against a particular component, if any..
    has $.invalid-feedback-class;

    #| The CSS class for controls that are invalid, if any..
    has $.is-invalid-class;

    #| The CSS class for an input control, if any..
    has $.input-control-class;
}

#| The base role of all custom form components.
role Cro::WebApp::Form::Component {
    #| Cached template compilation.
    has $!cached-compilation;

    #| Should the component be rendered with the default form control
    #| surroundings (form group, label, help text, and validation errors)?
    #| Returns True by default, but return False if the control will render
    #| these itself.
    method default-wrapper(--> Bool) { True }

    #| Should evaluate to a Cro template that has a sub named `render`, which
    #| will render the control. The render sub should have a single positional
    #| argument, which is a Cro::WebApp::Form::Component::Data. In the event
    #| that custom rendering (direct to HTML rather than using a template) is
    #| desired, then return Nil from this.
    method template(--> Str) { ... }

    #| Render the control. The default implementation uses a Cro template sub
    #| in order to do the rendering. However, for complete control, it is also
    #| possible to override this method. What it returns will be interpolated as
    #| HTML and JavaScript ready for direct insertion into the output, with no
    #| encoding performed, so be careful to avoid XSS issues.
    method render(Cro::WebApp::Form::Component::Data $data --> Str) {
        $!cached-compilation //= parse-template(self.template, path => self.^name ~ '.template'.IO);
        with $!cached-compilation.exports<sub><render> {
            .($data)
        }
        else {
            die "Custom form component template for {self.^name} has no render function";
        }
    }

    #| Parse a value sent to the form into the specified data type (which is the declared
    #| type of the attribute on the class defining the form). If the value cannot be
    #| parsed, return a Failure, which will mark the value as unparseable. Only die if
    #| there is an implementation error rather than the input data being malformed.
    method parse-value(Str $value, Mu:U $type) {
        $type ~~ Str
                ?? $value
                !! die "Custom form component {self.^name} cannot parse into a {$type.^name}; override parse-value"
    }

    #| Serialize a value into a Str, which will be used in the form rendering.
    method serialize-value(Mu $value --> Str) {
        $value ~~ Str
            ?? $value
            !! die  "Custom form component {self.^name} cannot serialize a {$value.^name}; override serialize-value"
    }
}
