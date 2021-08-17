use Test;
use Cro::HTTP::Router;
use Cro::WebApp::Template;

my constant $base = $*PROGRAM.parent.add('test-data');

{
    my $app = route :name<a>, {
        include x => route :name<b>, {
    	    get :name<home>, -> { } # no way to reach it yet
        }
        get :name<home>, -> { } # but this one should be reachable by a.home
        include y => route :name<c>, {
            get :name<home>, -> 'foo' {
                is make-link('home'), '/y/foo';    # /y
                is make-link('c.home'), '/y/foo';  # /y
                is make-link('a.home'), '/';  # /
            }
        }

        get :name<bar>, -> 'bar', Int $foo {
            is make-link('a.bar', 42), '/bar/42', 'A simple router link maker is correct';
            template $base.add('link.crotmp'), %( id => 50, name => 'a.bar' );
        }

        include baz => route :name<baz>, {
            get :name<foo>, -> 'bar', Int $foo {
                is make-link('baz.foo', 42), '/baz/bar/42', 'A link for an included route is correct';
                is make-link('foo', 42), '/baz/bar/42', 'A link for an included route is correct, by short name';
                template $base.add('link.crotmp'), %( id => 50, name => 'baz.foo' );
            }
        }

        include bad => route :name<bad>, {
            include baz => route :name<baz>, {
                get :name<foo>, -> 'bar', Int $foo {
                    is make-link('bad.baz.foo', 42), '/bad/baz/bar/42', 'A link for an included route is correct';
                    template $base.add('link.crotmp'), %( id => 50, name => 'bad.baz.foo' );
                }
            }
        }
    }

    my $source = Supplier.new;
    my $responses = $app.transformer($source.Supply).Channel;

    $source.emit(Cro::HTTP::Request.new(:method<GET>, :target</y/foo>));
    given $responses.receive -> $r {
        ok $r ~~ Cro::HTTP::Response, 'Route set routes / correctly';
        is $r.status, 204, 'Got 200 response';
    }

    $source.emit(Cro::HTTP::Request.new(:method<GET>, :target</bar/15>));
    given $responses.receive -> $r {
        ok $r ~~ Cro::HTTP::Response, 'Route set routes / correctly';
        is $r.status, 200, 'Got 200 response';
        is (await $r.body-text), '<a href="/bar/50">...</a>';
    }

    $source.emit(Cro::HTTP::Request.new(:method<GET>, :target</baz/bar/24>));
    given $responses.receive -> $r {
        ok $r ~~ Cro::HTTP::Response, 'Route set routes / correctly';
        is $r.status, 200, 'Got 200 response';
        is (await $r.body-text), '<a href="/baz/bar/50">...</a>';
    }

    $source.emit(Cro::HTTP::Request.new(:method<GET>, :target</bad/baz/bar/24>));
    given $responses.receive -> $r {
        ok $r ~~ Cro::HTTP::Response, 'Route set routes / correctly';
        is $r.status, 200, 'Got 200 response';
        is (await $r.body-text), '<a href="/bad/baz/bar/50">...</a>';
    }
}

done-testing;
