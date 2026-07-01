import { useState } from 'react';
import { Header } from '../components/Header';
import { BottomNav } from '../components/BottomNav';
import { Search, Package } from 'lucide-react';

export function TrackOrder() {
  const [orderId, setOrderId] = useState('');

  return (
    <div className="min-h-screen bg-[#F5F0E8] pb-20">
      <Header />

      <div className="flex items-center justify-center p-8 mt-12">
        <div className="w-full max-w-md bg-white rounded-2xl shadow-lg p-8">
          <div className="text-center mb-8">
            <div className="w-20 h-20 bg-[#1A5C38]/10 rounded-full flex items-center justify-center mx-auto mb-4">
              <Package className="w-10 h-10 text-[#1A5C38]" />
            </div>
            <h1 className="text-2xl font-bold text-[#2C1F0E] mb-2">
              Track Your Order
            </h1>
            <p className="text-sm text-[#6B6B6B]">
              Enter your order ID to track your delivery
            </p>
          </div>

          <div className="space-y-4">
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">
                Order ID
              </label>
              <input
                type="text"
                value={orderId}
                onChange={(e) => setOrderId(e.target.value)}
                placeholder="Enter your order ID"
                className="w-full px-4 py-3 bg-[#E8F4EE] border border-[#1A5C38]/20 rounded-lg focus:outline-none focus:ring-2 focus:ring-[#1A5C38] focus:border-transparent"
              />
            </div>

            <button className="w-full bg-[#E74C1F] text-white py-3 rounded-lg font-medium hover:bg-[#d64419] transition-colors flex items-center justify-center gap-2">
              <Search className="w-5 h-5" />
              SEARCH ORDER
            </button>
          </div>

          <div className="mt-12 text-center">
            <div className="w-32 h-32 mx-auto mb-4 opacity-50">
              <svg viewBox="0 0 200 200" fill="none" xmlns="http://www.w3.org/2000/svg">
                <path
                  d="M100 40L160 70V130L100 160L40 130V70L100 40Z"
                  stroke="#1A5C38"
                  strokeWidth="4"
                  fill="#E8F4EE"
                />
                <circle cx="100" cy="100" r="20" fill="#1A5C38" />
              </svg>
            </div>
            <p className="text-sm text-[#6B6B6B]">
              Enter your order ID above to view tracking details
            </p>
          </div>
        </div>
      </div>

      <BottomNav />
    </div>
  );
}
