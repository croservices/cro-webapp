use v6.d;
use Cro::WebApp::Form;
use JSON::Fast;
use Test;

{
    class MySimpleComponent does Cro::WebApp::Form::Component {
        method template(--> Str) {
            q:to/TEMPLATE/
                <:sub render($data)>
                  <input type="text" name="<$data.name>" value="<$data.value>">
                </:>
                TEMPLATE



        }
    }

    my class TestForm does Cro::WebApp::Form {
        has Str $.test is component(MySimpleComponent.new) is label('Test Label') is required;
    }

    my $render-data;
    lives-ok { $render-data = TestForm.empty.HTML-RENDER-DATA }, 'Can produce rendering data';
    is $render-data<controls>.elems, 1, 'Have one control';
    given $render-data<controls>[0] {
        is .<type>, 'custom', 'Has custom type';
        is .<name>, 'test', 'Correct name with custom component';
        is .<label>, 'Test Label', 'Correct label with custom component';
        is .<required>, True, 'Correct required with custom component';
        isa-ok .<custom-component>, MySimpleComponent, 'Component object is provided with control info';
        is-deeply .<custom-data>, Cro::WebApp::Form::Component::Data, 'Also given component data type object';

        my Str $rendered;
        lives-ok { $rendered = .<custom-component>.render(.<custom-data>.new(:name('test'), :label('Test'), :value('v'))) },
                'Can render template component';
        ok $rendered.contains('<input type="text" name="test" value="v">'),
                'Rendered as expected';
    }

    subtest 'Custom component with string value can parse fine' => {
        my $body = Cro::HTTP::Body::WWWFormUrlEncoded.new: :pairs[
            test => 'some value'
        ];
        given TestForm.parse($body) {
            is-deeply .test, 'some value', 'Correct string value of custom component placed in attribute';
            is-deeply .form-data, %(test => 'some value'), 'Can get the custom component data as a hash';
        }
    }
}

{
    class MyJsonComponent does Cro::WebApp::Form::Component {
        method template(--> Str) {
            q:to/TEMPLATE/
                <:sub render($data)>
                  <input type="text" name="<$data.name>" value="<$data.value>">
                </:>
                TEMPLATE
        }

        method parse-value(Str $value, Mu:U $type) {
            try { from-json $value } // fail 'Invalid JSON'
        }

        method serialize-value($value --> Str) {
            to-json $value
        }
    }

    my class TestForm does Cro::WebApp::Form {
        has %.test is component(MyJsonComponent.new) is label('JSON Blob');
    }

    subtest 'Custom component with parsing/serializing logic works' => {
        my $body = Cro::HTTP::Body::WWWFormUrlEncoded.new: :pairs[
            test => '{"key1":42,"key2":[1,2]}'
        ];
        given TestForm.parse($body) {
            is-deeply .test, { key1 => 42, key2 => [1, 2] }, 'Value was parsed as JSON';
            is-deeply .form-data, %(test => { key1 => 42, key2 => [1, 2] }), 'Can get the custom component data as a hash';
            ok .is-valid, 'The form is valid';

            my $render-data;
            lives-ok { $render-data = .HTML-RENDER-DATA }, 'Can produce rendering data in form with JSON value';
            is $render-data<controls>.elems, 1, 'Have one control';
            given $render-data<controls>[0] {
                is .<name>, 'test', 'Correct name';
                is .<label>, 'JSON Blob', 'Correct label';
                is-deeply from-json(.<value>), { key1 => 42, key2 => [1, 2] }, 'Value was serialized JSON';
            }
        }
    }

    subtest 'Custom component with parsing/serializing logic round-trips unparseable values' => {
        my $body = Cro::HTTP::Body::WWWFormUrlEncoded.new: :pairs[
            test => '{"key1":42,oops'
        ];
        given TestForm.parse($body) {
            is-deeply .test, {}, 'Empty attribute when parsing fails';
            nok .is-valid, 'The form is not valid';

            my $render-data;
            lives-ok { $render-data = .HTML-RENDER-DATA }, 'Can produce rendering data in form with unparseable component value';
            given $render-data<controls>[0] {
                is-deeply .<value>, '{"key1":42,oops', 'Unpareseable value was round-tripped';
            }
        }
    }
}

done-testing;
