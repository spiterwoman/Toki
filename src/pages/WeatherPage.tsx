import { Sunrise, Sunset, Calendar, Droplets, Wind, Eye, Gauge } from 'lucide-react';
import PageShell from '../components/PageShell';
import GlassCard from '../components/GlassCard';

const mockWeatherData = {
  current: {
    emoji: '☀️',
    condition: 'Sunny',
    temperature: 75,
    feelsLike: 73,
    humidity: 45,
    windSpeed: 8,
    visibility: 10,
    pressure: 1013,
    sunrise: '7:12 AM',
    sunset: '7:45 PM',
  },
  hourly: [
    { time: '9 AM', temp: 72, emoji: '☀️' },
    { time: '12 PM', temp: 78, emoji: '☀️' },
    { time: '3 PM', temp: 82, emoji: '🌤️' },
    { time: '6 PM', temp: 76, emoji: '🌤️' },
    { time: '9 PM', temp: 70, emoji: '🌙' },
  ],
  weekly: [
    { day: 'Mon', high: 82, low: 68, emoji: '☀️' },
    { day: 'Tue', high: 79, low: 66, emoji: '⛅' },
    { day: 'Wed', high: 75, low: 64, emoji: '🌧️' },
    { day: 'Thu', high: 73, low: 62, emoji: '🌧️' },
    { day: 'Fri', high: 76, low: 65, emoji: '⛅' },
    { day: 'Sat', high: 80, low: 67, emoji: '☀️' },
    { day: 'Sun', high: 83, low: 69, emoji: '☀️' },
  ],
};

