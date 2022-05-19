use v6.d;
use Cro::WebApp::Template::Repository;

#| The object received by custom control containing the data it uses to render
#| itself.
class Cro::WebApp::Form::Component::Data {
    #| The name of the control.
    has Str $.name is required;

    #| The current value of the control, if any.
    has $.value;
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
}
