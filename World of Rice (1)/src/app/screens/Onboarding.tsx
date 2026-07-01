import { useState } from 'react';
import { useNavigate } from 'react-router';
import { ChevronRight } from 'lucide-react';

const slides = [
  {
    image: 'https://images.unsplash.com/photo-1595296121253-ab538f21e54b?w=800&q=80',
    title: '150+ Premium Varieties',
    subtitle: 'From Basmati to rare heritage grains',
  },
  {
    image: 'https://images.unsplash.com/photo-1596040033229-a0b39e238128?w=800&q=80',
    title: 'Straight to Your Doorstep',
    subtitle: 'Fast delivery across India',
  },
  {
    image: 'https://images.unsplash.com/photo-1586201375761-83865001e31c?w=800&q=80',
    title: 'Freshly Packed for Delivery',
    subtitle: 'Carefully handled from our store to your doorstep',
  },
];

export function Onboarding() {
  const [currentSlide, setCurrentSlide] = useState(0);
  const navigate = useNavigate();

  const handleNext = () => {
    if (currentSlide < slides.length - 1) {
      setCurrentSlide(currentSlide + 1);
    }
  };

  const handleGetStarted = () => {
    navigate('/login');
  };

  const slide = slides[currentSlide];
  const isLastSlide = currentSlide === slides.length - 1;

  return (
    <div className="h-screen flex flex-col">
      <div className="relative flex-1">
        <img
          src={slide.image}
          alt={slide.title}
          className="w-full h-full object-cover"
        />
        <div className="absolute inset-0 bg-gradient-to-t from-black/70 via-black/30 to-transparent" />

        <div className="absolute bottom-0 left-0 right-0 p-8 text-white">
          <h2 className="text-3xl font-bold mb-2">{slide.title}</h2>
          <p className="text-lg text-white/90 mb-8">{slide.subtitle}</p>

          <div className="flex justify-center gap-2 mb-8">
            {slides.map((_, index) => (
              <div
                key={index}
                className={`h-2 rounded-full transition-all ${
                  index === currentSlide
                    ? 'w-8 bg-[#D4A017]'
                    : 'w-2 bg-white/40'
                }`}
              />
            ))}
          </div>

          {isLastSlide ? (
            <div className="flex flex-col gap-3">
              <button
                onClick={handleGetStarted}
                className="w-full bg-[#1A5C38] text-white py-4 rounded-xl font-medium hover:bg-[#155030] transition-colors"
              >
                Sign Up
              </button>
              <button
                onClick={() => navigate('/login')}
                className="w-full border-2 border-white text-white py-4 rounded-xl font-medium hover:bg-white/10 transition-colors"
              >
                Login
              </button>
            </div>
          ) : (
            <button
              onClick={handleNext}
              className="w-full bg-[#1A5C38] text-white py-4 rounded-xl font-medium flex items-center justify-center gap-2 hover:bg-[#155030] transition-colors"
            >
              Get Started
              <ChevronRight className="w-5 h-5" />
            </button>
          )}
        </div>
      </div>
    </div>
  );
}
