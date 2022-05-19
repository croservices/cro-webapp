use v6.d;
use Cro::WebApp::Form;
use Test;

class MyComponent does Cro::WebApp::Form::Component {
    method template(--> Str) {
        q:to/TEMPLATE/
            <:sub render($data)>
              <input type="text" name="<$data.name>" value="<$data.value>">
            </:>
            TEMPLATE
    }
}

{
    my class TestForm does Cro::WebApp::Form {
        has Str $.test is component(MyComponent.new) is label('Test Label') is required;
    }

    my $render-data;
    lives-ok { $render-data = TestForm.empty.HTML-RENDER-DATA }, 'Can produce rendering data';
    is $render-data<controls>.elems, 1, 'Have one control';
    given $render-data<controls>[0] {
        is .<type>, 'custom', 'Has custom type';
        is .<name>, 'test', 'Correct name with custom component';
        is .<label>, 'Test Label', 'Correct label with custom component';
        is .<required>, True, 'Correct required with custom component';
        isa-ok .<custom-component>, MyComponent, 'Component object is provided with control info';
        is-deeply .<custom-data>, Cro::WebApp::Form::Component::Data, 'Also given component data type object';

        my Str $rendered;
        lives-ok { $rendered = .<custom-component>.render(.<custom-data>.new(:name('test'), :value('v'))) },
            'Can render template component';
        ok $rendered.contains('<input type="text" name="test" value="v">'),
            'Rendered as expected';
    }
}

done-testing;
