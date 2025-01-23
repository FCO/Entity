use Entity;

entity ShoppingCart {
   has UInt $.user is entity-id;
   has UInt @.products;

   method add-product(:$product) is command {
      $.product-added(:$product)
   }

   method product-added(Str :$product) is event { @!products.push: $product }

}

my \Interface = ShoppingCart.^interface;
say my $cart = Interface.new: :42user;
say my $cmd = $cart.add-product: :product<ble>;

say ShoppingCart."!run"($cmd)