export default function WeatherPage() {
  return (
    <>
      <style>
        {`
          @media (max-width: 768px) {
            .weather-grid {
              grid-template-columns: 1fr !important;
              text-align: center;
            }
          }
        `}
      </style>

      <PageShell title="Weather" subtitle="Orlando, Florida">
        <div className="vstack" style={{ gap: 24, paddingTop: 24 }}>
          <div className="vstack" style={{ gap: 24 }}>
            {/* CURRENT WEATHER */}
            <GlassCard style={{ padding: 32, marginBottom: 24 }}>
              <div
                className="weather-grid"
                style={{
                  display: 'grid',
                  gridTemplateColumns: '1fr 1fr',
                  gap: 32,
                  alignItems: 'center',
                }}
              >
                {/* Left column */}
                <div style={{ textAlign: 'center' }}>
                  <div
                    style={{
                      display: 'flex',
                      justifyContent: 'center',
                      alignItems: 'center',
                      gap: 24,
                      marginBottom: 16,
                      flexWrap: 'wrap',
                    }}
                  >
                    <div style={{ fontSize: '6rem' }}>{mockWeatherData.current.emoji}</div>
                    <div>
                      <div style={{ fontSize: '4rem', color: 'white' }}>
                        {mockWeatherData.current.temperature}°
                      </div>
                      <div style={{ color: 'rgba(255,255,255,0.6)' }}>
                        Feels like {mockWeatherData.current.feelsLike}°
                      </div>
                    </div>
                  </div>

                  <div style={{ fontSize: '2rem', marginBottom: 8 }}>
                    {mockWeatherData.current.condition}
                  </div>
                  <div
                    style={{
                      display: 'flex',
                      justifyContent: 'center',
                      gap: 16,
                      color: 'rgba(255,255,255,0.6)',
                    }}
                  >
                    <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
                      <Sunrise size={16} />
                      <span>{mockWeatherData.current.sunrise}</span>
                    </div>
                    <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
                      <Sunset size={16} />
                      <span>{mockWeatherData.current.sunset}</span>
                    </div>
                  </div>
                </div>

                {/* Right column (stats) */}
                <div
                  style={{
                    display: 'grid',
                    gridTemplateColumns: '1fr 1fr',
                    gap: 16,
                  }}
                >
                  {[
                    {
                      label: 'Humidity',
                      value: `${mockWeatherData.current.humidity}%`,
                      icon: <Droplets size={16} color="#60a5fa" />,
                    },
                    {
                      label: 'Wind Speed',
                      value: `${mockWeatherData.current.windSpeed} mph`,
                      icon: <Wind size={16} color="#34d399" />,
                    },
                    {
                      label: 'Visibility',
                      value: `${mockWeatherData.current.visibility} mi`,
                      icon: <Eye size={16} color="#a78bfa" />,
                    },
                    {
                      label: 'Pressure',
                      value: `${mockWeatherData.current.pressure} mb`,
                      icon: <Gauge size={16} color="#facc15" />,
                    },
                  ].map((item, i) => (
                    <div
                      key={i}
                      style={{
                        background: 'rgba(255,255,255,0.05)',
                        borderRadius: 12,
                        padding: 16,
                      }}
                    >
                      <div
                        style={{
                          display: 'flex',
                          alignItems: 'center',
                          gap: 8,
                          marginBottom: 8,
                        }}
                      >
                        {item.icon}
                        <span style={{ fontSize: 14, opacity: 0.8 }}>{item.label}</span>
                      </div>
                      <div style={{ fontSize: '1.5rem', color: 'white' }}>{item.value}</div>
                    </div>
                  ))}
                </div>
              </div>
            </GlassCard>

            {/* HOURLY FORECAST */}
            <GlassCard style={{ padding: 24, marginBottom: 24 }}>
              <div style={{ fontWeight: 'bold' }}>Hourly Forecast</div>
              <div
                style={{
                  display: 'flex',
                  gap: 16,
                  overflowX: 'auto',
                  paddingBottom: 8,
                  marginTop: 16,
                }}
              >
                {mockWeatherData.hourly.map((hour, i) => (
                  <div
                    key={i}
                    style={{
                      background: 'rgba(255,255,255,0.05)',
                      borderRadius: 12,
                      padding: 16,
                      textAlign: 'center',
                      minWidth: 100,
                      transition: 'background 0.2s',
                    }}
                    onMouseEnter={(e) =>
                      (e.currentTarget.style.background = 'rgba(255,255,255,0.1)')
                    }
                    onMouseLeave={(e) =>
                      (e.currentTarget.style.background = 'rgba(255,255,255,0.05)')
                    }
                  >
                    <div style={{ color: 'rgba(255,255,255,0.6)', marginBottom: 8 }}>
                      {hour.time}
                    </div>
                    <div style={{ fontSize: '2rem', marginBottom: 8 }}>{hour.emoji}</div>
                    <div style={{ fontSize: '1.25rem', color: 'white' }}>{hour.temp}°</div>
                  </div>
                ))}
              </div>
            </GlassCard>

            {/* WEEKLY FORECAST */}
            <GlassCard style={{ padding: 24 }}>
              <div
                style={{
                  display: 'flex',
                  alignItems: 'center',
                  gap: 8,
                  fontWeight: 'bold',
                  marginBottom: 16,
                }}
              >
                <Calendar size={20} color="#fff" />
                7-Day Forecast
              </div>

              <div style={{ display: 'flex', flexDirection: 'column', gap: 12 }}>
                {mockWeatherData.weekly.map((day, i) => (
                  <div
                    key={i}
                    style={{
                      display: 'flex',
                      justifyContent: 'space-between',
                      alignItems: 'center',
                      background: 'rgba(255,255,255,0.05)',
                      borderRadius: 12,
                      padding: 16,
                      transition: 'background 0.2s',
                    }}
                    onMouseEnter={(e) =>
                      (e.currentTarget.style.background = 'rgba(255,255,255,0.1)')
                    }
                    onMouseLeave={(e) =>
                      (e.currentTarget.style.background = 'rgba(255,255,255,0.05)')
                    }
                  >
                    <div style={{ display: 'flex', alignItems: 'center', gap: 16 }}>
                      <div style={{ width: 48 }}>{day.day}</div>
                      <div style={{ fontSize: '1.5rem' }}>{day.emoji}</div>
                    </div>
                    <div style={{ display: 'flex', gap: 24 }}>
                      <div style={{ display: 'flex', gap: 4 }}>
                        <span style={{ color: 'rgba(255,255,255,0.6)', fontSize: 14 }}>High</span>
                        <span style={{ color: 'white', fontSize: 16 }}>{day.high}°</span>
                      </div>
                      <div style={{ display: 'flex', gap: 4 }}>
                        <span style={{ color: 'rgba(255,255,255,0.6)', fontSize: 14 }}>Low</span>
                        <span style={{ color: 'rgba(255,255,255,0.6)', fontSize: 16 }}>
                          {day.low}°
                        </span>
                      </div>
                    </div>
                  </div>
                ))}
              </div>
            </GlassCard>
          </div>
        </div>
      </PageShell>
    </>
  );
}
