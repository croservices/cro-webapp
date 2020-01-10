use Cro::WebApp::Template::Library;

my %exports := template-library %?RESOURCES<test-template-library.crotmp>;

sub EXPORT() {
    %exports
}
