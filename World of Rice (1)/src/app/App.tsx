import { RouterProvider } from 'react-router';
import { router } from './routes';
import { AppProvider } from './context/AppContext';
import { Toaster } from 'sonner';

export default function App() {
  return (
    <AppProvider>
      <div className="size-full bg-[#F5F0E8]">
        <RouterProvider router={router} />
        <Toaster position="bottom-center" />
      </div>
    </AppProvider>
  );
}