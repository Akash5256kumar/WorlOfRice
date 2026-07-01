import { Header } from '../components/Header';
import { BottomNav } from '../components/BottomNav';
import { Mail, Phone, MapPin, Send } from 'lucide-react';

export function Contact() {
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
        <h1 className="text-3xl font-bold text-white relative z-10">CONTACT</h1>
      </div>

      <div className="p-4 space-y-4">
        <div>
          <h2 className="text-2xl font-bold text-[#2C1F0E] mb-4">
            GET IN TOUCH
          </h2>

          <div className="space-y-3">
            <div className="bg-[#1C3557] text-white rounded-xl p-4 flex items-start gap-3">
              <div className="w-10 h-10 bg-white/10 rounded-full flex items-center justify-center flex-shrink-0">
                <Mail className="w-5 h-5" />
              </div>
              <div>
                <h3 className="font-medium mb-1">Email</h3>
                <p className="text-sm text-white/80">theworldofrice@gmail.com</p>
              </div>
            </div>

            <div className="bg-[#1C3557] text-white rounded-xl p-4 flex items-start gap-3">
              <div className="w-10 h-10 bg-white/10 rounded-full flex items-center justify-center flex-shrink-0">
                <Phone className="w-5 h-5" />
              </div>
              <div>
                <h3 className="font-medium mb-1">Phone</h3>
                <p className="text-sm text-white/80">+91 98109 61282</p>
              </div>
            </div>

            <div className="bg-[#1C3557] text-white rounded-xl p-4 flex items-start gap-3">
              <div className="w-10 h-10 bg-white/10 rounded-full flex items-center justify-center flex-shrink-0">
                <MapPin className="w-5 h-5" />
              </div>
              <div>
                <h3 className="font-medium mb-1">Headquarters</h3>
                <p className="text-sm text-white/80">
                  123 Rice Street, Heritage Colony
                  <br />
                  Mumbai, Maharashtra 400001
                </p>
              </div>
            </div>

            <div className="bg-[#1C3557] text-white rounded-xl p-4 flex items-start gap-3">
              <div className="w-10 h-10 bg-white/10 rounded-full flex items-center justify-center flex-shrink-0">
                <MapPin className="w-5 h-5" />
              </div>
              <div>
                <h3 className="font-medium mb-1">Second Store</h3>
                <p className="text-sm text-white/80">
                  456 Grain Avenue, Food District
                  <br />
                  Delhi, 110001
                </p>
              </div>
            </div>
          </div>
        </div>

        <div className="bg-white rounded-xl p-4">
          <h2 className="text-xl font-bold text-[#2C1F0E] mb-4">
            Send us a message
          </h2>

          <form className="space-y-3">
            <div className="grid grid-cols-2 gap-3">
              <input
                type="text"
                placeholder="First Name"
                className="px-4 py-3 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-[#1A5C38] focus:border-transparent"
              />
              <input
                type="text"
                placeholder="Last Name"
                className="px-4 py-3 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-[#1A5C38] focus:border-transparent"
              />
            </div>

            <input
              type="email"
              placeholder="Email"
              className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-[#1A5C38] focus:border-transparent"
            />

            <input
              type="tel"
              placeholder="Phone"
              className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-[#1A5C38] focus:border-transparent"
            />

            <textarea
              placeholder="Message"
              rows={4}
              className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-[#1A5C38] focus:border-transparent resize-none"
            />

            <button
              type="submit"
              className="w-full bg-[#1A5C38] text-white py-3 rounded-lg font-medium hover:bg-[#155030] transition-colors flex items-center justify-center gap-2"
            >
              SUBMIT
              <Send className="w-5 h-5" />
            </button>
          </form>
        </div>

        <div className="bg-gray-300 rounded-xl h-48 flex items-center justify-center">
          <p className="text-gray-600">Map Placeholder</p>
        </div>
      </div>

      <BottomNav />
    </div>
  );
}
