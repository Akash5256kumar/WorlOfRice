import { Link } from 'react-router';
import { Header } from '../components/Header';
import { BottomNav } from '../components/BottomNav';
import { ProductCard } from '../components/ProductCard';
import { useApp } from '../context/AppContext';
import { Heart, ShoppingBag } from 'lucide-react';

export function Favorites() {
  const { favorites } = useApp();

  if (favorites.length === 0) {
    return (
      <div className="min-h-screen bg-[#F5F0E8] pb-20">
        <Header />

        <div className="relative h-32 bg-gradient-to-r from-[#1A5C38] to-[#155030] flex items-center justify-center">
          <div
            className="absolute inset-0 opacity-10"
            style={{
              backgroundImage: `url("data:image/svg+xml,%3Csvg width='60' height='60' viewBox='0 0 60 60' xmlns='http://www.w3.org/2000/svg'%3E%3Cg fill='none' fill-rule='evenodd'%3E%3Cg fill='%23ffffff' fill-opacity='0.4'%3E%3Cpath d='M36 34v-4h-2v4h-4v2h4v4h2v-4h4v-2h-4zm0-30V0h-2v4h-4v2h4v4h2V6h4V4h-4zM6 34v-4H4v4H0v2h4v4h2v-4h4v-2H6zM6 4V0H4v4H0v2h4v4h2V6h4V4H6z'/%3E%3C/g%3E%3C/g%3E%3C/svg%3E")`,
            }}
          />
          <div className="relative z-10 text-center">
            <h1 className="text-3xl font-bold text-white">My Favorites</h1>
            <p className="text-white/90 text-sm mt-1">Your wishlist items</p>
          </div>
        </div>

        <div className="flex flex-col items-center justify-center py-20 px-4">
          <div className="w-32 h-32 bg-gradient-to-br from-pink-100 to-red-100 rounded-full flex items-center justify-center mb-6 shadow-lg">
            <Heart className="w-16 h-16 text-[#E74C1F]" />
          </div>
          <h2 className="text-2xl font-bold text-[#2C1F0E] mb-2">
            No Favorites Yet
          </h2>
          <p className="text-[#6B6B6B] mb-6 text-center max-w-xs">
            Start adding your favorite rice varieties to your wishlist
          </p>
          <Link
            to="/shop"
            className="bg-[#1A5C38] text-white px-8 py-3 rounded-xl font-medium hover:bg-[#155030] transition-all duration-300 shadow-lg hover:shadow-xl flex items-center gap-2"
          >
            <ShoppingBag className="w-5 h-5" />
            Browse Products
          </Link>
        </div>

        <BottomNav />
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-[#F5F0E8] pb-20">
      <Header />

      <div className="relative h-32 bg-gradient-to-r from-[#1A5C38] to-[#155030] flex items-center justify-center">
        <div
          className="absolute inset-0 opacity-10"
          style={{
            backgroundImage: `url("data:image/svg+xml,%3Csvg width='60' height='60' viewBox='0 0 60 60' xmlns='http://www.w3.org/2000/svg'%3E%3Cg fill='none' fill-rule='evenodd'%3E%3Cg fill='%23ffffff' fill-opacity='0.4'%3E%3Cpath d='M36 34v-4h-2v4h-4v2h4v4h2v-4h4v-2h-4zm0-30V0h-2v4h-4v2h4v4h2V6h4V4h-4zM6 34v-4H4v4H0v2h4v4h2v-4h4v-2H6zM6 4V0H4v4H0v2h4v4h2V6h4V4H6z'/%3E%3C/g%3E%3C/g%3E%3C/svg%3E")`,
          }}
        />
        <div className="relative z-10 text-center">
          <h1 className="text-3xl font-bold text-white">My Favorites</h1>
          <p className="text-white/90 text-sm mt-1">
            {favorites.length} {favorites.length === 1 ? 'item' : 'items'} saved
          </p>
        </div>
      </div>

      <div className="p-4">
        <div className="flex items-center justify-between mb-4">
          <h2 className="font-bold text-lg text-[#2C1F0E]">
            Saved Items ({favorites.length})
          </h2>
          <Link
            to="/shop"
            className="text-[#1A5C38] text-sm font-medium hover:underline flex items-center gap-1"
          >
            <ShoppingBag className="w-4 h-4" />
            Continue Shopping
          </Link>
        </div>

        <div className="grid grid-cols-2 gap-4">
          {favorites.map((product) => (
            <ProductCard key={product.id} product={product} />
          ))}
        </div>

        <div className="mt-8 bg-white rounded-2xl p-6 shadow-sm border border-gray-100">
          <div className="flex items-start gap-4">
            <div className="w-12 h-12 bg-[#1A5C38]/10 rounded-full flex items-center justify-center flex-shrink-0">
              <Heart className="w-6 h-6 text-[#1A5C38]" />
            </div>
            <div>
              <h3 className="font-semibold text-[#2C1F0E] mb-1">
                Save Your Favorites
              </h3>
              <p className="text-sm text-[#6B6B6B] leading-relaxed">
                Keep track of products you love and get notified when they go on
                sale. Your favorites are saved across all your devices.
              </p>
            </div>
          </div>
        </div>
      </div>

      <BottomNav />
    </div>
  );
}
