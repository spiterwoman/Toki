import { useEffect, useState } from "react";
import GlassCard from "../components/GlassCard";
import PageShell from "../components/PageShell";
import {
  Calendar,
  Cloud,
  Sun,
  Sunrise,
  Sunset,
  Bell,
  CheckCircle2,
} from "lucide-react";

type Task = {
  id: string;
  title: string;
  time?: string;
  priority?: "low" | "medium" | "high";
  completed?: boolean;
};

type EventItem = {
  id: string;
  title: string;
  time?: string;
  location?: string;
};

type Reminder = { id: string; text: string };

type Weather = {
  emoji: string;
  condition: string;
  high: number | null;
  low: number | null;
  sunrise: string;
  sunset: string;
};

// ------- helpers -------

function fmtDateKey(d: Date) {
  const year = d.getFullYear();
  const month = `${d.getMonth() + 1}`.padStart(2, "0");
  const day = `${d.getDate()}`.padStart(2, "0");
  return `${year}-${month}-${day}`;
}

function normalizeDateKey(value: any, fallback: string): string {
  if (!value) return fallback;

  if (value instanceof Date) return fmtDateKey(value);

  if (typeof value === "string") {
    const s = value.trim();

    // already yyyy-mm-dd
    if (/^\d{4}-\d{2}-\d{2}$/.test(s)) return s;

    // ISO / other parseable formats
    const parsed = new Date(s);
    if (!Number.isNaN(parsed.getTime())) return fmtDateKey(parsed);

    // fallback numeric chunks
    const parts = s.split(/[^0-9]/).filter(Boolean);
    if (parts.length >= 3) {
      const [y, m, d] = parts;
      const year = Number(y);
      const month = Number(m);
      const day = Number(d);
      if (year && month && day) {
        return fmtDateKey(new Date(year, month - 1, day));
      }
    }
  }

  return fallback;
}

function extractTime(value: any): string {
  if (!value || typeof value !== "string") return "";
  // ignore the dummy 1970 date the backend sends
  if (value.startsWith("1970-01-01")) return "";
  const match = value.match(/(\d{1,2}:\d{2})(?::\d{2})?/);
  if (!match) return "";
  return match[1]; // HH:MM
}

function fmt(val: string | number | null | undefined, fallback = "--") {
  return val === null || val === undefined || val === "" ? fallback : val;
}

const toNumber = (v: any): number | null => {
  if (typeof v === "number") return v;
  if (typeof v === "string" && v.trim()) {
    const n = Number(v);
    return Number.isFinite(n) ? n : null;
  }
  return null;
};

const conditionToEmoji = (condition: string | undefined) => {
  if (!condition) return "❓";
  const c = condition.toLowerCase();
  if (c.includes("sunny") || c.includes("clear")) return "☀️";
  if (c.includes("cloud")) return "☁️";
  if (c.includes("rain")) return "🌧️";
  if (c.includes("snow")) return "❄️";
  if (c.includes("thunder")) return "⛈️";
  if (c.includes("fog") || c.includes("mist")) return "🌫️";
  return "🌡️";
};

