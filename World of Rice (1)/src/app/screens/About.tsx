import { Header } from '../components/Header';
import { BottomNav } from '../components/BottomNav';

export function About() {
  return (
    <div className="min-h-screen bg-[#F5F0E8] pb-20">
      <Header />

      <div className="relative h-32 bg-[#1A5C38] flex items-center justify-center">
        <div
          className="absolute inset-0 opacity-20"
          style={{
            backgroundImage: `url("data:image/svg+xml,%3Csvg width='60' height='60' viewBox='0 0 60 60' xmlns='http://www.w3.org/2000/svg'%3E%3Cg fill='none' fill-rule='evenodd'%3E%3Cg fill='%23ffffff' fill-opacity='0.4'%3E%3Cpath d='M36 34v-4h-2v4h-4v2h4v4h2v-4h4v-2h-4zm0-30V0h-2v4h-4v2h4v4h2V6h4V4h-4zM6 34v-4H4v4H0v2h4v4h2v-4h4v-2H6zM6 4V0H4v4H0v2h4v4h2V6h4V4H6z'/%3E%3C/g%3E%3C/g%3E%3C/svg%3E")`,
          }}
        />
        <h1 className="text-3xl font-bold text-white relative z-10">ABOUT</h1>
      </div>

      <div className="p-4 space-y-6">
        <div className="bg-white rounded-xl overflow-hidden">
          <img
            src="https://images.unsplash.com/photo-1595296121253-ab538f21e54b?w=800&q=80"
            alt="Rice fields"
            className="w-full h-48 object-cover"
          />
          <div className="p-4">
            <h2 className="text-2xl font-bold text-[#2C1F0E] mb-3">
              Our Heritage
            </h2>
            <p className="text-[#6B6B6B] leading-relaxed">
              World of Rice began over five decades ago with a simple mission: to
              bring the finest rice varieties from across India to your table. Our
              journey started in the lush paddy fields of Punjab, where our
              founders discovered their passion for premium rice cultivation.
            </p>
          </div>
        </div>

        <div className="bg-white rounded-xl p-4 space-y-4">
          <div>
            <h3 className="text-xl font-bold text-[#2C1F0E] mb-2">
              A Legacy That Began Over Five Decades Ago
            </h3>
            <p className="text-[#6B6B6B] leading-relaxed">
              What started as a small family business has grown into one of India's
              most trusted rice brands. Through generations, we've maintained our
              commitment to quality and authenticity.
            </p>
          </div>

          <div>
            <h3 className="text-xl font-bold text-[#2C1F0E] mb-2">
              The Second Generation Takes the Reins
            </h3>
            <p className="text-[#6B6B6B] leading-relaxed">
              Today, the second generation continues the legacy with modern
              technology while preserving traditional values. We combine age-old
              wisdom with contemporary practices to deliver excellence.
            </p>
          </div>

          <div>
            <h3 className="text-xl font-bold text-[#2C1F0E] mb-2">
              A Commitment to Indigenous and Regional Varieties
            </h3>
            <p className="text-[#6B6B6B] leading-relaxed">
              We're proud to offer over 150 varieties of rice, including rare
              heritage grains that are disappearing from modern agriculture. Our
              mission is to preserve these treasures for future generations.
            </p>
          </div>

          <div>
            <h3 className="text-xl font-bold text-[#2C1F0E] mb-2">
              A Destination for Rice Lovers
            </h3>
            <p className="text-[#6B6B6B] leading-relaxed">
              From everyday staples to exotic varieties, we cater to every palate
              and preference. Our customers range from home cooks to professional
              chefs, all united by their love for quality rice.
            </p>
          </div>

          <div>
            <h3 className="text-xl font-bold text-[#2C1F0E] mb-2">
              The Joy World of Rice Today
            </h3>
            <p className="text-[#6B6B6B] leading-relaxed">
              Today, we serve over 5,000 families across India, delivering
              premium rice varieties right to their doorsteps. Our commitment to
              quality, tradition, and customer satisfaction remains unwavering.
            </p>
          </div>
        </div>

        <div className="bg-[#1A5C38] px-6 py-8 rounded-xl">
          <div className="text-center text-white">
            <h2 className="text-xl mb-1">
              STAY <span className="text-[#D4A017]">UPDATED</span>
            </h2>
            <p className="text-sm mb-4 text-white/90">
              Subscribe to our newsletter
            </p>
            <div className="flex gap-2">
              <input
                type="email"
                placeholder="Enter your email"
                className="flex-1 px-4 py-3 rounded-lg text-gray-900 focus:outline-none focus:ring-2 focus:ring-[#D4A017]"
              />
              <button className="bg-[#D4A017] text-white px-6 py-3 rounded-lg font-medium hover:bg-[#c49015] transition-colors">
                SUBSCRIBE
              </button>
            </div>
          </div>
        </div>
      </div>

      <BottomNav />
    </div>
  );
}
