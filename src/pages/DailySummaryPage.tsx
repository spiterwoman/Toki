import GlassCard from '../components/GlassCard';
import { Calendar, Cloud, Sun, Sunrise, Sunset, Bell, CheckCircle2 } from 'lucide-react';
import React, { use } from "react";
import { useState } from "react";
import PageShell from "../components/PageShell";

export default function DailySummaryPage() {
  const [date, setDate] = useState('');
  const [weather, setWeather] = useState({
    emoji: '',
    condition: '',
    high: null,
    low: null,
    sunrise: '',
    sunset: '',
  });

  const [tasks, setTasks] = useState([]);
  const [events, setEvents] = useState([]);
  const [reminders, setReminders] = useState([]);
  const [nasaPhoto, setNasaPhoto] = useState('');
  
  const [isSmallScreen, setIsSmallScreen] = useState(false);

  React.useEffect(() => {
    const checkScreenSize = () => {
      setIsSmallScreen(window.innerWidth < 1024);
    };
    
    checkScreenSize();
    window.addEventListener('resize', checkScreenSize);
    
    return () => window.removeEventListener('resize', checkScreenSize);
  }, []);

  function toggleTask(id) {
    setTasks(prev => prev.map(t => t.id === id ? { ...t, completed: !t.completed } : t));
  }

  const tasksLoaded = tasks.length > 0;
  const eventsLoaded = events.length > 0;
  const remindersLoaded = reminders.length > 0;
  const nasaLoaded = nasaPhoto !== '';

  return (
    <PageShell title= "Hello, Astronaut" subtitle={date || 'Loading date...'}>
      <div className="vstack" style={{ gap: 24, paddingTop: 24 }}>

        <div className="vstack" style={{ gap: 24 }}>
          <div style={{ 
            display: "grid", 
            gridTemplateColumns: isSmallScreen ? "1fr" : "repeat(3, 1fr)", 
            gap: 24 
          }}>  

            {/* Weather Card */}  
            <GlassCard className="vstack" style={{ padding: 16 }}>  
              <div className="hstack" style={{ gap: 8, alignItems: "center" }}>  
                <Cloud className="w-5 h-5" style={{ color: "#93c5fd" }} />  
                <strong>Today's Weather</strong>  
              </div>  
              <div className="vstack" style={{ alignItems: "center", gap: 8, marginTop: 12 }}>  
                <div style={{ fontSize: 48 }}>{weather.emoji}</div>  
                <div>{weather.condition || 'Loading weather...'}</div>  
                <div className="hstack" style={{ gap: 24 }}>  
                  <div className="vstack" style={{ gap: 2 }}>  
                    <div>High</div>  
                    <div style={{ fontSize: 20 }}>{weather.high || '--'}°</div>  
                  </div>  
                  <div className="vstack" style={{ gap: 2 }}>  
                    <div>Low</div>  
                    <div style={{ fontSize: 20 }}>{weather.low || '--'}°</div>  
                  </div>  
                </div>  
                <div className="hstack" style={{ gap: 24, fontSize: 12, color: "var(--muted)" }}>  
                  <div className="hstack" style={{ gap: 4, alignItems: "center" }}>  
                    <Sunrise className="w-4 h-4" /> <span>{weather.sunrise || '--:--'}</span>  
                  </div>  
                  <div className="hstack" style={{ gap: 4, alignItems: "center" }}>  
                    <Sunset className="w-4 h-4" /> <span>{weather.sunset || '--:--'}</span>  
                  </div>  
                </div>  
              </div>  
            </GlassCard>  

            {/* Tasks Card */}  
            <GlassCard className="vstack" style={{ padding: 16 }}>  
              <div className="hstack" style={{ gap: 8, alignItems: "center" }}>  
                <CheckCircle2 className="w-5 h-5" style={{ color: "#86efac" }} />  
                <strong>Today's Tasks</strong>  
              </div>  
              {tasksLoaded ? (
                <div className="list" style={{ marginTop: 12 }}>  
                  {tasks.map((t) => (  
                    <div className="list-item" key={t.id}>  
                      <div className="hstack" style={{ gap: 12 }}>  
                        <input type="checkbox" checked={t.completed} onChange={() => toggleTask(t.id)} />  
                        <div className="vstack" style={{ gap: 4 }}>  
                          <div style={{ fontWeight: 600, textDecoration: t.completed ? "line-through" : "none", opacity: t.completed ? 0.5 : 1 }}>{t.title}</div>  
                          <div style={{ color: "var(--muted)", opacity: t.completed ? 0.5 : 1 }}>{t.time}</div>  
                        </div>  
                      </div>  
                      <span className={t.priority === "high" ? "badge danger" : t.priority === "medium" ? "badge warn" : "badge ok"}>{t.priority}</span>  
                    </div>  
                  ))}  
                </div> 
              ) : (
                <div style={{ color: 'rgba(255,255,255,0.6)' }}>No tasks yet.</div>
              )} 
            </GlassCard>  

            {/* Events Card */}  
            <GlassCard className="vstack" style={{ padding: 16 }}>  
              <div className="hstack" style={{ gap: 8, alignItems: "center" }}>  
                <Calendar className="w-5 h-5" style={{ color: "#d8b4fe" }} />  
                <strong>Today's Events</strong>  
              </div>  

              {eventsLoaded ? (
                <div className="vstack" style={{ gap: 12, marginTop: 12 }}>  
                  {events.map((e) => (  
                    <div className="list-item" key={e.id} style={{ padding: 16 }}>  
                      <div className="vstack" style={{ gap: 4 }}>
                        <div style={{ fontSize: 16, fontWeight: 500 }}>{e.title}</div>  
                        <div style={{ fontSize: 14, color: "var(--muted)" }}>{e.time}</div>
                        <div style={{ fontSize: 14, color: "var(--muted)" }}>{e.location}</div>
                      </div>
                    </div>  
                  ))}  
                </div>  
              ) : (
                <div style={{ color: 'rgba(255,255,255,0.6)', marginTop: 12 }}>No events today.</div>
              )}
            </GlassCard>  
          </div>

          <div style={{ 
            display: "grid", 
            gridTemplateColumns: isSmallScreen ? "1fr" : "minmax(300px, 1fr) 2fr", 
            gap: 24 
          }}>  

            {/* Reminders Card */}  
            <GlassCard className="vstack" style={{ padding: 16 }}>  
              <div className="hstack" style={{ gap: 8, alignItems: "center" }}>  
                <Bell className="w-5 h-5" style={{ color: "#fde047" }} />  
                <strong>Reminders</strong>  
              </div>  
              
              {remindersLoaded ? (
                <div className="list" style={{ marginTop: 12 }}>  
                  {reminders.map((r) => (  
                    <div className="list-item" key={r.id}>  
                      <div className="hstack" style={{ gap: 8, alignItems: "center" }}>  
                        <div style={{ width: 8, height: 8, borderRadius: "50%", background: "#facc15", flexShrink: 0 }} />  
                        <div>{r.text}</div>  
                      </div>  
                    </div>  
                  ))}  
                </div>
              ) : (
                <div style={{ color: 'rgba(255,255,255,0.6)', marginTop: 12 }}>No active reminders.</div>
              )}  
            </GlassCard>  

            {/* NASA Photo Card */}  
            <GlassCard className="vstack" style={{ padding: 16 }} >  
              <div className="hstack" style={{ gap: 8, alignItems: "center" }}>  
                <Sun className="w-5 h-5" style={{ color: "#fdba74" }} />  
                <strong>NASA Photo of the Day</strong>  
              </div>  

              {nasaLoaded ? (
                <div className="vstack" style={{ marginTop: 12 }}>  
                  <div style={{ position: "relative", paddingTop: "56.25%", borderRadius: 8, overflow: "hidden" }}>  
                    <img src={nasaPhoto} alt="{nasaTitle}" style={{ position: "absolute", top: 0, left: 0, width: "100%", height: "100%", objectFit: "cover" }} />  
                  </div>  
                  <p style={{ color: "var(--muted)", marginTop: 8, fontSize: 14 }}>{nasaTitle || 'Loading title...'}</p>  
                </div>  
              ) : (
                <div style={{ color: 'rgba(255,255,255,0.6)', marginTop: 12 }}>Loading NASA photo...</div>
              )}
            </GlassCard>  

          </div>
        </div>
      </div>  
    </PageShell>  
  );
}
