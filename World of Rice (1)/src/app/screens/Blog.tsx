import { Header } from '../components/Header';
import { BottomNav } from '../components/BottomNav';
import { Calendar, ArrowRight } from 'lucide-react';

const blogs = [
  {
    id: 1,
    category: 'Health',
    title: '5 Amazing Health Benefits of Brown Rice',
    excerpt:
      'Discover why brown rice is considered a superfood and how it can improve your overall health and wellness.',
    date: 'May 1, 2026',
    image: 'https://images.unsplash.com/photo-1615485290382-441e4d049cb5?w=800&q=80',
  },
  {
    id: 2,
    category: 'Tips',
    title: 'The Perfect Way to Cook Basmati Rice',
    excerpt:
      'Learn the traditional method of cooking basmati rice for fluffy, aromatic perfection every time.',
    date: 'April 28, 2026',
    image: 'https://images.unsplash.com/photo-1586201375761-83865001e31c?w=800&q=80',
  },
  {
    id: 3,
    category: 'Health',
    title: 'Heritage Rice Varieties and Their Nutritional Value',
    excerpt:
      'Explore the rich nutritional profile of traditional rice varieties and why they matter for your diet.',
    date: 'April 25, 2026',
    image: 'https://images.unsplash.com/photo-1603048297172-c92544798d5a?w=800&q=80',
  },
];

export function Blog() {
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
        <h1 className="text-3xl font-bold text-white relative z-10">BLOGS</h1>
      </div>

      <div className="p-4">
        <div className="text-center mb-6">
          <p className="text-xs text-[#1A5C38] tracking-widest mb-1">
            FROM OUR KITCHEN
          </p>
          <h2 className="text-2xl font-bold">
            BLOG <span className="text-[#1A5C38]">POST</span>
          </h2>
          <p className="text-sm text-[#6B6B6B] mt-2">
            Tips, recipes, and stories about rice
          </p>
        </div>

        <div className="space-y-4">
          {blogs.map((blog) => (
            <div key={blog.id} className="bg-white rounded-xl overflow-hidden shadow-sm">
              <img
                src={blog.image}
                alt={blog.title}
                className="w-full h-48 object-cover"
              />
              <div className="p-4">
                <span
                  className={`inline-block px-3 py-1 rounded-full text-xs font-medium mb-3 ${
                    blog.category === 'Health'
                      ? 'bg-[#1A5C38] text-white'
                      : 'bg-[#E74C1F] text-white'
                  }`}
                >
                  {blog.category}
                </span>

                <div className="flex items-center gap-2 text-sm text-[#6B6B6B] mb-2">
                  <Calendar className="w-4 h-4" />
                  <span>{blog.date}</span>
                </div>

                <h3 className="text-lg font-bold text-[#1A5C38] mb-2 hover:underline cursor-pointer">
                  {blog.title}
                </h3>

                <p className="text-[#6B6B6B] text-sm mb-3">{blog.excerpt}</p>

                <button className="text-[#1A5C38] font-medium text-sm flex items-center gap-1 hover:gap-2 transition-all">
                  Read More
                  <ArrowRight className="w-4 h-4" />
                </button>
              </div>
            </div>
          ))}
        </div>

        <div className="bg-[#1A5C38] px-6 py-8 rounded-xl mt-8">
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
