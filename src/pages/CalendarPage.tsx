import { useState } from "react";
import PageShell from "../components/PageShell";
import GlassCard from "../components/GlassCard";
import type { CalendarEvent } from "../types";
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogTrigger } from "../components/ui/dialog";

const getAuth = () => ({
  userId: localStorage.getItem("toki-user-id") || sessionStorage.getItem("toki-user-id") || "",
  accessToken: localStorage.getItem("toki-auth-token") || sessionStorage.getItem("toki-auth-token") || "",
});

function fmt(d: Date) {
  const year = d.getFullYear();
  const month = `${d.getMonth() + 1}`.padStart(2, "0");
  const day = `${d.getDate()}`.padStart(2, "0");
  return `${year}-${month}-${day}`;
}

function parseKey(key: string) {
  const [y, m, d] = key.split("-").map((part) => Number.parseInt(part, 10));
  return new Date(y || 1970, (m || 1) - 1, d || 1);
}

function buildMonth(year: number, month: number) {
  const first = new Date(year, month, 1);
  const start = new Date(first);
  const offset = first.getDay();
  start.setDate(1 - (offset === 0 ? 6 : offset - 1));
  const days: Date[] = [];
  for (let i = 0; i < 42; i++) { const d = new Date(start); d.setDate(start.getDate() + i); days.push(d); }
  return days;
}

type UIEvent = CalendarEvent & { theme?: "purple" | "pink" | "blue" };

