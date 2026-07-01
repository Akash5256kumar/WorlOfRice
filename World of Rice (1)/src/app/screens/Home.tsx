import { useState } from 'react';
import { Link } from 'react-router';
import { Header } from '../components/Header';
import { BottomNav } from '../components/BottomNav';
import { ProductCard } from '../components/ProductCard';
import { products, categories } from '../data/products';
import { Award, Truck, Package } from 'lucide-react';

export function Home() {
  const [selectedCategory, setSelectedCategory] = useState('All');

  const filteredProducts =
    selectedCategory === 'All'
      ? products.slice(0, 6)
      : products.filter((p) => p.category === selectedCategory).slice(0, 6);

  return (
    <div className="min-h-screen bg-[#F5F0E8] pb-20">
      <Header />

      <div className="relative h-64 overflow-hidden">
        <img
          src="https://images.unsplash.com/photo-1586201375761-83865001e31c?w=1200&q=80"
          alt="Rice fields"
          className="w-full h-full object-cover"
        />
        <div className="absolute inset-0 bg-gradient-to-t from-black/70 to-black/30" />
        <div className="absolute inset-0 flex flex-col items-center justify-center text-white px-6 text-center">
          <h1 className="text-3xl font-bold mb-3">
            Premium Rice, Delivered Fresh
          </h1>
          <Link
            to="/shop"
            className="bg-[#1A5C38] text-white px-8 py-3 rounded-lg font-medium hover:bg-[#155030] transition-colors"
          >
            Shop Now
          </Link>
        </div>
      </div>

      <section className="px-4 py-6">
        <h2 className="font-bold text-xl mb-4 text-[#2C1F0E]">CATEGORIES</h2>
        <div className="flex gap-2 overflow-x-auto pb-2 hide-scrollbar">
          {categories.map((category) => (
            <button
              key={category}
              onClick={() => setSelectedCategory(category)}
              className={`px-5 py-2 rounded-full whitespace-nowrap transition-colors ${
                selectedCategory === category
                  ? 'bg-[#1A5C38] text-white'
                  : 'bg-white text-gray-700 border border-gray-300'
              }`}
            >
              {category}
            </button>
          ))}
        </div>
      </section>

      <section className="px-4 py-6">
        <h2 className="font-bold text-xl mb-4 text-[#2C1F0E]">
          FEATURED PRODUCTS
        </h2>
        <div className="grid grid-cols-2 gap-4">
          {filteredProducts.map((product) => (
            <ProductCard key={product.id} product={product} />
          ))}
        </div>
        <Link
          to="/shop"
          className="block text-center mt-6 text-[#1A5C38] font-medium hover:underline"
        >
          View All Products →
        </Link>
      </section>

      <section className="px-4 py-6">
        <h2 className="font-bold text-xl mb-4 text-[#2C1F0E]">
          WHY CHOOSE US
        </h2>
        <div className="grid grid-cols-3 gap-4">
          <div className="bg-white p-4 rounded-xl text-center">
            <div className="w-12 h-12 bg-[#1A5C38]/10 rounded-full flex items-center justify-center mx-auto mb-3">
              <Award className="w-6 h-6 text-[#1A5C38]" />
            </div>
            <h3 className="font-medium text-sm mb-1">Quality</h3>
            <p className="text-xs text-[#6B6B6B]">Premium grains</p>
          </div>
          <div className="bg-white p-4 rounded-xl text-center">
            <div className="w-12 h-12 bg-[#1A5C38]/10 rounded-full flex items-center justify-center mx-auto mb-3">
              <Package className="w-6 h-6 text-[#1A5C38]" />
            </div>
            <h3 className="font-medium text-sm mb-1">Variety</h3>
            <p className="text-xs text-[#6B6B6B]">150+ types</p>
          </div>
          <div className="bg-white p-4 rounded-xl text-center">
            <div className="w-12 h-12 bg-[#1A5C38]/10 rounded-full flex items-center justify-center mx-auto mb-3">
              <Truck className="w-6 h-6 text-[#1A5C38]" />
            </div>
            <h3 className="font-medium text-sm mb-1">Delivery</h3>
            <p className="text-xs text-[#6B6B6B]">Fast shipping</p>
          </div>
        </div>
      </section>

      <BottomNav />
    </div>
  );
}
