import { Link } from 'react-router';
import { Header } from '../components/Header';
import { BottomNav } from '../components/BottomNav';
import { useApp } from '../context/AppContext';
import { Package } from 'lucide-react';

export function MyOrders() {
  const { orders } = useApp();

  if (orders.length === 0) {
    return (
      <div className="min-h-screen bg-[#F5F0E8] pb-20">
        <Header />

        <div className="relative h-24 bg-[#1A5C38] flex items-center justify-center">
          <h1 className="text-3xl font-bold text-white relative z-10">
            MY ORDERS
          </h1>
        </div>

        <div className="flex flex-col items-center justify-center py-20 px-4">
          <div className="w-24 h-24 bg-gray-200 rounded-full flex items-center justify-center mb-6">
            <Package className="w-12 h-12 text-gray-400" />
          </div>
          <h2 className="text-2xl font-bold text-[#2C1F0E] mb-2">
            No Orders Yet
          </h2>
          <p className="text-[#6B6B6B] mb-6 text-center">
            Start shopping to see your orders here
          </p>
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
        <h1 className="text-3xl font-bold text-white relative z-10">MY ORDERS</h1>
      </div>

      <div className="p-4 space-y-4">
        {orders.map((order) => (
          <div key={order.id} className="bg-white rounded-xl p-4 shadow-sm">
            <div className="flex justify-between items-start mb-3">
              <div>
                <p className="font-medium text-[#1A1A1A]">
                  Order #{order.id.slice(-8)}
                </p>
                <p className="text-sm text-[#6B6B6B]">{order.date}</p>
              </div>
              <span
                className={`px-3 py-1 rounded-full text-xs font-medium ${
                  order.status === 'Delivered'
                    ? 'bg-[#1A5C38] text-white'
                    : order.status === 'Pending'
                    ? 'bg-[#D4A017] text-white'
                    : 'bg-red-500 text-white'
                }`}
              >
                {order.status}
              </span>
            </div>

            <div className="space-y-2 mb-3">
              {order.items.map((item, index) => (
                <div key={index} className="flex gap-3">
                  <img
                    src={item.image}
                    alt={item.name}
                    className="w-12 h-12 object-cover rounded-lg"
                  />
                  <div className="flex-1">
                    <p className="text-sm font-medium text-[#1A1A1A]">
                      {item.name}
                    </p>
                    <p className="text-xs text-[#6B6B6B]">
                      {item.selectedSize} × {item.quantity}
                    </p>
                  </div>
                </div>
              ))}
            </div>

            <div className="flex justify-between items-center pt-3 border-t border-gray-200">
              <span className="text-sm text-[#6B6B6B]">
                {order.items.length} item{order.items.length > 1 ? 's' : ''}
              </span>
              <span className="font-semibold text-[#D4A017]">
                ₹{order.total.toFixed(2)}
              </span>
            </div>

            <div className="flex gap-2 mt-4">
              <button className="flex-1 text-[#1A5C38] font-medium py-2 px-4 border-2 border-[#1A5C38] rounded-lg hover:bg-[#1A5C38] hover:text-white transition-colors">
                View Details
              </button>
              <button className="flex-1 bg-[#1A5C38] text-white py-2 px-4 rounded-lg font-medium hover:bg-[#155030] transition-colors">
                Reorder
              </button>
            </div>
          </div>
        ))}
      </div>

      <BottomNav />
    </div>
  );
}