export default function CalendarPage() {
  const today = new Date();
  const todayKey = fmt(new Date(today.getFullYear(), today.getMonth(), today.getDate()));
  const [year, setYear] = useState(today.getFullYear());
  const [month, setMonth] = useState(today.getMonth());
  const [selected, setSelected] = useState(todayKey);
  const [events, setEvents] = useState<UIEvent[]>([]);
  const [title, setTitle] = useState("");
  const [time, setTime] = useState("");
  const [theme, setTheme] = useState<UIEvent["theme"]>("purple");
  const [open, setOpen] = useState(false);

  const days = buildMonth(year, month);
  const monthLabel = new Date(year, month, 1).toLocaleString(undefined, { month: "long", year: "numeric" });

  const eventsToday = events.filter((e) => e.date === selected);
  const upcoming = [...events].sort((a, b) => a.date.localeCompare(b.date));
  const selectedLabel = parseKey(selected).toLocaleDateString(undefined, { weekday: "long", month: "long", day: "numeric" });

  const go = (delta: number) => {
    const d = new Date(year, month + delta, 1);
    setYear(d.getFullYear()); setMonth(d.getMonth());
  };

  const add = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!title.trim()) return;
    const id = (globalThis.crypto && "randomUUID" in globalThis.crypto)
      ? (globalThis.crypto as Crypto).randomUUID()
      : Math.random().toString(36).slice(2);
    setEvents((evs) => [{ id, title: title.trim(), date: selected, time: time || undefined, theme }, ...evs]);
    try {
      const { userId, accessToken } = getAuth();
      if (!userId || !accessToken) {
        console.warn("Missing auth; skipping createCalendarEvent");
      } else {
        const res = await fetch("/api/createCalendarEvent", {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({
            userId,
            accessToken,
            title: title.trim(),
            description: "",
            startDate: selected,
            endDate: selected,
          }),
        });
        if (!res.ok) {
          const text = await res.text();
          console.error("createCalendarEvent failed:", res.status, text);
        }
      }
    } catch (err) {
      console.error("Failed to create calendar event:", err);
    }
    setTitle(""); setTime(""); setOpen(false);
  };
  const remove = (id: string) => setEvents((evs) => evs.filter((e) => e.id !== id));

  return (
    <PageShell title="Calendar" subtitle="Plan your cosmic journey">
      <div className="vstack" style={{ gap: 24 }}>
        <div style={{ display: "grid", gridTemplateColumns: "1.2fr 1fr", gap: 24, alignItems: "start" }}>
          <GlassCard style={{ padding: 20 }}>
            <div className="hstack" style={{ justifyContent: "space-between", marginBottom: 10 }}>
              <div className="hstack" style={{ gap: 10 }}>
                <span style={{ color: "#ff89d7" }}>📅</span>
                <strong>Select Date</strong>
              </div>
              <div className="hstack">
                <button className="btn" onClick={() => go(-1)}>{"<"}</button>
                <button className="btn" onClick={() => go(+1)}>{">"}</button>
              </div>
            </div>
            <div style={{ textAlign: "center", color: "var(--muted)", marginBottom: 6 }}>{monthLabel}</div>
            <div style={{ display: "grid", gridTemplateColumns: "repeat(7,1fr)", gap: 8 }}>
              {["Su","Mo","Tu","We","Th","Fr","Sa"].map((d) => (
                <div key={d} style={{ textAlign: "center", color: "var(--muted)" }}>{d}</div>
              ))}
              {days.map((d, i) => {
                const dKey = fmt(d);
                const inMonth = d.getMonth() === month;
                const isSelected = dKey === selected;
                const hasEvent = events.some((e) => e.date === dKey);
                return (
                  <button
                    key={i}
                    onClick={() => setSelected(dKey)}
                    className="glass"
                    style={{
                      height: 60,
                      borderRadius: 12,
                      padding: 8,
                      textAlign: "right",
                      cursor: "pointer",
                      opacity: inMonth ? 1 : 0.4,
                      outline: isSelected ? "2px solid rgba(174,70,255,.45)" : "none",
                      position: "relative",
                    }}
                  >
                    <span style={{
                      fontWeight: 700,
                      display: "inline-grid",
                      placeItems: "center",
                      width: 28,
                      height: 28,
                      borderRadius: 8,
                      color: "#fff",
                      background: isSelected ? "linear-gradient(135deg, #a855f7, #ec4899)" : "transparent",
                    }}>{d.getDate()}</span>
                    {hasEvent && (
                      <span style={{ position: "absolute", left: 8, bottom: 8, width: 8, height: 8, borderRadius: "50%", background: "var(--accent)" }} />
                    )}
                  </button>
                );
              })}
            </div>
          </GlassCard>

          <GlassCard style={{ padding: 20 }}>
            <div className="hstack" style={{ marginBottom: 10 }}>
              <span style={{ color: "#ff89d7" }}>📅</span>
              <strong>{selectedLabel}</strong>
            </div>
            <div className="list">
              {eventsToday.length === 0 && <div style={{ color: "var(--muted)" }}>No events today.</div>}
              {eventsToday.map((ev) => (
                <div className="list-item" key={ev.id}>
                  <div className="vstack">
                    <div style={{ fontWeight: 600 }}>{ev.title}</div>
                    <div style={{ color: "var(--muted)" }}>{ev.time ?? "All day"}</div>
                  </div>
                  <button className="btn" onClick={() => remove(ev.id)}>Delete</button>
                </div>
              ))}
            </div>
          </GlassCard>
        </div>

          <GlassCard style={{ padding: 20 }}>
            <strong>Upcoming Events</strong>
            <div className="list" style={{ marginTop: 12 }}>
            {upcoming.length === 0 && (
              <div style={{ color: "var(--muted)" }}>Add anticipated events to see them on your calendar.</div>
            )}
            {upcoming.map((ev) => {
              const bg = ev.theme === "purple"
                ? "linear-gradient(135deg, rgba(168,85,247,.18), rgba(236,72,153,.12))"
                : ev.theme === "pink"
                ? "linear-gradient(135deg, rgba(244,114,182,.18), rgba(251,113,133,.12))"
                : ev.theme === "blue"
                ? "linear-gradient(135deg, rgba(59,130,246,.18), rgba(99,102,241,.12))"
                : undefined;
              return (
                <div key={ev.id} className="list-item" style={{ background: bg }}>
                  <div className="vstack">
                    <div style={{ fontWeight: 600 }}>{ev.title}</div>
                    <div style={{ color: "var(--muted)" }}>
                      {parseKey(ev.date).toLocaleDateString(undefined, { month: "short", day: "numeric" })} {ev.time ? `at ${ev.time}` : ""}
                    </div>
                  </div>
                  <button className="btn" onClick={() => remove(ev.id)}>Delete</button>
                </div>
              );
            })}
          </div>
        </GlassCard>

        {/* floating action button + dialog */}
        <Dialog open={open} onOpenChange={setOpen}>
          <DialogTrigger>
            <button
              aria-label="Add event"
              style={{
                position: "fixed",
                right: 26,
                bottom: 26,
                width: 60,
                height: 60,
                borderRadius: "50%",
                border: "1px solid rgba(255,255,255,.18)",
                background: "linear-gradient(135deg, #8b5cf6, #ec4899)",
                color: "#fff",
                fontSize: 28,
                display: "grid",
                placeItems: "center",
                boxShadow: "0 10px 30px rgba(0,0,0,.35), 0 4px 10px rgba(236,72,153,.25)",
                cursor: "pointer",
                zIndex: 55,
              }}
            >
              +
            </button>
          </DialogTrigger>
          <DialogContent>
            <DialogHeader>
              <DialogTitle>Add New Event</DialogTitle>
              <div style={{ color: "var(--muted)" }}>Schedule a new event with a title, date, time, and color theme.</div>
            </DialogHeader>
            <form onSubmit={add} className="vstack" style={{ gap: 10 }}>
              <label className="label" htmlFor="title">Event Title</label>
              <input id="title" className="input" placeholder="Enter event title" value={title} onChange={(e) => setTitle(e.target.value)} />

              <label className="label" htmlFor="date">Date</label>
              <input id="date" className="input" type="date" value={selected} onChange={(e) => setSelected(e.target.value)} />

              <label className="label" htmlFor="time">Time</label>
              <input id="time" className="input" placeholder="e.g., 9:00 AM" value={time} onChange={(e) => setTime(e.target.value)} />

              <label className="label" htmlFor="theme">Color Theme</label>
              <select id="theme" className="input" value={theme} onChange={(e) => setTheme(e.target.value as UIEvent["theme"]) }>
                <option value="purple">Purple</option>
                <option value="pink">Pink</option>
                <option value="blue">Blue</option>
              </select>

              <button className="btn" type="submit" style={{
                background: "linear-gradient(135deg, #8b5cf6, #ec4899)",
                border: "none",
                fontWeight: 600,
              }}>Add Event</button>
            </form>
          </DialogContent>
        </Dialog>
      </div>
    </PageShell>
  );
}
