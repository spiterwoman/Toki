import React from "react";
import PageShell from "../components/PageShell";
import GlassCard from "../components/GlassCard";
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogTrigger,
} from "../components/ui/dialog";

type Reminder = {
  id: string;      // backend _id or fallback
  title: string;
  date?: string;   // yyyy-mm-dd (not used yet)
  time?: string;
  done?: boolean;  // true if completed.isCompleted === true
};

export default function RemindersPage() {
  const [reminders, setReminders] = React.useState<Reminder[]>([]);
  const [title, setTitle] = React.useState("");
  const [open, setOpen] = React.useState(false);

  const active = reminders.filter((r) => !r.done);
  const doneCount = reminders.length - active.length;

  // ---- Load reminders from backend ----
  React.useEffect(() => {
    const loadReminders = async () => {
      try {
        const res = await fetch("/api/viewReminder", {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          credentials: "include",
          body: JSON.stringify({}), // blank body => all reminders
        });

        if (!res.ok) {
          const text = await res.text();
          console.error("viewReminder failed:", res.status, text);
          return;
        }

        const data = await res.json();
        console.log("viewReminder data:", data);

        let raw: any[] = [];
        if (Array.isArray(data)) {
          raw = data;
        } else if (Array.isArray((data as any).reminders)) {
          raw = (data as any).reminders;
        } else {
          console.warn("Unexpected viewReminder payload", data);
          return;
        }

        const mapped: Reminder[] = raw.map((r: any, index: number) => {
          const isCompleted =
            !!r.completed && r.completed.isCompleted === true;

          return {
            id: r._id || r.id || `${r.title ?? "reminder"}-${index}`,
            title: r.title ?? r.name ?? r.text ?? "",
            done: isCompleted,
          };
        });

        setReminders(mapped);
      } catch (err) {
        console.error("Failed to load reminders:", err);
      }
    };

    loadReminders();
  }, []);

  // ---- Create a new reminder ----
  const add = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!title.trim()) return;

    const trimmed = title.trim();

    const tempId =
      globalThis.crypto && "randomUUID" in globalThis.crypto
        ? (globalThis.crypto as Crypto).randomUUID()
        : Math.random().toString(36).slice(2);

    // optimistic add
    setReminders((rs) => [{ id: tempId, title: trimmed, done: false }, ...rs]);

    try {
      const res = await fetch("/api/createReminder", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        credentials: "include",
        body: JSON.stringify({ title: trimmed }),
      });

      if (!res.ok) {
        const text = await res.text();
        console.error("createReminder failed:", res.status, text);
      } else {
        const data = await res.json().catch(() => null);
        console.log("Reminder created:", data);
      }
    } catch (err) {
      console.error("Failed to create reminder:", err);
    }

    setTitle("");
    setOpen(false);
  };

  // ---- Mark reminder complete / un-complete ----
  const toggle = async (id: string) => {
    const current = reminders.find((r) => r.id === id);
    if (!current) return;

    const prevDone = current.done ?? false;
    const willBeDone = !prevDone; // toggle

    // optimistic local toggle
    setReminders((rs) =>
      rs.map((r) =>
        r.id === id ? { ...r, done: willBeDone } : r
      )
    );

    // If un-completing, we only change it locally (no API support yet)
    if (!willBeDone) {
      console.log(
        "Un-completing reminder locally only (no API support yet):",
        current.title
      );
      return;
    }

    console.log("Marking reminder complete (optimistic):", current.title);

    try {
      const res = await fetch("/api/completeReminder", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        credentials: "include",
        body: JSON.stringify({ title: current.title }),
      });

      if (!res.ok) {
        const text = await res.text();
        console.error("completeReminder failed:", res.status, text);

        // rollback on failure
        setReminders((rs) =>
          rs.map((r) =>
            r.id === id ? { ...r, done: prevDone } : r
          )
        );
      } else {
        console.log("completeReminder succeeded for:", current.title);
      }
    } catch (err) {
      console.error("Failed to complete reminder:", err);
      // rollback on error
      setReminders((rs) =>
        rs.map((r) =>
          r.id === id ? { ...r, done: prevDone } : r
        )
      );
    }
  };

  // ---- Clear all completed reminders (delete in backend) ----
  const clearCompleted = async () => {
    const completed = reminders.filter((r) => r.done);
    if (completed.length === 0) return;

    // optimistic remove
    setReminders((rs) => rs.filter((r) => !r.done));

    try {
      await Promise.all(
        completed.map((r) =>
          fetch("/api/deleteReminder", {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            credentials: "include",
            body: JSON.stringify({ title: r.title }),
          }).then(async (res) => {
            if (!res.ok) {
              const text = await res.text();
              console.error(
                "deleteReminder failed for",
                r.title,
                res.status,
                text
              );
            }
          })
        )
      );
    } catch (err) {
      console.error("Failed to delete completed reminders:", err);
    }
  };

  return (
    <PageShell title="Reminders" subtitle={`${active.length} active reminders`}>
      <div className="vstack" style={{ gap: 24 }}>
        {/* ACTIVE */}
        <GlassCard style={{ padding: 20 }}>
          <div className="hstack" style={{ gap: 8, marginBottom: 8 }}>
            <span style={{ color: "#a0e0a0" }}>🔔</span>
            <strong>Active Reminders</strong>
          </div>
          <div className="list" style={{ marginTop: 8 }}>
            {active.length === 0 && (
              <div style={{ color: "var(--muted)" }}>No active reminders.</div>
            )}
            {active.map((r) => (
              <div
                key={r.id}
                className="list-item"
                style={{ background: "rgba(255,255,255,.06)" }}
              >
                <div className="hstack" style={{ gap: 12 }}>
                  <button
                    onClick={() => toggle(r.id)}
                    aria-label="Mark complete"
                    style={{
                      width: 18,
                      height: 18,
                      borderRadius: 18,
                      border: "2px solid #facc15",
                      background: "transparent",
                      cursor: "pointer",
                    }}
                  />
                  <div style={{ fontWeight: 600 }}>{r.title}</div>
                </div>
              </div>
            ))}
          </div>
        </GlassCard>

        {/* COMPLETED */}
        <GlassCard style={{ padding: 20 }}>
          <div className="hstack" style={{ gap: 8, marginBottom: 8 }}>
            <span style={{ color: "#a0e0a0" }}>🔔</span>
            <strong>Completed</strong>
            {doneCount > 0 && (
              <button
                className="btn"
                style={{ marginLeft: "auto" }}
                onClick={clearCompleted}
              >
                Clear Completed
              </button>
            )}
          </div>
          <div className="list" style={{ marginTop: 8 }}>
            {doneCount === 0 && (
              <div style={{ color: "var(--muted)" }}>
                No completed reminders yet.
              </div>
            )}
            {reminders
              .filter((r) => r.done)
              .map((r) => (
                <div
                  key={r.id}
                  className="list-item"
                  style={{ background: "rgba(255,255,255,.04)" }}
                >
                  <div className="hstack" style={{ gap: 12 }}>
                    <button
                      onClick={() => toggle(r.id)}
                      aria-label="Mark reminder as active again"
                      style={{
                        width: 12,
                        height: 12,
                        borderRadius: 12,
                        background: "#34d399",
                        border: "none",
                        cursor: "pointer",
                      }}
                    />
                    <div
                      style={{
                        textDecoration: "line-through",
                        color: "var(--muted)",
                        fontWeight: 600,
                      }}
                    >
                      {r.title}
                    </div>
                  </div>
                </div>
              ))}
          </div>
        </GlassCard>

        {/* STATS */}
        <div
          style={{
            display: "grid",
            gridTemplateColumns: "repeat(2,1fr)",
            gap: 16,
          }}
        >
          <GlassCard
            className="vstack"
            style={{ padding: 16, textAlign: "center" }}
          >
            <div style={{ color: "var(--muted)" }}>Active</div>
            <div style={{ fontSize: 28, fontWeight: 700 }}>
              {active.length}
            </div>
          </GlassCard>
          <GlassCard
            className="vstack"
            style={{ padding: 16, textAlign: "center" }}
          >
            <div style={{ color: "var(--muted)" }}>Completed</div>
            <div
              style={{
                fontSize: 28,
                fontWeight: 700,
                color: "#34d399",
              }}
            >
              {doneCount}
            </div>
          </GlassCard>
        </div>

        {/* FAB + Dialog */}
        <Dialog open={open} onOpenChange={setOpen}>
          <DialogTrigger>
            <button
              aria-label="Add reminder"
              style={{
                position: "fixed",
                right: 26,
                bottom: 26,
                width: 60,
                height: 60,
                borderRadius: "50%",
                border: "1px solid rgba(255,255,255,.18)",
                background: "linear-gradient(135deg, #f59e0b, #f97316)",
                color: "#fff",
                fontSize: 28,
                display: "grid",
                placeItems: "center",
                boxShadow:
                  "0 10px 30px rgba(0,0,0,.35), 0 4px 10px rgba(249,115,22,.25)",
                cursor: "pointer",
                zIndex: 55,
              }}
            >
              +
            </button>
          </DialogTrigger>
          <DialogContent>
            <DialogHeader>
              <DialogTitle>Add New Reminder</DialogTitle>
              <div style={{ color: "var(--muted)" }}>
                Add a quick reminder to help you remember important things.
              </div>
            </DialogHeader>
            <form onSubmit={add} className="vstack" style={{ gap: 10 }}>
              <label className="label" htmlFor="r-title">
                Reminder
              </label>
              <input
                id="r-title"
                className="input"
                placeholder="Enter reminder text..."
                value={title}
                onChange={(e) => setTitle(e.target.value)}
              />

              <button
                className="btn"
                type="submit"
                style={{
                  background: "linear-gradient(135deg, #f59e0b, #f97316)",
                  border: "none",
                  fontWeight: 600,
                }}
              >
                Add Reminder
              </button>
            </form>
          </DialogContent>
        </Dialog>
      </div>
    </PageShell>
  );
}
