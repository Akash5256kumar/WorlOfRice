import { Link, useLocation } from 'react-router';
import { Home, ShoppingBag, ShoppingCart, FileText, User } from 'lucide-react';
import { useApp } from '../context/AppContext';

export function BottomNav() {
  const location = useLocation();
  const { cart } = useApp();

  const navItems = [
    { path: '/home', icon: Home, label: 'Home' },
    { path: '/shop', icon: ShoppingBag, label: 'Shop' },
    { path: '/cart', icon: ShoppingCart, label: 'Cart', badge: cart.length },
    { path: '/blog', icon: FileText, label: 'Blog' },
    { path: '/account', icon: User, label: 'Account' },
  ];

  const isActive = (path: string) => location.pathname === path;

  return (
    <nav className="fixed bottom-0 left-0 right-0 bg-[#2C1F0E] border-t border-[#4a3a2a] z-50">
      <div className="flex justify-around items-center h-16 max-w-[390px] mx-auto">
        {navItems.map(({ path, icon: Icon, label, badge }) => (
          <Link
            key={path}
            to={path}
            className="flex flex-col items-center justify-center flex-1 h-full relative"
          >
            <div className="relative">
              <Icon
                className={`w-6 h-6 ${
                  isActive(path) ? 'text-[#D4A017]' : 'text-white/70'
                }`}
              />
              {badge !== undefined && badge > 0 && (
                <span className="absolute -top-2 -right-2 bg-[#E74C1F] text-white text-xs rounded-full w-5 h-5 flex items-center justify-center">
                  {badge}
                </span>
              )}
            </div>
            {isActive(path) && (
              <div className="w-1 h-1 bg-[#D4A017] rounded-full mt-1" />
            )}
          </Link>
        ))}
      </div>
    </nav>
  );
}
