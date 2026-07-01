import { Link, useNavigate } from 'react-router';
import { Minus, Plus, X } from 'lucide-react';
import { Header } from '../components/Header';
import { BottomNav } from '../components/BottomNav';
import { useApp } from '../context/AppContext';

export function Cart() {
  const { cart, updateQuantity, removeFromCart, couponCode, setCouponCode } = useApp();
  const navigate = useNavigate();

  const subtotal = cart.reduce((sum, item) => sum + item.price * item.quantity, 0);
  const tax = subtotal * 0.05;
  const delivery = subtotal > 500 ? 0 : 40;
  const total = subtotal + tax + delivery;

  if (cart.length === 0) {
    return (
      <div className="min-h-screen bg-[#F5F0E8] pb-20">
        <Header />
        <div className="flex flex-col items-center justify-center py-20 px-4">
          <div className="w-32 h-32 bg-gray-200 rounded-full flex items-center justify-center mb-6">
            <svg
              className="w-16 h-16 text-gray-400"
              fill="none"
              viewBox="0 0 24 24"
              stroke="currentColor"
            >
              <path
                strokeLinecap="round"
                strokeLinejoin="round"
                strokeWidth={2}
                d="M3 3h2l.4 2M7 13h10l4-8H5.4M7 13L5.4 5M7 13l-2.293 2.293c-.63.63-.184 1.707.707 1.707H17m0 0a2 2 0 100 4 2 2 0 000-4zm-8 2a2 2 0 11-4 0 2 2 0 014 0z"
              />
            </svg>
          </div>
          <h2 className="text-2xl font-bold text-[#2C1F0E] mb-2">
            Your cart is empty
          </h2>
          <p className="text-[#6B6B6B] mb-6">Add some rice to get started!</p>
          <Link
            to="/shop"
            className="bg-[#1A5C38] text-white px-8 py-3 rounded-lg font-medium hover:bg-[#155030] transition-colors"
          >
            Start Shopping
          </Link>
        </div>
        <BottomNav />
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-[#F5F0E8] pb-20">
      <Header />

      <div className="relative h-24 bg-[#1A5C38] flex items-center justify-center">
        <div
          className="absolute inset-0 opacity-20"
          style={{
            backgroundImage: `url("data:image/svg+xml,%3Csvg width='60' height='60' viewBox='0 0 60 60' xmlns='http://www.w3.org/2000/svg'%3E%3Cg fill='none' fill-rule='evenodd'%3E%3Cg fill='%23ffffff' fill-opacity='0.4'%3E%3Cpath d='M36 34v-4h-2v4h-4v2h4v4h2v-4h4v-2h-4zm0-30V0h-2v4h-4v2h4v4h2V6h4V4h-4zM6 34v-4H4v4H0v2h4v4h2v-4h4v-2H6zM6 4V0H4v4H0v2h4v4h2V6h4V4H6z'/%3E%3C/g%3E%3C/g%3E%3C/svg%3E")`,
          }}
        />
        <h1 className="text-3xl font-bold text-white relative z-10">CART</h1>
      </div>

      <div className="p-4 space-y-4">
        {cart.map((item) => (
          <div key={`${item.id}-${item.selectedSize}`} className="bg-white rounded-xl p-4">
            <div className="flex gap-4">
              <img
                src={item.image}
                alt={item.name}
                className="w-20 h-20 object-cover rounded-lg"
              />

              <div className="flex-1">
                <div className="flex justify-between items-start mb-2">
                  <div>
                    <h3 className="font-medium text-[#1A1A1A] mb-1">
                      {item.name}
                    </h3>
                    <p className="text-sm text-[#6B6B6B]">
                      Size: {item.selectedSize}
                    </p>
                  </div>
                  <button
                    onClick={() => removeFromCart(item.id)}
                    className="text-gray-400 hover:text-[#E74C1F] transition-colors"
                  >
                    <X className="w-5 h-5" />
                  </button>
                </div>

                <div className="flex justify-between items-center">
                  <div className="flex items-center gap-3 bg-gray-100 rounded-lg p-1">
                    <button
                      onClick={() => updateQuantity(item.id, item.quantity - 1)}
                      className="w-8 h-8 flex items-center justify-center hover:bg-white rounded transition-colors"
                    >
                      <Minus className="w-4 h-4 text-[#1A5C38]" />
                    </button>
                    <span className="w-8 text-center font-medium">
                      {item.quantity}
                    </span>
                    <button
                      onClick={() => updateQuantity(item.id, item.quantity + 1)}
                      className="w-8 h-8 flex items-center justify-center hover:bg-white rounded transition-colors"
                    >
                      <Plus className="w-4 h-4 text-[#1A5C38]" />
                    </button>
                  </div>

                  <span className="font-semibold text-[#D4A017]">
                    ₹{item.price * item.quantity}
                  </span>
                </div>
              </div>
            </div>
          </div>
        ))}

        <div className="bg-white rounded-xl p-4 space-y-3">
          <h2 className="font-bold text-lg text-[#2C1F0E] mb-3">
            Order Summary
          </h2>

          <div className="flex justify-between text-[#6B6B6B]">
            <span>Subtotal</span>
            <span>₹{subtotal.toFixed(2)}</span>
          </div>

          <div className="flex justify-between text-[#6B6B6B]">
            <span>Tax (5%)</span>
            <span>₹{tax.toFixed(2)}</span>
          </div>

          <div className="flex justify-between text-[#6B6B6B]">
            <span>Delivery</span>
            <span className={delivery === 0 ? 'text-[#1A5C38]' : ''}>
              {delivery === 0 ? 'Free' : `₹${delivery}`}
            </span>
          </div>

          {subtotal < 500 && (
            <p className="text-xs text-[#6B6B6B]">
              Add ₹{(500 - subtotal).toFixed(2)} more for free delivery
            </p>
          )}

          <div className="border-t border-gray-200 pt-3 mt-3">
            <div className="flex justify-between font-bold text-lg">
              <span>Total</span>
              <span className="text-[#D4A017]">₹{total.toFixed(2)}</span>
            </div>
          </div>
        </div>

        <div className="bg-white rounded-xl p-4">
          <label className="block text-sm font-medium mb-2">
            Coupon / Gift Card
          </label>
          <div className="flex gap-2">
            <input
              type="text"
              value={couponCode}
              onChange={(e) => setCouponCode(e.target.value)}
              placeholder="Enter code"
              className="flex-1 px-4 py-3 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-[#1A5C38] focus:border-transparent"
            />
            <button className="bg-[#1A5C38] text-white px-6 py-3 rounded-lg font-medium hover:bg-[#155030] transition-colors">
              APPLY
            </button>
          </div>
        </div>

        <button
          onClick={() => navigate('/checkout')}
          className="w-full bg-[#E74C1F] text-white py-4 rounded-lg font-medium hover:bg-[#d64419] transition-colors"
        >
          CHECKOUT
        </button>

        <Link to="/shop">
          <button className="w-full border-2 border-[#1A5C38] text-[#1A5C38] py-4 rounded-lg font-medium hover:bg-[#1A5C38] hover:text-white transition-colors">
            CONTINUE SHOPPING
          </button>
        </Link>
      </div>

      <BottomNav />
    </div>
  );
}
