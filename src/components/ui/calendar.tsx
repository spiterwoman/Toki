import React from "react";

export function Calendar({
  selected,
  onSelect,
  className = "",
}: {
  selected?: Date;
  onSelect: (d: Date | undefined) => void;
  className?: string;
}) {
  const [cursor, setCursor] = React.useState<Date>(selected ?? new Date());
  const year = cursor.getFullYear();
  const month = cursor.getMonth();

  const start = new Date(year, month, 1);
  const startDay = (start.getDay() + 6) % 7; // Monday-like offset
  const days: Date[] = [];
  for (let i = 0; i < 42; i++) {
    const d = new Date(year, month, 1 - startDay + i);
    days.push(d);
  }
  const monthLabel = start.toLocaleString(undefined, { month: "long", year: "numeric" });

  return (
    <div className={className}>
      <div className="hstack" style={{ justifyContent: "space-between", marginBottom: 8 }}>
        <button className="btn" onClick={() => setCursor(new Date(year, month - 1, 1))}>←</button>
        <strong>{monthLabel}</strong>
        <button className="btn" onClick={() => setCursor(new Date(year, month + 1, 1))}>→</button>
      </div>
      <div style={{ display: "grid", gridTemplateColumns: "repeat(7,1fr)", gap: 6 }}>
        {["Mo","Tu","We","Th","Fr","Sa","Su"].map((d) => (
          <div key={d} style={{ textAlign: "center", color: "var(--muted)" }}>{d}</div>
        ))}
        {days.map((d, i) => {
          const inMonth = d.getMonth() === month;
          const sel = selected && d.toDateString() === selected.toDateString();
          return (
            <button key={i} onClick={() => onSelect(d)}
              className="glass"
              style={{
                height: 44, borderRadius: 10, padding: 6, textAlign: "right",
                opacity: inMonth ? 1 : 0.35,
                outline: sel ? "2px solid rgba(110,168,255,.4)" : "none",
                cursor: "pointer"
              }}>
              <span style={{ fontWeight: 600 }}>{d.getDate()}</span>
            </button>
          );
        })}
      </div>
    </div>
  );
}
