import GlassCard from '../components/GlassCard';
import { Calendar, Cloud, Sun, Sunrise, Sunset, Bell, CheckCircle2 } from 'lucide-react';
import React from "react";
import { useState } from "react";
import PageShell from "../components/PageShell";

const mockData = {
  date: 'Thursday, October 9, 2025',
  weather: {
    emoji: '☀️',
    condition: 'Sunny',
    high: 82,
    low: 68,
    sunrise: '7:12 AM',
    sunset: '7:45 PM',
  },
  tasks: [
    { id: 1, title: 'Team standup meeting', time: '9:00 AM', priority: 'high', completed: true },
    { id: 2, title: 'Review project proposal', time: '11:00 AM', priority: 'high', completed: false },
    { id: 3, title: 'Lunch with Sarah', time: '12:30 PM', priority: 'medium', completed: false },
  ],
  events: [
    { id: 1, title: 'Product Launch', time: '2:00 PM', location: 'Conference Room A' },
    { id: 2, title: 'Design Review', time: '4:00 PM', location: 'Virtual' },
  ],
  reminders: [
    { id: 1, text: 'Submit expense report' },
    { id: 2, text: 'Call dentist for appointment' },
    { id: 3, text: 'Pick up dry cleaning' },
  ],
  nasaPhoto: 'https://images.unsplash.com/photo-1642635715930-b3a1eba9c99f?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxzcGFjZSUyMHN0YXJzJTIwbmVidWxhfGVufDF8fHx8MTc1OTk3OTAxMXww&ixlib=rb-4.1.0&q=80&w=1080',
};

export default function DailySummaryPage() {
  const [tasks, setTasks] = useState(mockData.tasks);
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
    setTasks((prev) => prev.map((t) => (t.id === id ? { ...t, completed: !t.completed } : t)));
  }

  return (
    <PageShell title= "Good Morning, Astronaut" subtitle={mockData.date}>
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
                <div style={{ fontSize: 48 }}>{mockData.weather.emoji}</div>  
                <div>{mockData.weather.condition}</div>  
                <div className="hstack" style={{ gap: 24 }}>  
                  <div className="vstack" style={{ gap: 2 }}>  
                    <div>High</div>  
                    <div style={{ fontSize: 20 }}>{mockData.weather.high}°</div>  
                  </div>  
                  <div className="vstack" style={{ gap: 2 }}>  
                    <div>Low</div>  
                    <div style={{ fontSize: 20 }}>{mockData.weather.low}°</div>  
                  </div>  
                </div>  
                <div className="hstack" style={{ gap: 24, fontSize: 12, color: "var(--muted)" }}>  
                  <div className="hstack" style={{ gap: 4, alignItems: "center" }}>  
                    <Sunrise className="w-4 h-4" /> <span>{mockData.weather.sunrise}</span>  
                  </div>  
                  <div className="hstack" style={{ gap: 4, alignItems: "center" }}>  
                    <Sunset className="w-4 h-4" /> <span>{mockData.weather.sunset}</span>  
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
            </GlassCard>  

            {/* Events Card */}  
            <GlassCard className="vstack" style={{ padding: 16 }}>  
              <div className="hstack" style={{ gap: 8, alignItems: "center" }}>  
                <Calendar className="w-5 h-5" style={{ color: "#d8b4fe" }} />  
                <strong>Today's Events</strong>  
              </div>  
              <div className="vstack" style={{ gap: 12, marginTop: 12 }}>  
                {mockData.events.map((e) => (  
                  <div className="list-item" key={e.id} style={{ padding: 16 }}>  
                    <div className="vstack" style={{ gap: 4 }}>
                      <div style={{ fontSize: 16, fontWeight: 500 }}>{e.title}</div>  
                      <div style={{ fontSize: 14, color: "var(--muted)" }}>{e.time}</div>
                      <div style={{ fontSize: 14, color: "var(--muted)" }}>{e.location}</div>
                    </div>
                  </div>  
                ))}  
              </div>  
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
              <div className="list" style={{ marginTop: 12 }}>  
                {mockData.reminders.map((r) => (  
                  <div className="list-item" key={r.id}>  
                    <div className="hstack" style={{ gap: 8, alignItems: "center" }}>  
                      <div style={{ width: 8, height: 8, borderRadius: "50%", background: "#facc15", flexShrink: 0 }} />  
                      <div>{r.text}</div>  
                    </div>  
                  </div>  
                ))}  
              </div>  
            </GlassCard>  

            {/* NASA Photo Card */}  
            <GlassCard className="vstack" style={{ padding: 16 }} >  
              <div className="hstack" style={{ gap: 8, alignItems: "center" }}>  
                <Sun className="w-5 h-5" style={{ color: "#fdba74" }} />  
                <strong>NASA Photo of the Day</strong>  
              </div>  
              <div className="vstack" style={{ marginTop: 12 }}>  
                <div style={{ position: "relative", paddingTop: "56.25%", borderRadius: 8, overflow: "hidden" }}>  
                  <img src={mockData.nasaPhoto} alt="NASA Photo of the Day" style={{ position: "absolute", top: 0, left: 0, width: "100%", height: "100%", objectFit: "cover" }} />  
                </div>  
                <p style={{ color: "var(--muted)", marginTop: 8, fontSize: 14 }}>A stunning view of the cosmos captured by NASA's telescopes</p>  
              </div>  
            </GlassCard>  

          </div>
        </div>
      </div>  
    </PageShell>  
  );
}