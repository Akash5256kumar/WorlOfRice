import { useNavigate } from 'react-router';
import { Header } from '../components/Header';
import { BottomNav } from '../components/BottomNav';
import { useApp } from '../context/AppContext';
import {
  User,
  Package,
  MapPin,
  Settings,
  LogOut,
  ChevronRight,
  Search,
} from 'lucide-react';
import { toast } from 'sonner';

export function Account() {
  const { user, logout } = useApp();
  const navigate = useNavigate();

  const handleLogout = () => {
    logout();
    toast.success('Logged out successfully');
    navigate('/login');
  };

  if (!user) {
    return (
      <div className="min-h-screen bg-[#F5F0E8] pb-20">
        <Header />
        <div className="flex flex-col items-center justify-center py-20 px-4">
          <div className="w-24 h-24 bg-gray-200 rounded-full flex items-center justify-center mb-6">
            <User className="w-12 h-12 text-gray-400" />
          </div>
          <h2 className="text-2xl font-bold text-[#2C1F0E] mb-2">
            Not Logged In
          </h2>
          <p className="text-[#6B6B6B] mb-6 text-center">
            Please login to access your account
          </p>
          <button
            onClick={() => navigate('/login')}
            className="bg-[#1A5C38] text-white px-8 py-3 rounded-lg font-medium hover:bg-[#155030] transition-colors"
          >
            Login
          </button>
        </div>
        <BottomNav />
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-[#F5F0E8] pb-20">
      <Header />

      <div className="bg-white p-6 mb-4">
        <div className="flex items-center gap-4">
          <div className="w-16 h-16 bg-[#E74C1F] rounded-full flex items-center justify-center">
            <span className="text-2xl text-white font-bold">
              {user.name.charAt(0)}
            </span>
          </div>
          <div>
            <h2 className="text-xl font-bold text-[#2C1F0E]">{user.name}</h2>
            <p className="text-sm text-[#6B6B6B]">{user.email}</p>
          </div>
        </div>
      </div>

      <div className="px-4 space-y-2">
        <button
          onClick={() => navigate('/account')}
          className="w-full bg-white rounded-xl p-4 flex items-center justify-between hover:bg-gray-50 transition-colors"
        >
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 bg-[#1A5C38]/10 rounded-full flex items-center justify-center">
              <Settings className="w-5 h-5 text-[#1A5C38]" />
            </div>
            <span className="font-medium text-[#1A1A1A]">Profile Settings</span>
          </div>
          <ChevronRight className="w-5 h-5 text-gray-400" />
        </button>

        <button
          onClick={() => navigate('/orders')}
          className="w-full bg-white rounded-xl p-4 flex items-center justify-between hover:bg-gray-50 transition-colors"
        >
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 bg-[#1A5C38]/10 rounded-full flex items-center justify-center">
              <Package className="w-5 h-5 text-[#1A5C38]" />
            </div>
            <span className="font-medium text-[#1A1A1A]">My Orders</span>
          </div>
          <ChevronRight className="w-5 h-5 text-gray-400" />
        </button>

        <button
          onClick={() => navigate('/track')}
          className="w-full bg-white rounded-xl p-4 flex items-center justify-between hover:bg-gray-50 transition-colors"
        >
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 bg-[#1A5C38]/10 rounded-full flex items-center justify-center">
              <Search className="w-5 h-5 text-[#1A5C38]" />
            </div>
            <span className="font-medium text-[#1A1A1A]">Track Order</span>
          </div>
          <ChevronRight className="w-5 h-5 text-gray-400" />
        </button>

        <button
          onClick={() => navigate('/account')}
          className="w-full bg-white rounded-xl p-4 flex items-center justify-between hover:bg-gray-50 transition-colors"
        >
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 bg-[#1A5C38]/10 rounded-full flex items-center justify-center">
              <MapPin className="w-5 h-5 text-[#1A5C38]" />
            </div>
            <span className="font-medium text-[#1A1A1A]">Saved Addresses</span>
          </div>
          <ChevronRight className="w-5 h-5 text-gray-400" />
        </button>

        <button
          onClick={handleLogout}
          className="w-full bg-white rounded-xl p-4 flex items-center justify-between hover:bg-red-50 transition-colors"
        >
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 bg-red-100 rounded-full flex items-center justify-center">
              <LogOut className="w-5 h-5 text-[#E74C1F]" />
            </div>
            <span className="font-medium text-[#E74C1F]">Logout</span>
          </div>
          <ChevronRight className="w-5 h-5 text-gray-400" />
        </button>
      </div>

      <BottomNav />
    </div>
  );
}
