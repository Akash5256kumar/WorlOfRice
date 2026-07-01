import { useState } from 'react';
import { useNavigate } from 'react-router';
import { Header } from '../components/Header';
import { useApp } from '../context/AppContext';
import { toast } from 'sonner';
import { ChevronDown } from 'lucide-react';

export function Checkout() {
  const { cart, placeOrder, user } = useApp();
  const navigate = useNavigate();
  const [paymentMethod, setPaymentMethod] = useState<'cod' | 'online'>('cod');
  const [deliveryMethod, setDeliveryMethod] = useState<'home' | 'pickup'>('home');
  const [termsAccepted, setTermsAccepted] = useState(false);
  const [showAddressForm, setShowAddressForm] = useState(false);

  const subtotal = cart.reduce((sum, item) => sum + item.price * item.quantity, 0);
  const tax = subtotal * 0.05;
  const delivery = deliveryMethod === 'home' ? (subtotal > 500 ? 0 : 40) : 0;
  const total = subtotal + tax + delivery;

  const handlePlaceOrder = () => {
    if (!termsAccepted) {
      toast.error('Please accept terms and conditions');
      return;
    }
    if (!user) {
      toast.error('Please login to place order');
      navigate('/login');
      return;
    }
    placeOrder();
    toast.success('Order placed successfully!');
    navigate('/orders');
  };

  return (
    <div className="min-h-screen bg-[#F5F0E8] pb-8">
      <Header />

      <div className="relative h-24 bg-[#1A5C38] flex items-center justify-center">
        <div
          className="absolute inset-0 opacity-20"
          style={{
            backgroundImage: `url("data:image/svg+xml,%3Csvg width='60' height='60' viewBox='0 0 60 60' xmlns='http://www.w3.org/2000/svg'%3E%3Cg fill='none' fill-rule='evenodd'%3E%3Cg fill='%23ffffff' fill-opacity='0.4'%3E%3Cpath d='M36 34v-4h-2v4h-4v2h4v4h2v-4h4v-2h-4zm0-30V0h-2v4h-4v2h4v4h2V6h4V4h-4zM6 34v-4H4v4H0v2h4v4h2v-4h4v-2H6zM6 4V0H4v4H0v2h4v4h2V6h4V4H6z'/%3E%3C/g%3E%3C/g%3E%3C/svg%3E")`,
          }}
        />
        <h1 className="text-3xl font-bold text-white relative z-10">CHECKOUT</h1>
      </div>

      <div className="p-4 space-y-4">
        <div className="bg-white rounded-xl p-4">
          <h2 className="font-bold text-lg mb-4 text-[#2C1F0E]">
            Payment Method
          </h2>
          <div className="flex gap-3">
            <button
              onClick={() => setPaymentMethod('cod')}
              className={`flex-1 py-3 px-4 rounded-lg font-medium transition-colors ${
                paymentMethod === 'cod'
                  ? 'bg-[#E74C1F] text-white'
                  : 'bg-gray-100 text-gray-700'
              }`}
            >
              Cash On Delivery
            </button>
            <button
              onClick={() => setPaymentMethod('online')}
              className={`flex-1 py-3 px-4 rounded-lg font-medium transition-colors ${
                paymentMethod === 'online'
                  ? 'bg-[#E74C1F] text-white'
                  : 'bg-gray-100 text-gray-700'
              }`}
            >
              Online
            </button>
          </div>
        </div>

        <div className="bg-white rounded-xl p-4">
          <h2 className="font-bold text-lg mb-4 text-[#2C1F0E]">
            Delivery Options
          </h2>
          <div className="flex gap-3">
            <button
              onClick={() => setDeliveryMethod('home')}
              className={`flex-1 py-3 px-4 rounded-lg font-medium transition-colors ${
                deliveryMethod === 'home'
                  ? 'bg-[#D4A017] text-white'
                  : 'bg-gray-100 text-gray-700'
              }`}
            >
              Home Delivery
            </button>
            <button
              onClick={() => setDeliveryMethod('pickup')}
              className={`flex-1 py-3 px-4 rounded-lg font-medium transition-colors ${
                deliveryMethod === 'pickup'
                  ? 'bg-[#D4A017] text-white'
                  : 'bg-gray-100 text-gray-700'
              }`}
            >
              I'll Pick It Up
            </button>
          </div>
        </div>

        {deliveryMethod === 'home' && (
          <div className="bg-white rounded-xl p-4">
            <div className="flex items-center justify-between mb-3">
              <h2 className="font-bold text-lg text-[#2C1F0E]">
                Delivery Address
              </h2>
              <button className="text-[#1A5C38] text-sm font-medium hover:underline">
                Edit
              </button>
            </div>

            <div className="bg-gray-50 p-4 rounded-lg mb-3">
              <p className="font-medium text-[#1A1A1A]">
                {user?.name || 'Guest User'}
              </p>
              <p className="text-sm text-[#6B6B6B] mt-1">
                123 Rice Street, Heritage Colony
              </p>
              <p className="text-sm text-[#6B6B6B]">Mumbai, Maharashtra 400001</p>
              <p className="text-sm text-[#6B6B6B] mt-1">+91 98109 61282</p>
            </div>

            <button
              onClick={() => setShowAddressForm(!showAddressForm)}
              className="flex items-center justify-between w-full py-3 px-4 bg-gray-50 rounded-lg text-left hover:bg-gray-100 transition-colors"
            >
              <span className="font-medium text-[#1A5C38]">Add New Address</span>
              <ChevronDown
                className={`w-5 h-5 text-[#1A5C38] transition-transform ${
                  showAddressForm ? 'rotate-180' : ''
                }`}
              />
            </button>

            {showAddressForm && (
              <div className="mt-3 space-y-3">
                <input
                  type="text"
                  placeholder="Street Address"
                  className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-[#1A5C38]"
                />
                <div className="grid grid-cols-2 gap-3">
                  <input
                    type="text"
                    placeholder="City"
                    className="px-4 py-3 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-[#1A5C38]"
                  />
                  <input
                    type="text"
                    placeholder="Pin Code"
                    className="px-4 py-3 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-[#1A5C38]"
                  />
                </div>
                <button className="w-full bg-[#1A5C38] text-white py-3 rounded-lg font-medium hover:bg-[#155030] transition-colors">
                  Save Address
                </button>
              </div>
            )}
          </div>
        )}

        <div className="bg-white rounded-xl p-4">
          <h2 className="font-bold text-lg mb-3 text-[#2C1F0E]">
            Order Summary
          </h2>

          <div className="space-y-3 mb-4">
            {cart.map((item) => (
              <div
                key={`${item.id}-${item.selectedSize}`}
                className="flex gap-3"
              >
                <img
                  src={item.image}
                  alt={item.name}
                  className="w-16 h-16 object-cover rounded-lg"
                />
                <div className="flex-1">
                  <p className="font-medium text-sm">{item.name}</p>
                  <p className="text-xs text-[#6B6B6B]">
                    {item.selectedSize} × {item.quantity}
                  </p>
                </div>
                <span className="font-semibold text-[#D4A017]">
                  ₹{item.price * item.quantity}
                </span>
              </div>
            ))}
          </div>

          <div className="border-t border-gray-200 pt-3 space-y-2">
            <div className="flex justify-between text-[#6B6B6B]">
              <span>Items Price</span>
              <span>₹{subtotal.toFixed(2)}</span>
            </div>
            <div className="flex justify-between text-[#6B6B6B]">
              <span>TAX (5%)</span>
              <span>₹{tax.toFixed(2)}</span>
            </div>
            <div className="flex justify-between text-[#6B6B6B]">
              <span>Delivery Fee</span>
              <span className={delivery === 0 ? 'text-[#1A5C38]' : ''}>
                {delivery === 0 ? 'Free' : `₹${delivery}`}
              </span>
            </div>
            <div className="flex justify-between font-bold text-lg pt-2 border-t border-gray-200">
              <span>Total</span>
              <span className="text-[#D4A017]">₹{total.toFixed(2)}</span>
            </div>
          </div>
        </div>

        <div className="bg-white rounded-xl p-4">
          <label className="flex items-start gap-3 cursor-pointer">
            <input
              type="checkbox"
              checked={termsAccepted}
              onChange={(e) => setTermsAccepted(e.target.checked)}
              className="mt-1 w-5 h-5 text-[#1A5C38] border-gray-300 rounded focus:ring-[#1A5C38]"
            />
            <span className="text-sm text-[#6B6B6B]">
              I AGREE TO{' '}
              <a href="#" className="text-[#1A5C38] hover:underline">
                TERMS & CONDITIONS
              </a>
            </span>
          </label>
        </div>

        <button
          onClick={handlePlaceOrder}
          disabled={!termsAccepted}
          className={`w-full py-4 rounded-lg font-medium transition-colors ${
            termsAccepted
              ? 'bg-[#1A5C38] text-white hover:bg-[#155030]'
              : 'bg-gray-300 text-gray-500 cursor-not-allowed'
          }`}
        >
          PLACE ORDER
        </button>
      </div>
    </div>
  );
}
