// src/pages/UCFParkingPage.tsx
import { useEffect, useMemo, useState } from "react";
import PageShell from "../components/PageShell";
import GlassCard from "../components/GlassCard";
import type { Garage } from "../types";

function percentFull(g: Garage) {
  if (!g.capacity || g.capacity <= 0) return 0;
  const full = g.capacity - Math.max(0, g.available);
  return Math.max(0, Math.min(100, Math.round((full / g.capacity) * 100)));
}

function statusColor(s: Garage["status"]) {
  return s === "Available" ? "ok" : s === "Limited" ? "warn" : "danger";
}

export default function UCFParkingPage() {
  const [garages, setGarages] = useState<Garage[] | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState<boolean>(true);

  const refreshedAt = useMemo(() => new Date(), [garages]);

  useEffect(() => {
    let alive = true;

    async function load() {
      setLoading(true);
      setError(null);
      try {
        const res = await fetch("/api/viewGarages", {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          credentials: "include",
          body: JSON.stringify({}),
        });

        if (!res.ok) {
          const text = await res.text();
          console.error("viewGarages failed:", res.status, text);
          throw new Error(text || `viewGarages failed with ${res.status}`);
        }

        const data = await res.json();
        const raw: any[] = Array.isArray(data?.garages) ? data.garages : [];

        let mapped: Garage[] = raw.map((g: any, index: number) => {
          const capacity =
            typeof g.totalSpots === "number" ? g.totalSpots : 0;
          const available =
            typeof g.availableSpots === "number" ? g.availableSpots : 0;

          let percent: number;
          if (typeof g.percentFull === "number") {
            percent = g.percentFull;
          } else if (capacity) {
            percent = Math.round(
              ((capacity - available) / capacity) * 100
            );
          } else {
            percent = 0;
          }

          let status: Garage["status"];
          if (!capacity) status = "Available";
          else if (percent < 70) status = "Available";
          else if (percent < 90) status = "Limited";
          else status = "Full";

          return {
            id: g._id ?? g.id ?? `garage-${index}`,
            name: g.garageName ?? `Garage ${index + 1}`,
            available,
            capacity,
            status,
          } as Garage;
        });

        // ---- custom sort: main-campus garages first, downtown at bottom ----
        mapped = mapped.sort((a, b) => {
          const aName = a.name.toLowerCase();
          const bName = b.name.toLowerCase();

          const aIsDowntown = aName.startsWith("downtown campus");
          const bIsDowntown = bName.startsWith("downtown campus");

          // push downtown entries to the bottom
          if (aIsDowntown && !bIsDowntown) return 1;
          if (!aIsDowntown && bIsDowntown) return -1;

          // within each group, sort alphabetically (so Garage A, B, C…)
          return a.name.localeCompare(b.name);
        });

        if (alive) setGarages(mapped);
      } catch (e: any) {
        console.error("Failed to load UCF parking:", e);
        if (alive) setError(e?.message || "Failed to load parking data.");
      } finally {
        if (alive) setLoading(false);
      }
    }

    load();
    const t = setInterval(load, 60_000);
    return () => {
      alive = false;
      clearInterval(t);
    };
  }, []);

  const list = garages ?? [];

  return (
    <PageShell
      title="UCF Parking Tracker"
      subtitle="Real-time parking availability"
    >
      {loading && !list.length && (
        <div style={{ color: "var(--muted)", marginBottom: 12 }}>
          Loading latest availability…
        </div>
      )}
      {error && (
        <div style={{ color: "var(--danger)", marginBottom: 12 }}>
          {error} — showing any available data.
        </div>
      )}

      <div style={{ display: "grid", gap: 16 }}>
        {list.map((g) => {
          const p = percentFull(g);
          const note =
            g.capacity > 0
              ? `${p}% full of ${g.capacity} spots`
              : "Capacity data not available";

          return (
            <GlassCard key={g.id} style={{ padding: 16 }}>
              <div
                style={{
                  display: "flex",
                  justifyContent: "space-between",
                  alignItems: "center",
                }}
              >
                <div style={{ display: "flex", gap: 12, alignItems: "center" }}>
                  <strong>{g.name}</strong>
                  <span className={`badge ${statusColor(g.status)}`}>
                    {g.status}
                  </span>
                </div>
                <strong>{g.available}</strong>
              </div>
              <div className="progress" style={{ marginTop: 10 }}>
                <span style={{ width: `${p}%` }} />
              </div>
              <div style={{ color: "var(--muted)", marginTop: 8 }}>{note}</div>
            </GlassCard>
          );
        })}
      </div>

      {list.length > 0 && (
        <div style={{ color: "var(--muted)", marginTop: 12 }}>
          Last updated: {refreshedAt.toLocaleTimeString()}
        </div>
      )}
    </PageShell>
  );
}
