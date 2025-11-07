import { useEffect, useMemo, useState } from "react";
import PageShell from "../components/PageShell";
import GlassCard from "../components/GlassCard";
import type { Garage } from "../types";
import { fetchUcfParking } from "../services/ucfParking";

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
        const data = await fetchUcfParking();
        if (alive) setGarages(data);
      } catch (e: any) {
        console.error("Failed to load UCF parking:", e);
        if (alive) setError(e?.message || "Failed to load parking data.");
      } finally {
        if (alive) setLoading(false);
      }
    }

    load();
    const t = setInterval(load, 60_000); // refresh every 60s
    return () => {
      alive = false;
      clearInterval(t);
    };
  }, []);

  return (
    <PageShell title="UCF Parking Tracker" subtitle="Real-time parking availability">
      {loading && !garages && (
        <div style={{ color: "var(--muted)", marginBottom: 12 }}>Loading latest availability…</div>
      )}
      {error && (
        <div style={{ color: "var(--danger)", marginBottom: 12 }}>
          {error} — showing any available data.
        </div>
      )}

      <div style={{ display: "grid", gap: 16 }}>
        {(garages ?? []).map((g) => {
          const p = percentFull(g);
          const note = g.capacity > 0 ? `${p}% full of ${g.capacity}` : "";
          return (
            <GlassCard key={g.id} style={{ padding: 16 }}>
              <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center" }}>
                <div style={{ display: "flex", gap: 12, alignItems: "center" }}>
                  <strong>{g.name}</strong>
                  <span className={`badge ${statusColor(g.status)}`}>{g.status}</span>
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

      {garages && (
        <div style={{ color: "var(--muted)", marginTop: 12 }}>
          Last updated: {refreshedAt.toLocaleTimeString()}
        </div>
      )}
    </PageShell>
  );
}
