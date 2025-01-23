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
