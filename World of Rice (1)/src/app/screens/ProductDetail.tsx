import { useState } from 'react';
import { useParams, useNavigate, Link } from 'react-router';
import { ChevronLeft, ShoppingCart } from 'lucide-react';
import { products } from '../data/products';
import { useApp } from '../context/AppContext';
import { ProductCard } from '../components/ProductCard';
import { toast } from 'sonner';

export function ProductDetail() {
  const { id } = useParams();
  const navigate = useNavigate();
  const { addToCart, cart } = useApp();
  const [selectedSize, setSelectedSize] = useState('');
  const [selectedImage, setSelectedImage] = useState(0);
  const [activeTab, setActiveTab] = useState<'description' | 'reviews' | 'shipping'>('description');

  const product = products.find((p) => p.id === id);

  if (!product) {
    return <div className="p-4">Product not found</div>;
  }

  if (!selectedSize) {
    setSelectedSize(product.sizes[0]);
  }

  const relatedProducts = products
    .filter((p) => p.category === product.category && p.id !== product.id)
    .slice(0, 4);

  const cartCount = cart.reduce((sum, item) => sum + item.quantity, 0);

  const handleBuyNow = () => {
    addToCart(product, selectedSize);
    navigate('/cart');
  };

  const handleAddToCart = () => {
    addToCart(product, selectedSize);
    toast.success('Added to cart!');
  };

  return (
    <div className="min-h-screen bg-[#F5F0E8]">
      <header className="bg-white border-b border-gray-200 sticky top-0 z-40">
        <div className="flex items-center justify-between h-16 px-4">
          <button onClick={() => navigate(-1)} className="p-2">
            <ChevronLeft className="w-6 h-6 text-gray-700" />
          </button>
          <Link to="/cart" className="relative p-2">
            <ShoppingCart className="w-6 h-6 text-gray-700" />
            {cartCount > 0 && (
              <span className="absolute top-0 right-0 bg-[#E74C1F] text-white text-xs rounded-full w-5 h-5 flex items-center justify-center">
                {cartCount}
              </span>
            )}
          </Link>
        </div>
      </header>

      <div className="bg-white px-4 py-2 text-sm text-[#6B6B6B]">
        <Link to="/home" className="hover:text-[#1A5C38]">
          Home
        </Link>
        <span className="mx-2">/</span>
        <Link to="/shop" className="hover:text-[#1A5C38]">
          Shop
        </Link>
        <span className="mx-2">/</span>
        <span className="text-[#1A1A1A]">{product.name}</span>
      </div>

      <div className="bg-white p-4">
        <div className="aspect-square bg-gray-100 rounded-xl overflow-hidden mb-4">
          <img
            src={product.image}
            alt={product.name}
            className="w-full h-full object-cover"
          />
        </div>

        <div className="flex gap-2 overflow-x-auto pb-2 hide-scrollbar">
          {[product.image, product.image, product.image, product.image].map((img, index) => (
            <button
              key={index}
              onClick={() => setSelectedImage(index)}
              className={`w-16 h-16 flex-shrink-0 rounded-lg overflow-hidden border-2 ${
                selectedImage === index ? 'border-[#1A5C38]' : 'border-gray-200'
              }`}
            >
              <img src={img} alt="" className="w-full h-full object-cover" />
            </button>
          ))}
        </div>
      </div>

      <div className="bg-white mt-2 p-4">
        {product.inStock && (
          <span className="inline-block bg-[#1A5C38] text-white text-xs px-3 py-1 rounded-full mb-3">
            In Stock
          </span>
        )}

        <h1 className="text-2xl font-bold text-[#1A1A1A] mb-2">
          {product.name}
        </h1>

        <p className="text-[#6B6B6B] mb-4">{product.description}</p>

        <div className="text-2xl font-semibold text-[#D4A017] mb-4">
          Price: ₹{product.price}
        </div>

        <div className="mb-6">
          <h3 className="font-medium mb-3">Select Size:</h3>
          <div className="flex gap-2 flex-wrap">
            {product.sizes.map((size) => (
              <button
                key={size}
                onClick={() => setSelectedSize(size)}
                className={`px-6 py-2 rounded-lg border-2 transition-colors ${
                  selectedSize === size
                    ? 'bg-[#1A5C38] text-white border-[#1A5C38]'
                    : 'bg-white text-gray-700 border-gray-300 hover:border-[#1A5C38]'
                }`}
              >
                {size}
              </button>
            ))}
          </div>
        </div>

        <div className="flex gap-3 mb-6">
          <button
            onClick={handleBuyNow}
            className="flex-1 bg-[#E74C1F] text-white py-4 rounded-lg font-medium hover:bg-[#d64419] transition-colors"
          >
            BUY NOW
          </button>
          <button
            onClick={handleAddToCart}
            className="flex-1 bg-white text-[#1A5C38] py-4 rounded-lg font-medium border-2 border-[#1A5C38] hover:bg-[#1A5C38] hover:text-white transition-colors"
          >
            ADD TO CART
          </button>
        </div>

        <div className="border-b border-gray-200 mb-4">
          <div className="flex gap-6">
            {(['description', 'reviews', 'shipping'] as const).map((tab) => (
              <button
                key={tab}
                onClick={() => setActiveTab(tab)}
                className={`pb-3 capitalize font-medium transition-colors ${
                  activeTab === tab
                    ? 'text-[#E74C1F] border-b-2 border-[#E74C1F]'
                    : 'text-gray-500'
                }`}
              >
                {tab}
              </button>
            ))}
          </div>
        </div>

        <div className="text-[#6B6B6B]">
          {activeTab === 'description' && (
            <div>
              <p className="mb-3">{product.description}</p>
              <ul className="list-disc list-inside space-y-2">
                <li>100% natural and chemical-free</li>
                <li>Sourced directly from farmers</li>
                <li>Premium quality grains</li>
                <li>Traditional processing methods</li>
              </ul>
            </div>
          )}
          {activeTab === 'reviews' && (
            <div className="text-center py-6">
              <p>No reviews yet. Be the first to review this product!</p>
            </div>
          )}
          {activeTab === 'shipping' && (
            <div>
              <p className="mb-3">Free shipping on orders above ₹500</p>
              <p className="mb-3">Delivery in 3-5 business days</p>
              <p>Cash on delivery available</p>
            </div>
          )}
        </div>
      </div>

      {relatedProducts.length > 0 && (
        <div className="mt-2 bg-white p-4">
          <h2 className="text-xl font-bold mb-4 text-[#2C1F0E]">
            MORE FROM THIS STORE
          </h2>
          <div className="flex gap-4 overflow-x-auto pb-2 hide-scrollbar">
            {relatedProducts.map((relatedProduct) => (
              <div key={relatedProduct.id} className="w-40 flex-shrink-0">
                <ProductCard product={relatedProduct} />
              </div>
            ))}
          </div>
        </div>
      )}
    </div>
  );
}
