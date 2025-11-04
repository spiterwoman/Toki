import type { Garage } from "../types";

// scrapes UCF Parking availability page (via dev proxy) and extracts garage data.
// In dev, it fetches from `/proxy/ucf-parking` which the Vite proxy forwards to
// https://parking.ucf.edu/resources/garage-availability/

//
const GARAGE_IDS = ["a", "b", "c", "d", "h", "i"] as const;
type GarageId = typeof GARAGE_IDS[number];

// classifying garage status based on availability percentage
function statusFromPercent(pct: number): Garage["status"] {
  if (pct <= 0) return "Full";
  if (pct <= 15) return "Limited";
  return "Available";
}

function makeGarage(id: GarageId, name: string, available: number, capacity: number): Garage {
  const pct = Math.max(0, Math.min(100, Math.round((available / Math.max(1, capacity)) * 100)));
  return {
    id,
    name,
    available,
    capacity,
    status: statusFromPercent(pct),
  };
}

// extract garage data from the page's text using regex patterns.
function parseFromInnerText(text: string): Garage[] {
  const garages: Partial<Record<GarageId, Garage>> = {};
  const lines = text
    .split(/\r?\n/)
    .map((l) => l.trim())
    .filter(Boolean);

  const patterns: RegExp[] = [
    /Garage\s+([A-Z])\s*:?\s*(\d{1,4})\s*(?:of|\/|out of)\s*(\d{1,4})/i,
    /Garage\s+([A-Z])[^\d]*?(?:Available\s*:?\s*)?(\d{1,4})[^\d]*(?:Total|Capacity)?\s*:?\s*(\d{1,4})/i,
  ];

  for (const line of lines) {
    for (const re of patterns) {
      const m = line.match(re);
      if (m) {
        const letter = (m[1] || "").toLowerCase();
        if ((GARAGE_IDS as readonly string[]).includes(letter)) {
          const id = letter as GarageId;
          const available = parseInt(m[2], 10);
          const capacity = parseInt(m[3], 10);
          const name = `Garage ${letter.toUpperCase()}`;
          garages[id] = makeGarage(id, name, isNaN(available) ? 0 : available, isNaN(capacity) ? 0 : capacity);
        }
      }
    }
  }

  return GARAGE_IDS.map((id) =>
    garages[id] ?? makeGarage(id, `Garage ${id.toUpperCase()}`, 0, 0)
  );
}

export async function fetchUcfParking(): Promise<Garage[]> {
  // tries API endpoint first (production serverless). In dev this is proxied to HTML.
  let res: Response | null = null;
  try {
    res = await fetch("/api/ucf-parking", { headers: { accept: "application/json, text/html;q=0.8,*/*;q=0.1" } });
  } catch (e) {
  }

  if (res && res.ok) {
    const ct = res.headers.get("content-type") || "";
    if (ct.includes("application/json")) {
      const data = (await res.json()) as Garage[];
      return data;
    }
    // if HTML, fall through to HTML parsing using the received body
    const html = await res.text();
    const doc = new DOMParser().parseFromString(html, "text/html");
    const text = doc?.body?.innerText || html;
    return parseFromInnerText(text);
  }

  // fallback: use dev-only proxy path and parse HTML
  const res2 = await fetch("/proxy/ucf-parking", {
    headers: { accept: "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8" },
  });
  if (!res2.ok) throw new Error(`UCF parking fetch failed: ${res2?.status ?? "no response"}`);
  const html2 = await res2.text();
  const doc2 = new DOMParser().parseFromString(html2, "text/html");
  const text2 = doc2?.body?.innerText || html2;
  return parseFromInnerText(text2);
}
