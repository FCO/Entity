use MetamodelX::EntityHOW;

my package EXPORTHOW {
    package DECLARE {
        constant entity = MetamodelX::EntityHOW;
    }
}

multi trait_mod:<is>(Method $m, Bool :$command! where *.so) is export {
	$m does role Command { method is-command { True } }
}

multi trait_mod:<is>(Method $m, Bool :$event! where *.so) is export {
	$m does role Event { method is-event { True } }
}

multi trait_mod:<is>(Attribute $attr, Bool :$entity-id! where *.so) is export {
	$attr does role EntityId { method is-entity-id { True } }
}

=begin pod

=head1 NAME

Entity - Easy way to Event Sourcing

=head1 SYNOPSIS

=begin code :lang<raku>

# ShoppingCart.rakumod
use Entity;

my entity ShoppingCart {
	has UInt $.user is entity-id;
	has Str @.products;

	method create-cart is command {
		$.cart-created
	}

	method cart-created is event {
		self.new
	}

	method add-product(Str :$product, UInt :$count = 1) is command {
		$.product-added: :$product, :$count
	}

	method add-list-of-products(:%list) is command {
		for %list.kv -> Str $product, UInt $count {
			$.product-added: :$product, :$count
		}
	}

	method product-added(ShoppingCart:D: Str :$product, UInt :$count = 1) is event {
		@!products.push: |($product xx $count)
	}
}

multi EXPORT             { Map.new: ( ShoppingCart => ShoppingCart.^interface )}
multi EXPORT("internal") { Map.new: ( ShoppingCart => ShoppingCart )}

=end code

=begin code :lang<raku>
# run-shoppingcart.raku

use ShoppingCart;

my Supplier $supplier .= new;

# How the events and commands will be emitted
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

=end code

=head1 DESCRIPTION

I don't really know if that's a good idea or just stupid...
I was planning on writing ES/CQRS using Raku and got tired only by thinking on all classes I wouls need to writel
Then I thougt into this way on having the entity, the commands and the events all in a single "class" that will 
create the commands and events for you. If you define a method as command, instead of run your code, it will
emit a command object with all the data you passed, and on the command hancler (C<!run()>), it will run the original method code.
The same for events.

=head1 AUTHOR

Fernando Corrêa de Oliveira <fco@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright 2025 Fernando Corrêa de Oliveira

This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.

=end pod
