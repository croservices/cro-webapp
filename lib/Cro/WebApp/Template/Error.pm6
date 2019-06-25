role X::Cro::WebApp::Template is Exception {
    has IO::Path $.file is required;

    method message() { ... }
}
