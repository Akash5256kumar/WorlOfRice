import { Link } from 'react-router';
import { Product } from '../context/AppContext';
import { useApp } from '../context/AppContext';
import { toast } from 'sonner';
import { ShoppingCart, Star, Heart } from 'lucide-react';

interface ProductCardProps {
  product: Product;
}

export function ProductCard({ product }: ProductCardProps) {
  const { addToCart, toggleFavorite, isFavorite } = useApp();
  const isFav = isFavorite(product.id);

  const handleAddToCart = (e: React.MouseEvent) => {
    e.preventDefault();
    addToCart(product, product.sizes[0]);
    toast.success('Added to cart!');
  };

  const handleToggleFavorite = (e: React.MouseEvent) => {
    e.preventDefault();
    toggleFavorite(product);
    toast.success(isFav ? 'Removed from favorites' : 'Added to favorites');
  };

  return (
    <Link to={`/product/${product.id}`} className="group">
      <div className="bg-white rounded-2xl overflow-hidden shadow-sm hover:shadow-xl transition-all duration-300 transform hover:-translate-y-1 border border-gray-100">
        <div className="relative aspect-square overflow-hidden bg-gradient-to-br from-gray-50 to-gray-100">
          <img
            src={product.image}
            alt={product.name}
            className="w-full h-full object-cover group-hover:scale-110 transition-transform duration-500"
          />
          {product.inStock && (
            <div className="absolute top-3 left-3 bg-[#1A5C38] text-white text-xs px-2.5 py-1 rounded-full font-medium shadow-lg">
              In Stock
            </div>
          )}
          <button
            onClick={handleToggleFavorite}
            className="absolute top-3 right-3 w-9 h-9 bg-white/90 backdrop-blur-sm rounded-full flex items-center justify-center shadow-md hover:bg-white transition-all duration-300 hover:scale-110"
          >
            <Heart
              className={`w-5 h-5 transition-all ${
                isFav
                  ? 'fill-[#E74C1F] text-[#E74C1F] scale-110'
                  : 'text-gray-600'
              }`}
            />
          </button>
          <div className="absolute bottom-3 left-3 flex items-center gap-0.5 bg-white/90 backdrop-blur-sm px-2 py-1 rounded-full">
            <Star className="w-3 h-3 fill-[#D4A017] text-[#D4A017]" />
            <span className="text-xs font-semibold text-[#1A1A1A]">4.8</span>
          </div>
        </div>

        <div className="p-4">
          <div className="mb-2">
            <h3 className="font-semibold text-[#1A1A1A] mb-1 line-clamp-2 leading-tight group-hover:text-[#1A5C38] transition-colors">
              {product.name}
            </h3>
            <div className="flex items-center gap-2">
              <span className="text-xs text-[#6B6B6B] bg-gray-100 px-2 py-0.5 rounded-full">
                {product.sizes[0]}
              </span>
              <span className="text-xs text-[#1A5C38] font-medium">
                {product.category}
              </span>
            </div>
          </div>

          <div className="flex items-center justify-between gap-2 mt-3">
            <div>
              <div className="text-xl font-bold text-[#D4A017]">
                ₹{product.price}
              </div>
              <div className="text-xs text-[#6B6B6B] line-through">
                ₹{Math.round(product.price * 1.2)}
              </div>
            </div>
            <button
              onClick={handleAddToCart}
              className="bg-[#1A5C38] text-white pl-3 pr-4 py-2.5 rounded-xl text-sm font-medium hover:bg-[#155030] transition-all duration-300 flex items-center gap-1.5 shadow-md hover:shadow-lg transform hover:scale-105"
            >
              <ShoppingCart className="w-4 h-4" />
              Add
            </button>
          </div>
        </div>
      </div>
    </Link>
  );
}
