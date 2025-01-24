use ShoppingCart;
use Nats;

#!/usr/bin/env raku

use lib "lib";

use Nats::Server;
use Nats::Route;

my $application = route {
	subscribe -> "CQRS", $id, $type {
		CATCH { default { .say } }
		use ShoppingCart qw/internal/;

		my &*EMIT = -> $obj {
			my $type = $obj.^name;
			say "publishing: ", $obj;
			message.nats.publish: "CQRS.{ $obj.user }.{ $type }", $obj.to-json;
		}

		state ShoppingCart $cart;
		my $cmd = ::($type).from-json: message.payload;
		say message;
		say "reacting to: ", $cmd, " with: ", $cart;

		given $cart."!run"($cmd) {
			when ShoppingCart {
				$cart = $_
			}
		}
		say "after reacting: ", $cart;
	}

	start-up -> $nats {
		CATCH { default { .say } }
		my &*EMIT = -> $obj {
			my $type = $obj.^name;
			say "publishing: ", $obj;
			$nats.publish: "CQRS.{ $obj.user }.{ $type }", $obj.to-json
		}
		my $cart = ShoppingCart.new(:42user);
		$cart.create-cart;
		$cart.add-list-of-products: :list(:{ :13watch, :3belt});
	}
}

my $server = Nats::Server.new: :$application;

$server.start;

react whenever signal(SIGINT) { $server.stop; exit }
