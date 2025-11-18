import React from "react";
import PageShell from "../components/PageShell";
import GlassCard from "../components/GlassCard";
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogTrigger } from "../components/ui/dialog";

type Reminder = {
  id: string;
  title: string;
  date?: string; // yyyy-mm-dd
  time?: string;
  done?: boolean;
};

export default function RemindersPage() {
  const [reminders, setReminders] = React.useState<Reminder[]>([]);
  const [title, setTitle] = React.useState("");
  const [open, setOpen] = React.useState(false);

  const active = reminders.filter((r) => !r.done);
  const doneCount = reminders.length - active.length;

  const add = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!title.trim()) return;
    const id = (globalThis.crypto && "randomUUID" in globalThis.crypto)
      ? (globalThis.crypto as Crypto).randomUUID()
      : Math.random().toString(36).slice(2);
    setReminders((rs) => [{ id, title: title.trim(), done: false }, ...rs]);
    try {
      const userId = localStorage.getItem("toki-user-id") || "";
      const accessToken = localStorage.getItem("toki-auth-token") || "";
      await fetch("/api/createReminder", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          userId,
          accessToken,
          title: title.trim(),
        }),
      });
    } catch (err) {
      console.error("Failed to create reminder:", err);
    }
    setTitle("");
    setOpen(false);
  };
  const toggle = (id: string) => setReminders((rs) => rs.map((r) => (r.id === id ? { ...r, done: !r.done } : r)));
  const clearCompleted = () => setReminders((rs) => rs.filter((r) => !r.done));

  return (
    <PageShell title="Reminders" subtitle={`${active.length} active reminders`}>
      <div className="vstack" style={{ gap: 24 }}>
        <GlassCard style={{ padding: 20 }}>
          <div className="hstack" style={{ gap: 8, marginBottom: 8 }}>
            <span style={{ color: "#a0e0a0" }}>🔔</span>
            <strong>Active Reminders</strong>
          </div>
          <div className="list" style={{ marginTop: 8 }}>
            {active.length === 0 && <div style={{ color: "var(--muted)" }}>No active reminders.</div>}
            {active.map((r) => (
              <div key={r.id} className="list-item" style={{ background: "rgba(255,255,255,.06)" }}>
                <div className="hstack" style={{ gap: 12 }}>
                  <button onClick={() => toggle(r.id)} aria-label="Mark complete" style={{
                    width: 18, height: 18, borderRadius: 18, border: "2px solid #facc15", background: "transparent"
                  }} />
                  <div style={{ fontWeight: 600 }}>{r.title}</div>
                </div>
              </div>
            ))}
          </div>
        </GlassCard>

        <GlassCard style={{ padding: 20 }}>
          <div className="hstack" style={{ gap: 8, marginBottom: 8 }}>
            <span style={{ color: "#a0e0a0" }}>🔔</span>
            <strong>Completed</strong>
            {doneCount > 0 && <button className="btn" style={{ marginLeft: "auto" }} onClick={clearCompleted}>Clear Completed</button>}
          </div>
          <div className="list" style={{ marginTop: 8 }}>
            {doneCount === 0 && <div style={{ color: "var(--muted)" }}>No completed reminders yet.</div>}
            {reminders.filter((r) => r.done).map((r) => (
              <div key={r.id} className="list-item" style={{ background: "rgba(255,255,255,.04)" }}>
                <div className="hstack" style={{ gap: 12 }}>
                  <span style={{ width: 12, height: 12, borderRadius: 12, background: "#34d399" }} />
                  <div style={{ textDecoration: "line-through", color: "var(--muted)", fontWeight: 600 }}>{r.title}</div>
                </div>
              </div>
            ))}
          </div>
        </GlassCard>

        <div style={{ display: "grid", gridTemplateColumns: "repeat(2,1fr)", gap: 16 }}>
          <GlassCard className="vstack" style={{ padding: 16, textAlign: "center" }}>
            <div style={{ color: "var(--muted)" }}>Active</div>
            <div style={{ fontSize: 28, fontWeight: 700 }}>{active.length}</div>
          </GlassCard>
          <GlassCard className="vstack" style={{ padding: 16, textAlign: "center" }}>
            <div style={{ color: "var(--muted)" }}>Completed</div>
            <div style={{ fontSize: 28, fontWeight: 700, color: "#34d399" }}>{doneCount}</div>
          </GlassCard>
        </div>

        {/* Floating Action Button + Dialog */}
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
                boxShadow: "0 10px 30px rgba(0,0,0,.35), 0 4px 10px rgba(249,115,22,.25)",
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
              <div style={{ color: "var(--muted)" }}>Add a quick reminder to help you remember important things.</div>
            </DialogHeader>
            <form onSubmit={add} className="vstack" style={{ gap: 10 }}>
              <label className="label" htmlFor="r-title">Reminder</label>
              <input id="r-title" className="input" placeholder="Enter reminder text..." value={title} onChange={(e) => setTitle(e.target.value)} />

              <button className="btn" type="submit" style={{
                background: "linear-gradient(135deg, #f59e0b, #f97316)",
                border: "none",
                fontWeight: 600,
              }}>Add Reminder</button>
            </form>
          </DialogContent>
        </Dialog>
      </div>
    </PageShell>
  );
}

