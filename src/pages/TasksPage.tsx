import { useState, useEffect } from "react";
import PageShell from "../components/PageShell";
import GlassCard from "../components/GlassCard";
import type { Task } from "../types";
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogTrigger,
} from "../components/ui/dialog";

export default function TasksPage() {
  const [tasks, setTasks] = useState<Task[]>([]);
  const [title, setTitle] = useState("");
  const [time, setTime] = useState("");
  const [tag, setTag] = useState<Task["tag"]>("Work");
  const [priority, setPriority] = useState<Task["priority"]>("medium");
  const [open, setOpen] = useState(false);

  const doneCount = tasks.filter((t) => t.done).length;

  // -----------------------------------
  // Load tasks from backend on mount
  // -----------------------------------
  useEffect(() => {
    const loadTasks = async () => {
      try {
        const res = await fetch("/api/viewTask", {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          credentials: "include",
          body: JSON.stringify({}), // blank title -> return all
        });

        if (!res.ok) {
          const text = await res.text();
          console.error("viewTask failed:", res.status, text);
          return;
        }

        const data = await res.json();
        console.log("viewTask data:", data);

        let raw: any[] = [];
        if (Array.isArray(data)) raw = data;
        else if (Array.isArray((data as any).tasks)) raw = (data as any).tasks;
        else {
          console.warn("Unexpected viewTask payload", data);
          return;
        }

        const mapped: Task[] = raw.map((t: any, index: number) => ({
          id: t.taskId || t.id || t._id || `${t.title ?? "task"}-${index}`,
          title: t.title ?? t.name ?? "",
          time: t.dueDate || t.time || "",
          tag: (t.tag as Task["tag"]) || "Work",
          priority: (t.priority as Task["priority"]) || "medium",
          done:
            t.completed === true ||
            t.done === true ||
            t.status === "complete" ||
            t.status === "completed",
        }));

        setTasks(mapped);
      } catch (err) {
        console.error("Failed to load tasks:", err);
      }
    };

    loadTasks();
  }, []);

  const badgeClass = (p?: Task["priority"]) =>
    p === "high" ? "badge danger" : p === "medium" ? "badge warn" : "badge ok";

  // -----------------------------------
  // Create task
  // -----------------------------------
  const add = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!title.trim()) return;

    const trimmedTitle = title.trim();
    const id =
      globalThis.crypto && "randomUUID" in globalThis.crypto
        ? (globalThis.crypto as Crypto).randomUUID()
        : Math.random().toString(36).slice(2);

    // optimistic local add
    setTasks((ts) => [
      { id, title: trimmedTitle, time: time || undefined, tag, priority, done: false },
      ...ts,
    ]);

    try {
      const res = await fetch("/api/createTask", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        credentials: "include",
        body: JSON.stringify({
          title: trimmedTitle,
          dueDate: time || "",
          tag,
          priority,
        }),
      });

      if (!res.ok) {
        const text = await res.text();
        console.error("createTask failed:", res.status, text);
      } else {
        const data = await res.json().catch(() => null);
        console.log("Task created:", data);
      }
    } catch (err) {
      console.error("Failed to create task:", err);
    }

    setTitle("");
    setTime("");
    setOpen(false);
  };

  // -----------------------------------
  // Toggle complete
  // -----------------------------------
  const toggle = async (id: string) => {
    const existing = tasks.find((t) => t.id === id);
    if (!existing) return;

    const willBeDone = !existing.done;

    // optimistic local toggle
    setTasks((ts) =>
      ts.map((t) => (t.id === id ? { ...t, done: willBeDone } : t))
    );

    try {
      // ignore taskId for now, per backend note
      const res = await fetch("/api/editTask", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        credentials: "include",
        body: JSON.stringify({
          title: existing.title,
          description: "", // 👈 fixed: send empty string instead of existing.description
          status: willBeDone ? "complete" : "incomplete",
          priority: existing.priority ?? "medium",
          dueDate: existing.time || "",
          completed: willBeDone,
        }),
      });

      if (!res.ok) {
        const text = await res.text();
        console.error("editTask (toggle) failed:", res.status, text);
      }
    } catch (err) {
      console.error("Failed to toggle task completion:", err);
    }
  };

  // -----------------------------------
  // Delete a single task
  // -----------------------------------
  const remove = async (id: string) => {
    const target = tasks.find((t) => t.id === id);
    if (!target) return;

    // optimistic remove
    setTasks((ts) => ts.filter((t) => t.id !== id));

    try {
      const res = await fetch("/api/deleteTask", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        credentials: "include",
        body: JSON.stringify({ title: target.title }),
      });

      if (!res.ok) {
        const text = await res.text();
        console.error("deleteTask failed:", res.status, text);
      }
    } catch (err) {
      console.error("Failed to delete task:", err);
    }
  };

  // -----------------------------------
  // Clear completed (delete all done tasks)
  // -----------------------------------
  const clearCompleted = async () => {
    const completed = tasks.filter((t) => t.done);
    if (completed.length === 0) return;

    // optimistic local clear
    setTasks((ts) => ts.filter((t) => !t.done));

    try {
      await Promise.all(
        completed.map((t) =>
          fetch("/api/deleteTask", {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            credentials: "include",
            body: JSON.stringify({ title: t.title }),
          }).then(async (res) => {
            if (!res.ok) {
              const text = await res.text();
              console.error(
                "deleteTask failed for",
                t.title,
                res.status,
                text
              );
            }
          })
        )
      );
    } catch (err) {
      console.error("Failed to clear completed tasks:", err);
    }
  };

  return (
    <PageShell title="Tasks" subtitle={`${doneCount} of ${tasks.length} tasks completed`}>
      <div className="vstack" style={{ gap: 24 }}>
        <GlassCard style={{ padding: 20 }}>
          <strong>All Tasks</strong>
          <div
            className="hstack"
            style={{ justifyContent: "space-between", marginTop: 8 }}
          >
            <div style={{ color: "var(--muted)" }}>Manage your daily tasks</div>
            {doneCount > 0 && (
              <button
                type="button"
                className="btn"
                onClick={clearCompleted}
              >
                Clear Completed
              </button>
            )}
          </div>
          <div className="list" style={{ marginTop: 8 }}>
            {tasks.length === 0 && (
              <div style={{ color: "var(--muted)" }}>
                No tasks yet. Use the + button to add one.
              </div>
            )}
            {tasks.map((t) => (
              <div className="list-item" key={t.id}>
                <div className="hstack" style={{ gap: 12 }}>
                  <input
                    type="checkbox"
                    checked={!!t.done}
                    onChange={() => toggle(t.id)}
                  />
                  <div className="vstack" style={{ gap: 4 }}>
                    <div
                      style={{
                        fontWeight: 600,
                        textDecoration: t.done ? "line-through" : "none",
                        opacity: t.done ? 0.5 : 1,
                      }}
                    >
                      {t.title}
                    </div>
                    <div
                      style={{
                        color: "var(--muted)",
                        opacity: t.done ? 0.5 : 1,
                      }}
                    >
                      {[t.time, t.tag].filter(Boolean).join(" | ")}
                    </div>
                  </div>
                </div>
                <div className="hstack" style={{ gap: 8 }}>
                  <span className={badgeClass(t.priority)}>{t.priority}</span>
                  <button className="btn" onClick={() => remove(t.id)}>
                    Delete
                  </button>
                </div>
              </div>
            ))}
          </div>
        </GlassCard>

        <div
          style={{
            display: "grid",
            gridTemplateColumns: "repeat(3,1fr)",
            gap: 16,
          }}
        >
          <GlassCard
            className="vstack"
            style={{ padding: 16, textAlign: "center" }}
          >
            <div style={{ color: "var(--muted)" }}>Total Tasks</div>
            <div style={{ fontSize: 28, fontWeight: 700 }}>
              {tasks.length}
            </div>
          </GlassCard>
          <GlassCard
            className="vstack"
            style={{ padding: 16, textAlign: "center" }}
          >
            <div style={{ color: "var(--muted)" }}>Completed</div>
            <div style={{ fontSize: 28, fontWeight: 700 }}>{doneCount}</div>
          </GlassCard>
          <GlassCard
            className="vstack"
            style={{ padding: 16, textAlign: "center" }}
          >
            <div style={{ color: "var(--muted)" }}>Remaining</div>
            <div style={{ fontSize: 28, fontWeight: 700 }}>
              {tasks.length - doneCount}
            </div>
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
              <DialogTitle>Add New Task</DialogTitle>
              <div style={{ color: "var(--muted)" }}>
                Create a task with title, time, tag, and priority.
              </div>
            </DialogHeader>
            <form onSubmit={add} className="vstack" style={{ gap: 10 }}>
              <label className="label" htmlFor="t-title">
                Task Title
              </label>
              <input
                id="t-title"
                className="input"
                placeholder="Enter task title"
                value={title}
                onChange={(e) => setTitle(e.target.value)}
              />

              <label className="label" htmlFor="t-time">
                Time
              </label>
              <input
                id="t-time"
                className="input"
                placeholder="e.g., 2:30 PM"
                value={time}
                onChange={(e) => setTime(e.target.value)}
              />

              <label className="label" htmlFor="t-tag">
                Tag
              </label>
              <select
                id="t-tag"
                className="input"
                value={tag}
                onChange={(e) =>
                  setTag(e.target.value as Task["tag"])
                }
              >
                <option>Work</option>
                <option>Personal</option>
                <option>School</option>
              </select>

              <label className="label" htmlFor="t-pri">
                Priority
              </label>
              <select
                id="t-pri"
                className="input"
                value={priority}
                onChange={(e) =>
                  setPriority(e.target.value as Task["priority"])
                }
              >
                <option value="low">low</option>
                <option value="medium">medium</option>
                <option value="high">high</option>
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
                Add Task
              </button>
            </form>
          </DialogContent>
        </Dialog>
      </div>
    </PageShell>
  );
}