export default function DailySummaryPage() {
  const today = new Date();
  const todayKey = fmtDateKey(today);

  const [date, setDate] = useState("");
  const [weather, setWeather] = useState<Weather>({
    emoji: "",
    condition: "",
    high: null,
    low: null,
    sunrise: "",
    sunset: "",
  });

  const [tasks, setTasks] = useState<Task[]>([]);
  const [events, setEvents] = useState<EventItem[]>([]);
  const [reminders, setReminders] = useState<Reminder[]>([]);
  const [nasaPhoto, setNasaPhoto] = useState<string>("");
  const [isSmallScreen, setIsSmallScreen] = useState(false);

  useEffect(() => {
    const checkScreenSize = () => setIsSmallScreen(window.innerWidth < 1024);
    checkScreenSize();
    window.addEventListener("resize", checkScreenSize);
    return () => window.removeEventListener("resize", checkScreenSize);
  }, []);

  useEffect(() => {
    const label = today.toLocaleDateString(undefined, {
      weekday: "long",
      month: "long",
      day: "numeric",
    });
    setDate(label);
  }, [today]);

  useEffect(() => {
    const loadData = async () => {
      // ---- Weather ----
      try {
        const res = await fetch("/api/viewWeather", {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          credentials: "include",
          body: JSON.stringify({}),
        });

        if (!res.ok) {
          const text = await res.text();
          console.error("viewWeather failed:", res.status, text);
        } else {
          const data = await res.json();
          const w: any = (data && (data.weather || data)) || {};

          const condition: string = w.forecast || w.condition || "";
          const high = toNumber(w.high ?? w.temperature ?? w.current);
          const low = toNumber(w.low ?? w.minTemp);

          setWeather({
            emoji: conditionToEmoji(condition),
            condition,
            high,
            low,
            sunrise: w.sunrise || "",
            sunset: w.sunset || "",
          });
        }
      } catch (err) {
        console.error("Error loading weather for Daily Summary:", err);
      }

      // ---- NASA Photo of the Day (same logic as NASA page) ----
      try {
        const apiKey =
          (import.meta as any).env?.VITE_NASA_API_KEY || "DEMO_KEY";
        const url = `https://api.nasa.gov/planetary/apod?api_key=${encodeURIComponent(
          apiKey
        )}`;

        const res = await fetch(url);
        if (!res.ok) {
          const text = await res.text();
          console.warn(
            "NASA APOD not OK:",
            res.status,
            text.slice(0, 120)
          );
        } else {
          const data: any = await res.json();
          const photoUrl = (data.hdurl || data.url || "").trim();
          if (photoUrl) {
            setNasaPhoto(photoUrl);
          } else {
            console.warn("NASA APOD returned no image url:", data);
          }
        }
      } catch (err) {
        console.error("Error loading NASA photo for Daily Summary:", err);
      }

      // ---- Tasks ----
      try {
        const res = await fetch("/api/viewTask", {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          credentials: "include",
          body: JSON.stringify({ title: "" }), // blank => all
        });

        if (!res.ok) {
          const text = await res.text();
          console.error("viewTask failed:", res.status, text);
        } else {
          const data = await res.json();
          let raw: any[] = [];
          if (Array.isArray(data)) raw = data;
          else if (Array.isArray((data as any).tasks))
            raw = (data as any).tasks;

          const mapped: Task[] = raw.map((t: any, index: number) => {
            // NEW: support { completed: { isCompleted: true } }
            const completedObj = t.completed;
            const completedFromObj =
              completedObj && typeof completedObj === "object"
                ? completedObj.isCompleted === true
                : t.completed === true;

            const completedFromStatus =
              typeof t.status === "string" &&
              ["complete", "completed", "done"].includes(
                t.status.toLowerCase()
              );

            const completed = completedFromObj || completedFromStatus;

            let priority: Task["priority"] = "low";
            if (t.priority === "high") priority = "high";
            else if (t.priority === "medium") priority = "medium";

            const rawDue = t.dueDate;
            let time: string | undefined;
            if (typeof t.time === "string" && t.time.trim()) {
              time = t.time.trim();
            } else if (typeof rawDue === "string" && rawDue.trim()) {
              const extracted = extractTime(rawDue);
              if (extracted) time = extracted;
            }

            return {
              id:
                t.taskId ||
                t.id ||
                t._id ||
                `${t.title ?? "task"}-${index}`,
              title: t.title ?? "",
              time,
              priority,
              completed,
            };
          });

          setTasks(mapped);
        }
      } catch (err) {
        console.error("Error loading tasks for Daily Summary:", err);
      }

      // ---- Events ----
      try {
        const res = await fetch("/api/viewCalendarEvent", {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          credentials: "include",
          body: JSON.stringify({ title: "" }),
        });

        if (!res.ok) {
          const text = await res.text();
          console.error("viewCalendarEvent failed:", res.status, text);
        } else {
          const data = await res.json();
          let raw: any[] = [];
          if (Array.isArray(data)) raw = data;
          else if (Array.isArray((data as any).events))
            raw = (data as any).events;

          const mapped = raw
            .map((ev: any, index: number) => {
              const eventKey = normalizeDateKey(
                ev.date || ev.startDate || ev.endDate,
                todayKey
              );
              if (eventKey !== todayKey) return null;

              const item: EventItem = {
                id:
                  ev.eventId || ev.id || `${ev.title ?? "event"}-${index}`,
                title: ev.title ?? "",
                time:
                  ev.time || ev.startTime || extractTime(ev.startDate),
                location: ev.location || "",
              };
              return item;
            })
            .filter((e) => e !== null) as EventItem[];

          setEvents(mapped);
        }
      } catch (err) {
        console.error("Error loading events for Daily Summary:", err);
      }

      // ---- Reminders ----
      try {
        const res = await fetch("/api/viewReminder", {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          credentials: "include",
          body: JSON.stringify({ title: "" }),
        });

        if (!res.ok) {
          const text = await res.text();
          console.error("viewReminder failed:", res.status, text);
        } else {
          const data = await res.json();
          let raw: any[] = [];
          if (Array.isArray(data)) raw = data;
          else if (Array.isArray((data as any).reminders))
            raw = (data as any).reminders;

          const mapped: Reminder[] = raw
            .filter((r: any) => {
              // NEW: respect completed.isCompleted on reminders too
              const completedObj = r.completed;
              const isCompletedObj =
                completedObj && typeof completedObj === "object"
                  ? completedObj.isCompleted === true
                  : false;

              const status = (r.status || "").toLowerCase();
              const statusCompleted = ["complete", "completed", "done"].includes(
                status
              );

              // only show *active* reminders
              return !(isCompletedObj || statusCompleted);
            })
            .map((r: any, index: number) => ({
              id:
                r.reminderId ||
                r.id ||
                `${r.title ?? r.text ?? "reminder"}-${index}`,
              text: r.title || r.text || "",
            }));

          setReminders(mapped);
        }
      } catch (err) {
        console.error("Error loading reminders for Daily Summary:", err);
      }
    };

    loadData();
  }, [todayKey]);

  // toggle here is *visual only* (no backend call);
  // persistence comes from Tasks page via completeTask.
  const toggleTask = (id: string) => {
    setTasks((prev) =>
      prev.map((t) =>
        t.id === id ? { ...t, completed: !t.completed } : t
      )
    );
  };

  const tasksLoaded = tasks.length > 0;
  const eventsLoaded = events.length > 0;
  const remindersLoaded = reminders.length > 0;
  const nasaLoaded = nasaPhoto !== "";

  return (
    <PageShell title="Hello, Astronaut" subtitle={date || "Loading date..."}>
      <div className="vstack" style={{ gap: 24, paddingTop: 24 }}>
        <div className="vstack" style={{ gap: 24 }}>
          <div
            style={{
              display: "grid",
              gridTemplateColumns: isSmallScreen ? "1fr" : "repeat(3, 1fr)",
              gap: 24,
            }}
          >
            {/* Weather */}
            <GlassCard className="vstack" style={{ padding: 16 }}>
              <div className="hstack" style={{ gap: 8, alignItems: "center" }}>
                <Cloud className="w-5 h-5" style={{ color: "#93c5fd" }} />
                <strong>Today's Weather</strong>
              </div>
              <div
                className="vstack"
                style={{ alignItems: "center", gap: 8, marginTop: 12 }}
              >
                <div style={{ fontSize: 48 }}>{weather.emoji}</div>
                <div>{weather.condition || "Loading weather..."}</div>
                <div className="hstack" style={{ gap: 24 }}>
                  <div className="vstack" style={{ gap: 2 }}>
                    <div>High</div>
                    <div style={{ fontSize: 20 }}>{fmt(weather.high)}°</div>
                  </div>
                  <div className="vstack" style={{ gap: 2 }}>
                    <div>Low</div>
                    <div style={{ fontSize: 20 }}>{fmt(weather.low)}°</div>
                  </div>
                </div>
                <div
                  className="hstack"
                  style={{
                    gap: 24,
                    fontSize: 12,
                    color: "var(--muted)",
                  }}
                >
                  <div
                    className="hstack"
                    style={{ gap: 4, alignItems: "center" }}
                  >
                    <Sunrise className="w-4 h-4" />{" "}
                    <span>{fmt(weather.sunrise)}</span>
                  </div>
                  <div
                    className="hstack"
                    style={{ gap: 4, alignItems: "center" }}
                  >
                    <Sunset className="w-4 h-4" />{" "}
                    <span>{fmt(weather.sunset)}</span>
                  </div>
                </div>
              </div>
            </GlassCard>

            {/* Tasks */}
            <GlassCard className="vstack" style={{ padding: 16 }}>
              <div className="hstack" style={{ gap: 8, alignItems: "center" }}>
                <CheckCircle2
                  className="w-5 h-5"
                  style={{ color: "#86efac" }}
                />
                <strong>Today's Tasks</strong>
              </div>
              {tasksLoaded ? (
                <div className="list" style={{ marginTop: 12 }}>
                  {tasks.map((t) => (
                    <div className="list-item" key={t.id}>
                      <div className="hstack" style={{ gap: 12 }}>
                        <input
                          type="checkbox"
                          checked={!!t.completed}
                          onChange={() => toggleTask(t.id)}
                        />
                        <div className="vstack" style={{ gap: 4 }}>
                          <div
                            style={{
                              fontWeight: 600,
                              textDecoration: t.completed
                                ? "line-through"
                                : "none",
                              opacity: t.completed ? 0.5 : 1,
                            }}
                          >
                            {t.title}
                          </div>
                          <div
                            style={{
                              color: "var(--muted)",
                              opacity: t.completed ? 0.5 : 1,
                            }}
                          >
                            {t.time || "--"}
                          </div>
                        </div>
                      </div>
                      <span
                        className={
                          t.priority === "high"
                            ? "badge danger"
                            : t.priority === "medium"
                            ? "badge warn"
                            : "badge ok"
                        }
                      >
                        {t.priority || "low"}
                      </span>
                    </div>
                  ))}
                </div>
              ) : (
                <div style={{ color: "rgba(255,255,255,0.6)" }}>
                  No tasks yet.
                </div>
              )}
            </GlassCard>

            {/* Events */}
            <GlassCard className="vstack" style={{ padding: 16 }}>
              <div className="hstack" style={{ gap: 8, alignItems: "center" }}>
                <Calendar
                  className="w-5 h-5"
                  style={{ color: "#d8b4fe" }}
                />
                <strong>Today's Events</strong>
              </div>

              {eventsLoaded ? (
                <div className="vstack" style={{ gap: 12, marginTop: 12 }}>
                  {events.map((e) => (
                    <div
                      className="list-item"
                      key={e.id}
                      style={{ padding: 16 }}
                    >
                      <div className="vstack" style={{ gap: 4 }}>
                        <div
                          style={{ fontSize: 16, fontWeight: 500 }}
                        >
                          {e.title}
                        </div>
                        <div
                          style={{ fontSize: 14, color: "var(--muted)" }}
                        >
                          {e.time || "All day"}
                        </div>
                        <div
                          style={{ fontSize: 14, color: "var(--muted)" }}
                        >
                          {e.location || ""}
                        </div>
                      </div>
                    </div>
                  ))}
                </div>
              ) : (
                <div
                  style={{
                    color: "rgba(255,255,255,0.6)",
                    marginTop: 12,
                  }}
                >
                  No events today.
                </div>
              )}
            </GlassCard>
          </div>

          <div
            style={{
              display: "grid",
              gridTemplateColumns: isSmallScreen
                ? "1fr"
                : "minmax(300px, 1fr) 2fr",
              gap: 24,
            }}
          >
            {/* Reminders */}
            <GlassCard className="vstack" style={{ padding: 16 }}>
              <div className="hstack" style={{ gap: 8, alignItems: "center" }}>
                <Bell className="w-5 h-5" style={{ color: "#fde047" }} />
                <strong>Reminders</strong>
              </div>

              {remindersLoaded ? (
                <div className="list" style={{ marginTop: 12 }}>
                  {reminders.map((r) => (
                    <div className="list-item" key={r.id}>
                      <div
                        className="hstack"
                        style={{ gap: 8, alignItems: "center" }}
                      >
                        <div
                          style={{
                            width: 8,
                            height: 8,
                            borderRadius: "50%",
                            background: "#facc15",
                            flexShrink: 0,
                          }}
                        />
                        <div>{r.text}</div>
                      </div>
                    </div>
                  ))}
                </div>
              ) : (
                <div
                  style={{
                    color: "rgba(255,255,255,0.6)",
                    marginTop: 12,
                  }}
                >
                  No active reminders.
                </div>
              )}
            </GlassCard>

            {/* NASA Photo */}
            <GlassCard className="vstack" style={{ padding: 16 }}>
              <div className="hstack" style={{ gap: 8, alignItems: "center" }}>
                <Sun className="w-5 h-5" style={{ color: "#fdba74" }} />
                <strong>NASA Photo of the Day</strong>
              </div>

              {nasaLoaded ? (
                <div className="vstack" style={{ marginTop: 12 }}>
                  <div
                    style={{
                      position: "relative",
                      paddingTop: "56.25%",
                      borderRadius: 8,
                      overflow: "hidden",
                    }}
                  >
                    <img
                      src={nasaPhoto}
                      alt="NASA Photo of the Day"
                      style={{
                        position: "absolute",
                        top: 0,
                        left: 0,
                        width: "100%",
                        height: "100%",
                        objectFit: "cover",
                      }}
                    />
                  </div>
                  <p
                    style={{
                      color: "var(--muted)",
                      marginTop: 8,
                      fontSize: 14,
                    }}
                  >
                    Courtesy of NASA
                  </p>
                </div>
              ) : (
                <div
                  style={{
                    color: "rgba(255,255,255,0.6)",
                    marginTop: 12,
                  }}
                >
                  Loading NASA photo...
                </div>
              )}
            </GlassCard>
          </div>
        </div>
      </div>
    </PageShell>
  );
}
