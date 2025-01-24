use Entity;
use JSON::Class:ver<0.0.21>:auth<zef:jonathanstowe>:api<1.0>;

my entity ShoppingCart {
	has UInt $.user is entity-id;
	has Str  @.products;
	has Bool $.done = False;

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

	method finish is command {
		$.done
	}

	method done is event {
		$!done = True;
	}
}

multi EXPORT             { Map.new: ( ShoppingCart => ShoppingCart.^interface )}
multi EXPORT("internal") { ShoppingCart.^exports }
