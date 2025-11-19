import { useState, useEffect } from "react";
import PageShell from "../components/PageShell";
import GlassCard from "../components/GlassCard";
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogTrigger,
} from "../components/ui/dialog";

// ---- helpers ----

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
  // Monday-style grid
  start.setDate(1 - (offset === 0 ? 6 : offset - 1));
  const days: Date[] = [];
  for (let i = 0; i < 42; i++) {
    const d = new Date(start);
    d.setDate(start.getDate() + i);
    days.push(d);
  }
  return days;
}

// Normalize any backend-ish date into "yyyy-mm-dd"
function normalizeDateKey(value: any, fallback: string): string {
  if (!value) return fallback;

  if (value instanceof Date) return fmt(value);

  if (typeof value === "string") {
    const s = value.trim();

    // Already yyyy-mm-dd
    if (/^\d{4}-\d{2}-\d{2}$/.test(s)) return s;

    // ISO / other formats that Date can parse
    const parsed = new Date(s);
    if (!Number.isNaN(parsed.getTime())) return fmt(parsed);

    // Very last resort: split on non-digits
    const parts = s.split(/[^0-9]/).filter(Boolean);
    if (parts.length >= 3) {
      const [y, m, d] = parts;
      const year = Number(y);
      const month = Number(m);
      const day = Number(d);
      if (year && month && day) {
        return fmt(new Date(year, month - 1, day));
      }
    }
  }

  return fallback;
}

// Keep UIEvent shape minimal and explicit
type UIEvent = {
  id: string;
  title: string;
  date: string; // normalized "yyyy-mm-dd"
  time?: string;
  theme?: "purple" | "pink" | "blue";
  description?: string;
  location?: string;
};

