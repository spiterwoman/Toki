import PageShell from '../components/PageShell';
import GlassCard from '../components/GlassCard';
import { Camera, Calendar, Info } from 'lucide-react';

const mockNasaData = {
  title: 'The Magnificent Nebula NGC 6302',
  date: 'October 9, 2025',
  explanation:
    'The bright clusters and nebulae of planet Earth\'s night sky are often named for flowers or insects. Though its wingspan covers over 3 light-years, NGC 6302 is no exception. With an estimated surface temperature of about 250,000 degrees C, the dying central star of this particular planetary nebula has become exceptionally hot, shining brightly in ultraviolet light but hidden from direct view by a dense torus of dust.',
  url: 'https://images.unsplash.com/photo-1642635715930-b3a1eba9c99f?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxzcGFjZSUyMHN0YXJzJTIwbmVidWxhfGVufDF8fHx8MTc1OTk3OTAxMXww&ixlib=rb-4.1.0&q=80&w=1080',
  copyright: 'NASA/ESA Hubble Space Telescope',
};

const recentPhotos = [
  { id: 1, title: 'Jupiter\'s Great Red Spot', date: 'Oct 8, 2025', thumbnail: 'https://images.unsplash.com/photo-1614732484003-ef9881555dc3?w=400' },
  { id: 2, title: 'Andromeda Galaxy', date: 'Oct 7, 2025', thumbnail: 'https://images.unsplash.com/photo-1543722530-d2c3201371e7?w=400' },
  { id: 3, title: 'Saturn\'s Rings', date: 'Oct 6, 2025', thumbnail: 'https://images.unsplash.com/photo-1614313913007-2b4ae8ce32d6?w=400' },
];

export default function NasaPhotoPage() {
  return (
    <PageShell title="NASA Photo of the Day" subtitle="Explore the cosmos through NASA's lens">
      <div style={{ display: 'grid', gap: 16 }}>

        {/* Main Photo */}
        <GlassCard style={{ padding: 16 }}>
          <div style={{ marginBottom: 8 }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'start' }}>
              <strong style={{ fontSize: '1.5rem', color: 'white' }}>{mockNasaData.title}</strong>
              <div style={{ display: 'flex', alignItems: 'center', gap: 4, color: 'rgba(255,255,255,0.6)' }}>
                <Calendar style={{ width: 16, height: 16 }} />
                <span style={{ fontSize: '0.875rem' }}>{mockNasaData.date}</span>
              </div>
            </div>
          </div>

          <div style={{ borderRadius: 12, overflow: 'hidden', marginBottom: 8 }}>
            <img src={mockNasaData.url} alt={mockNasaData.title} style={{ width: '100%', display: 'block' }} />
          </div>

          <div style={{ display: 'grid', gap: 12 }}>
            <div style={{ display: 'flex', gap: 8, padding: 8, borderRadius: 8, background: 'rgba(255,255,255,0.05)' }}>
              <Info style={{ width: 20, height: 20, color: '#3b82f6', flexShrink: 0, marginTop: 2 }} />
              <div>
                <strong>About this image</strong>
                <p style={{ color: 'rgba(255,255,255,0.8)', lineHeight: 1.5 }}>{mockNasaData.explanation}</p>
              </div>
            </div>

            <div style={{ display: 'flex', alignItems: 'center', gap: 4, color: 'rgba(255,255,255,0.6)', fontSize: 12 }}>
              <Camera style={{ width: 16, height: 16 }} />
              <span>{mockNasaData.copyright}</span>
            </div>
          </div>
        </GlassCard>

        {/* Recent Photos */}
        <GlassCard style={{ padding: 16 }}>
          <h2 style={{ color: 'white', fontSize: '1.25rem', marginBottom: 8 }}>Recent Photos</h2>
          <div style={{ display: 'grid', gap: 12, gridTemplateColumns: 'repeat(auto-fit, minmax(200px, 1fr))' }}>
            {recentPhotos.map((photo) => (
              <div key={photo.id} style={{ borderRadius: 8, overflow: 'hidden', background: 'rgba(255,255,255,0.05)', cursor: 'pointer', transition: '0.3s' }}>
                <div style={{ aspectRatio: '16/9', overflow: 'hidden' }}>
                  <img src={photo.thumbnail} alt={photo.title} style={{ width: '100%', height: '100%', objectFit: 'cover', transition: 'transform 0.3s' }} />
                </div>
                <div style={{ padding: 8 }}>
                  <h3 style={{ color: 'white', marginBottom: 2 }}>{photo.title}</h3>
                  <p style={{ color: 'rgba(255,255,255,0.6)', fontSize: 12 }}>{photo.date}</p>
                </div>
              </div>
            ))}
          </div>
        </GlassCard>

      </div>
    </PageShell>
  );
}

