import { useState, useEffect } from 'react';
import PageShell from '../components/PageShell';
import GlassCard from '../components/GlassCard';
import { Camera, Calendar, Info } from 'lucide-react';

type NasaPhoto = {
  title: string;
  date: string;
  explanation: string;
  hdurl: string;
  thumbnailUrl: string;
  copyright: string;
};

type RecentPhoto = {
  id: string | number;
  title: string;
  date: string;
  thumbnail: string;
};

export default function NasaPhotoPage() {
  const [photoData, setPhotoData] = useState<NasaPhoto | null>(null);
  const [recentPhotos, setRecentPhotos] = useState<RecentPhoto[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    async function fetchAPOD() {
      try {
        const today = new Date().toISOString().split('T')[0];

        const res = await fetch('/api/viewAPOD', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            accessToken: localStorage.getItem('token'),
            date: today
          })
        });
        const data = await res.json();
        if (data.success) {
          setPhotoData({
            title: data.title,
            date: today,
            explanation: data.explanation,
            hdurl: data.hdurl,
            thumbnailUrl: data.thumbnailUrl,
            copyright: data.copyright
          });
        }

        const recentRes = await fetch('/api/recentAPODs', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            accessToken: localStorage.getItem('token'),
            limit: 3
          })
        });
        const recentData = await recentRes.json();
        if (recentData.success) {
          setRecentPhotos(
            recentData.photos.map((p: any, i: number) => ({
              id: i,
              title: p.title,
              date: p.date,
              thumbnail: p.thumbnailUrl
            }))
          );
        }
      } catch (error) {
        console.error('Failed to fetch NASA photos:', error);
      } finally {
        setLoading(false);
      }
    }

    fetchAPOD();
  }, []);

  const photoLoaded = !!photoData;
  const recentPhotosLoaded = recentPhotos.length > 0;

  return (
    <PageShell title="NASA Photo of the Day" subtitle="Explore the cosmos through NASA's lens">
      <div style={{ display: 'grid', gap: 16 }}>

        {/* Main Photo */}
        <GlassCard style={{ padding: 16 }}>
          {loading ? (
            <div style={{ color: 'rgba(255,255,255,0.6)' }}>Loading NASA photo...</div>
          ) : photoLoaded ? (  
            <>
              <div style={{ marginBottom: 8 }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'start' }}>
                  <strong style={{ fontSize: '1.5rem', color: 'white' }}>{photoData.title}</strong>
                  <div style={{ display: 'flex', alignItems: 'center', gap: 4, color: 'rgba(255,255,255,0.6)' }}>
                    <Calendar style={{ width: 16, height: 16 }} />
                    <span style={{ fontSize: '0.875rem' }}>{photoData.date}</span>
                  </div>
                </div>
              </div>

              <div style={{ borderRadius: 12, overflow: 'hidden', marginBottom: 8 }}>
                <img src={photoData.hdurl} alt={photoData.title} style={{ width: '100%', display: 'block' }} />
              </div>

              <div style={{ display: 'grid', gap: 12 }}>
                <div style={{ display: 'flex', gap: 8, padding: 8, borderRadius: 8, background: 'rgba(255,255,255,0.05)' }}>
                  <Info style={{ width: 20, height: 20, color: '#3b82f6', flexShrink: 0, marginTop: 2 }} />
                  <div>
                    <strong>About this image</strong>
                    <p style={{ color: 'rgba(255,255,255,0.8)', lineHeight: 1.5 }}>{photoData.explanation}</p>
                  </div>
                </div>

                <div style={{ display: 'flex', alignItems: 'center', gap: 4, color: 'rgba(255,255,255,0.6)', fontSize: 12 }}>
                  <Camera style={{ width: 16, height: 16 }} />
                  <span>{photoData.copyright}</span>
                </div>
              </div>
           </>
          ) : (
            <div style={{ color: 'rgba(255,255,255,0.6)' }}>No photo available.</div>
          )}  
          </GlassCard>

        {/* Recent Photos */}
        {/* <GlassCard style={{ padding: 16 }}>
          <h2 style={{ color: 'white', fontSize: '1.25rem', marginBottom: 8 }}>Recent Photos</h2>
          <div style={{ display: 'grid', gap: 12, gridTemplateColumns: 'repeat(auto-fit, minmax(200px, 1fr))' }}>
            {recentPhotosLoaded ? (
              recentPhotos.map((photo) => (
                <div key={photo.id} style={{ borderRadius: 8, overflow: 'hidden', background: 'rgba(255,255,255,0.05)', cursor: 'pointer', transition: '0.3s' }}>
                  <div style={{ aspectRatio: '16/9', overflow: 'hidden' }}>
                    <img src={photo.thumbnail} alt={photo.title} style={{ width: '100%', height: '100%', objectFit: 'cover', transition: 'transform 0.3s' }} />
                  </div>
                  <div style={{ padding: 8 }}>
                    <h3 style={{ color: 'white', marginBottom: 2 }}>{photo.title}</h3>
                    <p style={{ color: 'rgba(255,255,255,0.6)', fontSize: 12 }}>{photo.date}</p>
                  </div>
                </div>
              ))
            ) : (
              <div style={{ color: 'rgba(255,255,255,0.6)' }}>Loading recent photos...</div>
            )}
          </div>
        </GlassCard> */}

      </div>
    </PageShell>
  );
}

