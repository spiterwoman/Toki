import type { Garage } from "../types";

// Simplified client: always fetch JSON from our API.
// In production, this is the Vercel serverless function at /api/ucf-parking.
// In local dev, Vite proxies /api/ucf-parking to the upstream JSON endpoint.

export async function fetchUcfParking(): Promise<Garage[]> {
  const apiBase = (import.meta as any).env?.VITE_API_BASE || ""; // e.g. https://toki-frontend-gamma.vercel.app
  const url = apiBase ? `${apiBase.replace(/\/$/, "")}/api/ucf-parking` : "/api/ucf-parking";
  const res = await fetch(url, {
    headers: { accept: "application/json" },
  });
  if (!res.ok) {
    throw new Error(`UCF parking fetch failed: ${res.status}`);
  }
  const data = (await res.json()) as Garage[];
  return data;
}
