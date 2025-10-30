import type { Garage } from "../types";

// Simplified client: always fetch JSON from our API.
// In production, this is the Vercel serverless function at /api/ucf-parking.
// In local dev, Vite proxies /api/ucf-parking to the upstream JSON endpoint.

export async function fetchUcfParking(): Promise<Garage[]> {
  const res = await fetch("/api/ucf-parking", {
    headers: { accept: "application/json" },
  });
  if (!res.ok) {
    throw new Error(`UCF parking fetch failed: ${res.status}`);
  }
  const data = (await res.json()) as Garage[];
  return data;
}