export default function CalendarPage() {
  const today = new Date();
  const todayKey = fmt(
    new Date(today.getFullYear(), today.getMonth(), today.getDate())
  );

  const [year, setYear] = useState(today.getFullYear());
  const [month, setMonth] = useState(today.getMonth());
  const [selected, setSelected] = useState(todayKey);
  const [events, setEvents] = useState<UIEvent[]>([]);
  const [title, setTitle] = useState("");
  const [time, setTime] = useState("");
  const [theme, setTheme] = useState<UIEvent["theme"]>("purple");
  const [open, setOpen] = useState(false);

  const days = buildMonth(year, month);
  const monthLabel = new Date(year, month, 1).toLocaleString(undefined, {
    month: "long",
    year: "numeric",
  });

  const eventsToday = events.filter((e) => e.date === selected);
  const upcoming = [...events].sort((a, b) => a.date.localeCompare(b.date));
  const selectedLabel = parseKey(selected).toLocaleDateString(undefined, {
    weekday: "long",
    month: "long",
    day: "numeric",
  });

  // -----------------------------
  // Load events from backend
  // -----------------------------
  useEffect(() => {
    const loadEvents = async () => {
      try {
        const res = await fetch("/api/viewCalendarEvent", {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          credentials: "include",
          // per cheat sheet: blank title returns all
          body: JSON.stringify({ title: "" }),
        });

        if (!res.ok) {
          const text = await res.text();
          console.error("viewCalendarEvent failed:", res.status, text);
          return;
        }

        const data = await res.json();
        console.log("viewCalendarEvent data:", data);

        let raw: any[] = [];
        if (Array.isArray(data)) raw = data;
        else if (Array.isArray((data as any).events)) raw = (data as any).events;
        else {
          console.warn("Unexpected viewCalendarEvent payload", data);
          return;
        }

        const mapped: UIEvent[] = raw.map((ev: any, index: number) => {
          const fallbackKey = todayKey;
          const dateKey = normalizeDateKey(
            ev.date || ev.startDate || ev.endDate,
            fallbackKey
          );

          const colorRaw: string | undefined =
            ev.color || ev.theme || (ev.tag as string | undefined);
          let theme: UIEvent["theme"] = "purple";
          if (colorRaw === "pink") theme = "pink";
          else if (colorRaw === "blue") theme = "blue";
          else if (colorRaw === "purple") theme = "purple";

          return {
            id: ev.eventId || ev.id || ev._id || `${ev.title ?? "event"}-${index}`,
            title: ev.title ?? "",
            date: dateKey,
            time: ev.time || ev.startTime || "",
            theme,
            description: ev.description,
            location: ev.location,
          };
        });

        setEvents(mapped);
      } catch (err) {
        console.error("Error loading calendar events:", err);
      }
    };

    loadEvents();
  }, [todayKey]);

  const go = (delta: number) => {
    const d = new Date(year, month + delta, 1);
    setYear(d.getFullYear());
    setMonth(d.getMonth());
  };

  // -----------------------------
  // Create event
  // -----------------------------
  const add = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!title.trim()) return;

    const trimmedTitle = title.trim();
    const dateKey = normalizeDateKey(selected, todayKey);

    const id =
      globalThis.crypto && "randomUUID" in globalThis.crypto
        ? (globalThis.crypto as Crypto).randomUUID()
        : Math.random().toString(36).slice(2);

    // optimistic local add
    setEvents((evs) => [
      {
        id,
        title: trimmedTitle,
        date: dateKey,
        time: time || "",
        theme,
      },
      ...evs,
    ]);

    try {
      const res = await fetch("/api/createCalendarEvent", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        credentials: "include",
        body: JSON.stringify({
          title: trimmedTitle,
          description: "",
          startDate: dateKey,
          endDate: dateKey,
          color: theme,
        }),
      });

      if (!res.ok) {
        const text = await res.text();
        console.error("createCalendarEvent failed:", res.status, text);
      } else {
        const data = await res.json().catch(() => null);
        console.log("Calendar event created:", data);
      }
    } catch (err) {
      console.error("Failed to create calendar event:", err);
    }

    setTitle("");
    setTime("");
    setOpen(false);
  };

  // -----------------------------
  // Delete event (with Chrome alert/confirm)
  // -----------------------------
  const remove = async (id: string) => {
    const target = events.find((e) => e.id === id);
    if (!target) return;

    // Native browser confirm dialog
    const confirmed = window.confirm(
      `Delete event "${target.title}"? This cannot be undone.`
    );
    if (!confirmed) return;

    // Optimistic local delete
    setEvents((evs) => evs.filter((e) => e.id !== id));

    try {
      const res = await fetch("/api/deleteCalendarEvent", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        credentials: "include",
        body: JSON.stringify({ title: target.title }),
      });

      if (!res.ok) {
        const text = await res.text();
        console.error("deleteCalendarEvent failed:", res.status, text);
        // rollback if backend delete fails
        setEvents((evs) => [target, ...evs]);
        window.alert("Failed to delete event. Please try again.");
      } else {
        console.log("Calendar event deleted:", target.title);
        // optional success alert
        window.alert("Event deleted.");
      }
    } catch (err) {
      console.error("Failed to delete calendar event:", err);
      // rollback on error
      setEvents((evs) => [target, ...evs]);
      window.alert("Failed to delete event. Please try again.");
    }
  };

  return (
    <PageShell title="Calendar" subtitle="Plan your cosmic journey">
      <div className="vstack" style={{ gap: 24 }}>
        <div
          style={{
            display: "grid",
            gridTemplateColumns: "1.2fr 1fr",
            gap: 24,
            alignItems: "start",
          }}
        >
          <GlassCard style={{ padding: 20 }}>
            <div
              className="hstack"
              style={{ justifyContent: "space-between", marginBottom: 10 }}
            >
              <div className="hstack" style={{ gap: 10 }}>
                <span style={{ color: "#ff89d7" }}>📅</span>
                <strong>Select Date</strong>
              </div>
              <div className="hstack">
                <button className="btn" onClick={() => go(-1)}>
                  {"<"}
                </button>
                <button className="btn" onClick={() => go(+1)}>
                  {">"}
                </button>
              </div>
            </div>
            <div
              style={{
                textAlign: "center",
                color: "var(--muted)",
                marginBottom: 6,
              }}
            >
              {monthLabel}
            </div>
            <div
              style={{
                display: "grid",
                gridTemplateColumns: "repeat(7,1fr)",
                gap: 8,
              }}
            >
              {["Su", "Mo", "Tu", "We", "Th", "Fr", "Sa"].map((d) => (
                <div
                  key={d}
                  style={{ textAlign: "center", color: "var(--muted)" }}
                >
                  {d}
                </div>
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
                      outline: isSelected
                        ? "2px solid rgba(174,70,255,.45)"
                        : "none",
                      position: "relative",
                    }}
                  >
                    <span
                      style={{
                        fontWeight: 700,
                        display: "inline-grid",
                        placeItems: "center",
                        width: 28,
                        height: 28,
                        borderRadius: 8,
                        color: "#fff",
                        background: isSelected
                          ? "linear-gradient(135deg, #a855f7, #ec4899)"
                          : "transparent",
                      }}
                    >
                      {d.getDate()}
                    </span>
                    {hasEvent && (
                      <span
                        style={{
                          position: "absolute",
                          left: 8,
                          bottom: 8,
                          width: 8,
                          height: 8,
                          borderRadius: "50%",
                          background: "var(--accent)",
                        }}
                      />
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
              {eventsToday.length === 0 && (
                <div style={{ color: "var(--muted)" }}>No events today.</div>
              )}
              {eventsToday.map((ev) => (
                <div className="list-item" key={ev.id}>
                  <div className="vstack">
                    <div style={{ fontWeight: 600 }}>{ev.title}</div>
                    <div style={{ color: "var(--muted)" }}>
                      {ev.time ?? "All day"}
                    </div>
                  </div>
                  <button className="btn" onClick={() => remove(ev.id)}>
                    Delete
                  </button>
                </div>
              ))}
            </div>
          </GlassCard>
        </div>

        <GlassCard style={{ padding: 20 }}>
          <strong>Upcoming Events</strong>
          <div className="list" style={{ marginTop: 12 }}>
            {upcoming.length === 0 && (
              <div style={{ color: "var(--muted)" }}>
                Add anticipated events to see them on your calendar.
              </div>
            )}
            {upcoming.map((ev) => {
              const bg =
                ev.theme === "purple"
                  ? "linear-gradient(135deg, rgba(168,85,247,.18), rgba(236,72,153,.12))"
                  : ev.theme === "pink"
                  ? "linear-gradient(135deg, rgba(244,114,182,.18), rgba(251,113,133,.12))"
                  : ev.theme === "blue"
                  ? "linear-gradient(135deg, rgba(59,130,246,.18), rgba(99,102,241,.12))"
                  : undefined;
              return (
                <div
                  key={ev.id}
                  className="list-item"
                  style={{ background: bg }}
                >
                  <div className="vstack">
                    <div style={{ fontWeight: 600 }}>{ev.title}</div>
                    <div style={{ color: "var(--muted)" }}>
                      {parseKey(ev.date).toLocaleDateString(undefined, {
                        month: "short",
                        day: "numeric",
                      })}{" "}
                      {ev.time ? `at ${ev.time}` : ""}
                    </div>
                  </div>
                  <button className="btn" onClick={() => remove(ev.id)}>
                    Delete
                  </button>
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
                boxShadow:
                  "0 10px 30px rgba(0,0,0,.35), 0 4px 10px rgba(236,72,153,.25)",
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
              <div style={{ color: "var(--muted)" }}>
                Schedule a new event with a title, date, time, and color
                theme.
              </div>
            </DialogHeader>
            <form onSubmit={add} className="vstack" style={{ gap: 10 }}>
              <label className="label" htmlFor="title">
                Event Title
              </label>
              <input
                id="title"
                className="input"
                placeholder="Enter event title"
                value={title}
                onChange={(e) => setTitle(e.target.value)}
              />

              <label className="label" htmlFor="date">
                Date
              </label>
              <input
                id="date"
                className="input"
                type="date"
                value={selected}
                onChange={(e) => setSelected(e.target.value)}
              />

              <label className="label" htmlFor="time">
                Time
              </label>
              <input
                id="time"
                className="input"
                placeholder="e.g., 9:00 AM"
                value={time}
                onChange={(e) => setTime(e.target.value)}
              />

              <label className="label" htmlFor="theme">
                Color Theme
              </label>
              <select
                id="theme"
                className="input"
                value={theme}
                onChange={(e) =>
                  setTheme(e.target.value as UIEvent["theme"])
                }
              >
                <option value="purple">Purple</option>
                <option value="pink">Pink</option>
                <option value="blue">Blue</option>
              </select>

              <button
                className="btn"
                type="submit"
                style={{
                  background: "linear-gradient(135deg, #8b5cf6, #ec4899)",
                  border: "none",
                  fontWeight: 600,
                }}
              >
                Add Event
              </button>
            </form>
          </DialogContent>
        </Dialog>
      </div>
    </PageShell>
  );
}
