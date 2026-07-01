import { Link } from 'react-router';
import { ShoppingCart, User, Heart } from 'lucide-react';
import { useApp } from '../context/AppContext';

interface HeaderProps {
  showCart?: boolean;
}

export function Header({ showCart = true }: HeaderProps) {
  const { cart, user, favorites } = useApp();
  const cartCount = cart.reduce((sum, item) => sum + item.quantity, 0);

  return (
    <header className="bg-white border-b border-gray-200 sticky top-0 z-40 shadow-sm">
      <div className="flex items-center justify-between h-16 px-4 max-w-[390px] mx-auto">
        <Link to="/home" className="flex items-center gap-2">
          <div className="w-12 h-12">
            <img
              src="/src/imports/image.png"
              alt="JOY World of Rice"
              className="w-full h-full object-contain"
            />
          </div>
        </Link>

        <div className="flex items-center gap-3">
          <Link to="/favorites" className="relative p-2 hover:bg-gray-100 rounded-full transition-colors">
            <Heart className="w-5 h-5 text-gray-700" />
            {favorites.length > 0 && (
              <span className="absolute -top-0.5 -right-0.5 bg-[#E74C1F] text-white text-xs rounded-full w-4 h-4 flex items-center justify-center font-medium">
                {favorites.length}
              </span>
            )}
          </Link>
          {showCart && (
            <Link to="/cart" className="relative p-2 hover:bg-gray-100 rounded-full transition-colors">
              <ShoppingCart className="w-5 h-5 text-gray-700" />
              {cartCount > 0 && (
                <span className="absolute -top-0.5 -right-0.5 bg-[#E74C1F] text-white text-xs rounded-full w-4 h-4 flex items-center justify-center font-medium">
                  {cartCount}
                </span>
              )}
            </Link>
          )}
          <Link to="/account" className="p-2 hover:bg-gray-100 rounded-full transition-colors">
            {user ? (
              <div className="w-7 h-7 rounded-full bg-[#E74C1F] flex items-center justify-center">
                <span className="text-white text-xs font-medium">
                  {user.name.charAt(0)}
                </span>
              </div>
            ) : (
              <User className="w-5 h-5 text-gray-700" />
            )}
          </Link>
        </div>
      </div>
    </header>
  );
}
