import { createBrowserRouter } from 'react-router';
import { Splash } from './screens/Splash';
import { Onboarding } from './screens/Onboarding';
import { Login } from './screens/Login';
import { Home } from './screens/Home';
import { Shop } from './screens/Shop';
import { ProductDetail } from './screens/ProductDetail';
import { Cart } from './screens/Cart';
import { Checkout } from './screens/Checkout';
import { Blog } from './screens/Blog';
import { About } from './screens/About';
import { Contact } from './screens/Contact';
import { TrackOrder } from './screens/TrackOrder';
import { Account } from './screens/Account';
import { MyOrders } from './screens/MyOrders';
import { Favorites } from './screens/Favorites';

export const router = createBrowserRouter([
  {
    path: '/',
    Component: Splash,
  },
  {
    path: '/onboarding',
    Component: Onboarding,
  },
  {
    path: '/login',
    Component: Login,
  },
  {
    path: '/home',
    Component: Home,
  },
  {
    path: '/shop',
    Component: Shop,
  },
  {
    path: '/product/:id',
    Component: ProductDetail,
  },
  {
    path: '/cart',
    Component: Cart,
  },
  {
    path: '/checkout',
    Component: Checkout,
  },
  {
    path: '/blog',
    Component: Blog,
  },
  {
    path: '/about',
    Component: About,
  },
  {
    path: '/contact',
    Component: Contact,
  },
  {
    path: '/track',
    Component: TrackOrder,
  },
  {
    path: '/account',
    Component: Account,
  },
  {
    path: '/orders',
    Component: MyOrders,
  },
  {
    path: '/favorites',
    Component: Favorites,
  },
]);
