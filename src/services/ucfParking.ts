import type { Garage } from "../types";

// Simplified client: always fetch JSON from our API.
// In production, this is the Vercel serverless function at /api/ucf-parking.
// In local dev, Vite proxies /api/ucf-parking to the upstream JSON endpoint.

export async function fetchUcfParking(): Promise<Garage[]> {
  const env = (import.meta as any).env as { VITE_API_BASE?: string; PROD?: boolean };
  // Fallback: if no env is provided in a production build, default to the Vercel API base
  const apiBase = (env?.VITE_API_BASE && String(env.VITE_API_BASE))
    || (env?.PROD ? "https://toki-frontend-gamma.vercel.app" : "");
  const url = apiBase ? `${apiBase.replace(/\/$/, "")}/api/ucf-parking` : "/api/ucf-parking";
  const res = await fetch(url, {
    headers: { accept: "application/json" },
  });
  if (!res.ok) {
    throw new Error(`UCF parking fetch failed: ${res.status}`);
  }
  const raw = await res.json();

  // Normalize shape: accept either our API's Garage[] or the upstream UCF raw array
  // Example raw item: { location: { name: 'Garage A', counts: { available, total, occupied } } }
  const normalize = (input: any): Garage[] => {
    if (Array.isArray(input) && input.length && input[0] && input[0].location) {
      const out: Garage[] = [];
      for (const item of input) {
        const loc = item.location || {};
        const counts = loc.counts || {};
        const name: string = (loc.name || counts.location_name || "").toString();
        const match = name.match(/Garage\s+([A-Z])\b/i);
        if (!match) continue;
        const id = match[1].toLowerCase();
        const available = Number(counts.available ?? Math.max(0, (counts.total ?? 0) - (counts.occupied ?? 0)) ?? 0);
        const capacity = Number(counts.total ?? 0);
        const pct = capacity > 0 ? Math.round(((capacity - available) / capacity) * 100) : 0; // percent full
        const status: Garage["status"] = available <= 0 ? "Full" : pct <= 15 ? "Limited" : "Available";
        out.push({ id, name, available, capacity, status });
      }
      return out;
    }
    return input as Garage[];
  };

  return normalize(raw);
}
