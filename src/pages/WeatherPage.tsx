import { useState } from 'react';
import { Sunrise, Sunset, Calendar, Droplets, Wind, Eye, Gauge } from 'lucide-react';
import PageShell from '../components/PageShell';
import GlassCard from '../components/GlassCard';

type CurrentWeather = {
  location: string;
  emoji: string;
  condition: string;
  temperature: number | null;
  feelsLike: number | null;
  humidity: number | null;
  windSpeed: number | null;
  visibility: number | null;
  pressure: number | null;
  sunrise: string;
  sunset: string;
};

type Hourly = { time: string; emoji: string; temp: number | string };
type Weekly = { day: string; emoji: string; high: number | string; low: number | string };

export default function WeatherPage() {

  const [weather] = useState<CurrentWeather>({
    location: '',
    emoji: '',
    condition: '',
    temperature: null,
    feelsLike: null,
    humidity: null,
    windSpeed: null,
    visibility: null,
    pressure: null,
    sunrise: '',
    sunset: '',
  });

  const [hourlyForecast] = useState<Hourly[]>([]);
  const [weeklyForecast] = useState<Weekly[]>([]);

  const formatValue = (value: number | string | null | undefined, placeholder = '--') =>
    value !== null && value !== undefined ? value : placeholder;

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

      <PageShell title="Weather" subtitle={weather.location || 'Loading location...'}>
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
                    <div style={{ fontSize: '6rem' }}>{weather.emoji}</div>
                    <div>
                      <div style={{ fontSize: '4rem', color: 'white' }}>
                        {formatValue(weather.temperature)}°
                      </div>
                      <div style={{ color: 'rgba(255,255,255,0.6)' }}>
                        Feels like {formatValue(weather.feelsLike)}°
                      </div>
                    </div>
                  </div>

                  <div style={{ fontSize: '2rem', marginBottom: 8 }}>
                    {weather.condition || 'Loading weather...'}
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
                      <span>{weather.sunrise || '--.--'}</span>
                    </div>
                    <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
                      <Sunset size={16} />
                      <span>{weather.sunset || '--.--'}</span>
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
                      value: `${formatValue(weather.humidity, '--')}%`,
                      icon: <Droplets size={16} color="#60a5fa" />,
                    },
                    {
                      label: 'Wind Speed',
                      value: `${formatValue(weather.windSpeed, '--')} mph`,
                      icon: <Wind size={16} color="#34d399" />,
                    },
                    {
                      label: 'Visibility',
                      value: `${formatValue(weather.visibility, '--')} mi`,
                      icon: <Eye size={16} color="#a78bfa" />,
                    },
                    {
                      label: 'Pressure',
                      value: `${formatValue(weather.pressure, '--')} mb`,
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
              {hourlyForecast.length === 0 ? (
                <div style={{ marginTop: 16, color: 'rgba(255,255,255,0.6)' }}>Loading hourly forecast...</div>
              ) : (
                <div
                  style={{
                    display: 'flex',
                    gap: 16,
                    overflowX: 'auto',
                    paddingBottom: 8,
                    marginTop: 16,
                  }}
                >
                  {hourlyForecast.map((hour, i) => (
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
              )}
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

              {weeklyForecast.length === 0 ? (
                <div style={{ color: 'rgba(255,255,255,0.6)' }}>Loading weekly forecast...</div>
              ) : (
                <div style={{ display: 'flex', flexDirection: 'column', gap: 12 }}>
                  {weeklyForecast.map((day, i) => (
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
              )}
            </GlassCard>
          </div>
        </div>
      </PageShell>
    </>
  );
}
