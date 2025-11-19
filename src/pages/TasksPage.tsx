import { useState } from "react";
import PageShell from "../components/PageShell";
import GlassCard from "../components/GlassCard";
import type { Task } from "../types";
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogTrigger } from "../components/ui/dialog";

const getAuth = () => {
  const userId = localStorage.getItem("toki-user-id") || sessionStorage.getItem("toki-user-id") || "";
  const accessToken = localStorage.getItem("toki-auth-token") || sessionStorage.getItem("toki-auth-token") || "";
  return { userId, accessToken };
};

export default function TasksPage() {
  const [tasks, setTasks] = useState<Task[]>([]);
  const [title, setTitle] = useState("");
  const [time, setTime] = useState("");
  const [tag, setTag] = useState<Task["tag"]>("Work");
  const [priority, setPriority] = useState<Task["priority"]>("medium");
  const [open, setOpen] = useState(false);

  const doneCount = tasks.filter((t) => t.done).length;

  const toggle = (id: string) => setTasks((ts) => ts.map((t) => (t.id === id ? { ...t, done: !t.done } : t)));
  const remove = (id: string) => setTasks((ts) => ts.filter((t) => t.id !== id));
  const clearCompleted = () => setTasks((ts) => ts.filter((t) => !t.done));
  const add = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!title.trim()) return;
    const id = (globalThis.crypto && "randomUUID" in globalThis.crypto)
      ? (globalThis.crypto as Crypto).randomUUID()
      : Math.random().toString(36).slice(2);
    setTasks((ts) => [{ id, title: title.trim(), time: time || undefined, tag, priority, done: false }, ...ts]);
    try {
      const { userId, accessToken } = getAuth();
      console.log("createTask auth", { userId, accessToken });
      if (!userId || !accessToken) {
        console.warn("Missing auth; skipping createTask");
      } else {
        const res = await fetch("/api/createTask", {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({
            userId,
            accessToken,
            title: title.trim(),
            dueDate: time || "",
            tag,
            priority,
          }),
        });
        if (!res.ok) {
          const text = await res.text();
          console.error("createTask failed:", res.status, text);
        }
      }
    } catch (err) {
      console.error("Failed to create task:", err);
    }
    setTitle(""); setTime(""); setOpen(false);
  };

  const badgeClass = (p?: Task["priority"]) => (p === "high" ? "badge danger" : p === "medium" ? "badge warn" : "badge ok");

  return (
    <PageShell title="Tasks" subtitle={`${doneCount} of ${tasks.length} tasks completed`}>
      <div className="vstack" style={{ gap: 24 }}>
        <GlassCard style={{ padding: 20 }}>
          <strong>All Tasks</strong>
          <div className="hstack" style={{ justifyContent: "space-between", marginTop: 8 }}>
            <div style={{ color: "var(--muted)" }}>Manage your daily tasks</div>
            {doneCount > 0 && (
              <button type="button" className="btn" onClick={clearCompleted}>Clear Completed</button>
            )}
          </div>
          <div className="list" style={{ marginTop: 8 }}>
            {tasks.length === 0 && <div style={{ color: "var(--muted)" }}>No tasks yet. Use the + button to add one.</div>}
            {tasks.map((t) => (
              <div className="list-item" key={t.id}>
                <div className="hstack" style={{ gap: 12 }}>
                  <input type="checkbox" checked={!!t.done} onChange={() => toggle(t.id)} />
                  <div className="vstack" style={{ gap: 4 }}>
                    <div style={{ fontWeight: 600, textDecoration: t.done ? "line-through" : "none" }}>{t.title}</div>
                    <div style={{ color: "var(--muted)" }}>{[t.time, t.tag].filter(Boolean).join(" | ")}</div>
                  </div>
                </div>
                <div className="hstack" style={{ gap: 8 }}>
                  <span className={badgeClass(t.priority)}>{t.priority}</span>
                  <button className="btn" onClick={() => remove(t.id)}>Delete</button>
                </div>
              </div>
            ))}
          </div>
        </GlassCard>

        <div style={{ display: "grid", gridTemplateColumns: "repeat(3,1fr)", gap: 16 }}>
          <GlassCard className="vstack" style={{ padding: 16, textAlign: "center" }}>
            <div style={{ color: "var(--muted)" }}>Total Tasks</div>
            <div style={{ fontSize: 28, fontWeight: 700 }}>{tasks.length}</div>
          </GlassCard>
          <GlassCard className="vstack" style={{ padding: 16, textAlign: "center" }}>
            <div style={{ color: "var(--muted)" }}>Completed</div>
            <div style={{ fontSize: 28, fontWeight: 700 }}>{doneCount}</div>
          </GlassCard>
          <GlassCard className="vstack" style={{ padding: 16, textAlign: "center" }}>
            <div style={{ color: "var(--muted)" }}>Remaining</div>
            <div style={{ fontSize: 28, fontWeight: 700 }}>{tasks.length - doneCount}</div>
          </GlassCard>
        </div>

        {/* Floating Action Button + Dialog for Tasks */}
        <Dialog open={open} onOpenChange={setOpen}>
          <DialogTrigger>
            <button
              aria-label="Add task"
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
              <DialogTitle>Add New Task</DialogTitle>
              <div style={{ color: "var(--muted)" }}>Create a task with title, time, tag, and priority.</div>
            </DialogHeader>
            <form onSubmit={add} className="vstack" style={{ gap: 10 }}>
              <label className="label" htmlFor="t-title">Task Title</label>
              <input id="t-title" className="input" placeholder="Enter task title" value={title} onChange={(e) => setTitle(e.target.value)} />

              <label className="label" htmlFor="t-time">Time</label>
              <input id="t-time" className="input" placeholder="e.g., 2:30 PM" value={time} onChange={(e) => setTime(e.target.value)} />

              <label className="label" htmlFor="t-tag">Tag</label>
              <select id="t-tag" className="input" value={tag} onChange={(e) => setTag(e.target.value as Task["tag"]) }>
                <option>Work</option>
                <option>Personal</option>
                <option>School</option>
              </select>

              <label className="label" htmlFor="t-pri">Priority</label>
              <select id="t-pri" className="input" value={priority} onChange={(e) => setPriority(e.target.value as Task["priority"]) }>
                <option value="low">low</option>
                <option value="medium">medium</option>
                <option value="high">high</option>
              </select>

              <button className="btn" type="submit" style={{
                background: "linear-gradient(135deg, #8b5cf6, #ec4899)",
                border: "none",
                fontWeight: 600,
              }}>Add Task</button>
            </form>
          </DialogContent>
        </Dialog>
      </div>
    </PageShell>
  );
}

