use Test;
use Cro::HTTP::Router;
use Cro::WebApp::Template;

my constant $base = $*PROGRAM.parent.add('test-data');

{
    my $app = route {
        include bar => route {
            get :name<home>, -> Int $foo {
                is '/bar/42', make-link('home', 42);
                template $base.add('link.crotmp'), %( id => 50 );
            }
        }
    }

    my $source = Supplier.new;
    my $responses = $app.transformer($source.Supply).Channel;

    $source.emit(Cro::HTTP::Request.new(:method<GET>, :target</bar/15>));
    given $responses.receive -> $r {
        ok $r ~~ Cro::HTTP::Response, 'Route set routes / correctly';
        is $r.status, 200, 'Got 200 response';
        is $r.header('Content-type'), 'text/html', 'Got expected header';
    }
}

done-testing;
