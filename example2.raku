use ShoppingCart;

my Supplier $supplier .= new;

my &*EMIT = -> $obj {
	say $obj;
	$supplier.emit: $obj
}

my $s = $supplier.Supply.tap: -> $cmd {
	use ShoppingCart qw/internal/;
	state ShoppingCart $cart;
	given $cart."!run"($cmd) {
		when ShoppingCart {
			$cart = $_
		}
	}
	say $cart;
	CATCH {
		default {
			.warn
		}
	}
}

my $cart = ShoppingCart.new(:42user);
$cart.create-cart;
$cart.add-list-of-products: :list(:{ :13watch, :3belt});
