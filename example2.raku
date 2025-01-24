use ShoppingCart;

my Supplier $supplier .= new;

my &*EMIT = -> $obj {
	say "\o33[31;1memit: \o33[m", $obj;
	$supplier.emit: $obj
}

my $s = $supplier.Supply.tap: -> $cmd {
	use ShoppingCart qw/internal/;
	state ShoppingCart $cart;
	say "\o33[32;1mprocessing: \o33[m", $cmd;
	$cart .= "!handle"($cmd);
	say "\o33[33;1m", $cart, "\o33[m";
}

my $cart = ShoppingCart.new: :42user;
$cart.create-cart;
$cart.add-list-of-products: :list(:{ :5watch, :3belt});
$cart.finish;
say "query: ", $cart.query;
