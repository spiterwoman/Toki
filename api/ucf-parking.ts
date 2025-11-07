// Vercel serverless function for production use.
// Deploying to a live domain? Place this file at `api/ucf-parking.ts` (Vercel convention)
// and deploy via Vercel. The frontend calls `/api/ucf-parking`.
//
// Low-traffic friendly: includes a simple in-memory 60s cache.

type Garage = {
  id: string;
  name: string;
  available: number;
  capacity: number;
  status: "Available" | "Limited" | "Full";
};

const GARAGE_IDS = ["a", "b", "c", "d", "h", "i"] as const;
type GarageId = typeof GARAGE_IDS[number];

function statusFromPercent(pct: number): Garage["status"] {
  if (pct <= 0) return "Full";
  if (pct <= 15) return "Limited";
  return "Available";
}

function makeGarage(id: GarageId, name: string, available: number, capacity: number): Garage {
  const pct = Math.max(0, Math.min(100, Math.round((available / Math.max(1, capacity)) * 100)));
  return { id, name, available, capacity, status: statusFromPercent(pct) };
}

function parseFromText(text: string): Garage[] {
  const out: Partial<Record<GarageId, Garage>> = {};
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
          out[id] = makeGarage(id, name, isNaN(available) ? 0 : available, isNaN(capacity) ? 0 : capacity);
        }
      }
    }
  }

  return GARAGE_IDS.map((id) => out[id] ?? makeGarage(id, `Garage ${id.toUpperCase()}`, 0, 0));
}

const UCF_URL = "https://parking.ucf.edu/resources/garage-availability/";
const JSON_CANDIDATES: string[] = [
  // Verified from user DevTools capture
  "https://secure.parking.ucf.edu/GarageCounter/GetOccupancy",
  // Reasonable alternates seen on similar stacks
  "https://parking.ucf.edu/GarageCounter/GetOccupancy",
  "https://secure.parking.ucf.edu/GarageCount/GetOccupancy",
  "https://parking.ucf.edu/GarageCount/GetOccupancy",
  "https://secure.parking.ucf.edu/GarageCount/GetGarageCounts",
  "https://parking.ucf.edu/GarageCount/GetGarageCounts",
];

function tryGet<T>(obj: any, keys: string[]): T | undefined {
  for (const k of keys) {
    if (obj && typeof obj === "object" && k in obj) return obj[k] as T;
  }
  return undefined;
}

function parseFromJson(json: any): Garage[] | null {
  // Heuristic parser for several possible JSON shapes
  const result: Partial<Record<GarageId, Garage>> = {};

  const set = (id: GarageId, available: number | undefined, capacity: number | undefined) => {
    if (typeof available !== "number") return;
    const cap = typeof capacity === "number" ? capacity : 0;
    result[id] = makeGarage(id, `Garage ${id.toUpperCase()}` as string, available, cap);
  };

  if (Array.isArray(json)) {
    for (const item of json) {
      // Direct flat shape
      let name: string | undefined = tryGet(item, ["name", "Name", "garage", "Garage", "lot", "Lot"]);
      let available: number | undefined =
        tryGet(item, ["available", "Available", "free", "Free", "spacesAvailable", "SpacesAvailable"]) ??
        (() => {
          const occ = tryGet<number>(item, ["occupied", "Occupancy", "occupiedSpaces", "Occupied"]);
          const cap = tryGet<number>(item, ["capacity", "Capacity", "total", "Total", "spacesTotal", "SpacesTotal"]);
          if (typeof occ === "number" && typeof cap === "number") return Math.max(0, cap - occ);
          return undefined;
        })();
      let capacity: number | undefined = tryGet(item, ["capacity", "Capacity", "total", "Total", "spacesTotal", "SpacesTotal"]);

      // UCF GetOccupancy nested shape: { location: { name, counts: { available, total, occupied } } }
      if (!name && item && typeof item === "object" && "location" in item) {
        const loc = (item as any).location;
        if (loc && typeof loc === "object") {
          name = tryGet(loc, ["name", "Name"]) ?? tryGet(loc.counts, ["location_name"]);
          const counts = tryGet<any>(loc, ["counts"]) || {};
          // Prefer 'available' directly; fallback to total - occupied
          available = tryGet<number>(counts, ["available"]) ?? (() => {
            const occ = tryGet<number>(counts, ["occupied"]);
            const cap = tryGet<number>(counts, ["total"]);
            if (typeof occ === "number" && typeof cap === "number") return Math.max(0, cap - occ);
            return undefined;
          })();
          capacity = tryGet<number>(counts, ["total"]) ?? capacity;
        }
      }

      const idGuess = (name || "").match(/Garage\s+([A-Z])\b/i)?.[1]?.toLowerCase() || (name || "").match(/\b([A-Z])\b/)?.[1]?.toLowerCase();
      const id = (GARAGE_IDS as readonly string[]).includes(idGuess || "") ? (idGuess as GarageId) : undefined;
      if (id) set(id, available, capacity);
    }
  } else if (json && typeof json === "object") {
    // Object keyed by garage identifier, e.g., { A: { Available: 123, Capacity: 1200 }, ... }
    for (const key of Object.keys(json)) {
      const letter = key.toLowerCase().replace(/[^a-z]/g, "");
      if ((GARAGE_IDS as readonly string[]).includes(letter)) {
        const id = letter as GarageId;
        const val = json[key];
        if (val && typeof val === "object") {
          const available: number | undefined =
            tryGet(val, ["available", "Available", "free", "Free"]) ??
            (() => {
              const occ = tryGet<number>(val, ["occupied", "Occupancy"]);
              const cap = tryGet<number>(val, ["capacity", "Capacity", "total", "Total"]);
              if (typeof occ === "number" && typeof cap === "number") return Math.max(0, cap - occ);
              return undefined;
            })();
          const capacity: number | undefined = tryGet(val, ["capacity", "Capacity", "total", "Total"]);
          set(id, available, capacity);
        } else if (typeof val === "number") {
          set(id, val, undefined);
        }
      }
    }
  }

  const garages = GARAGE_IDS.map((id) => result[id] ?? makeGarage(id, `Garage ${id.toUpperCase()}`, 0, 0));
  const anyData = garages.some((g) => g.available > 0 || g.capacity > 0);
  return anyData ? garages : null;
}

async function tryFetchJson(): Promise<{ data: any; url: string } | null> {
  for (const u of JSON_CANDIDATES) {
    try {
      const r = await fetch(u, {
        headers: {
          accept: "application/json, text/javascript, */*; q=0.01",
          // Some IIS backends vary on Origin/Referer; set them to the site that calls it
          Origin: "https://parking.ucf.edu",
          Referer: "https://parking.ucf.edu/",
          "User-Agent": "Mozilla/5.0 (compatible; ClassProjectBot/1.0; +https://example.edu)",
        },
      });
      if (!r.ok) continue;
      const ct = r.headers.get("content-type") || "";
      if (ct.includes("application/json") || ct.includes("text/json") || ct.includes("application/javascript")) {
        const data = await r.json();
        return { data, url: u };
      }
      // Some endpoints may return JSON with text/plain
      const text = await r.text();
      try {
        const data = JSON.parse(text);
        return { data, url: u };
      } catch {}
    } catch {}
  }
  return null;
}

let cache: { data: Garage[]; ts: number } | null = null;
const TTL_MS = 60_000; // 60s cache

export const config = { runtime: "edge" };

const CORS_HEADERS: Record<string, string> = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "GET, OPTIONS",
  "Access-Control-Allow-Headers": "Content-Type, Authorization",
  "Access-Control-Max-Age": "600",
  Vary: "Origin",
};

export default async function handler(req: Request): Promise<Response> {
  const url = new URL(req.url);
  if (url.pathname !== "/api/ucf-parking") {
    return new Response("Not found", { status: 404, headers: CORS_HEADERS });
  }

  if (req.method === "OPTIONS") {
    return new Response(null, { status: 204, headers: CORS_HEADERS });
  }

  const now = Date.now();
  if (cache && now - cache.ts < TTL_MS) {
    return new Response(JSON.stringify(cache.data), {
      status: 200,
      headers: { ...CORS_HEADERS, "content-type": "application/json; charset=utf-8", "cache-control": "s-maxage=30, max-age=0" },
    });
  }

  // Try JSON endpoints first if available
  const jsonHit = await tryFetchJson();
  if (jsonHit) {
    const parsed = parseFromJson(jsonHit.data);
    if (parsed) {
      cache = { data: parsed, ts: now };
      const debug = (url.searchParams.get("debug") || "").toLowerCase();
      if (debug === "json") {
        return new Response(JSON.stringify({ source: jsonHit.url, raw: jsonHit.data }, null, 2), {
          status: 200,
          headers: { ...CORS_HEADERS, "content-type": "application/json; charset=utf-8" },
        });
      }
      return new Response(JSON.stringify(parsed), {
        status: 200,
        headers: { ...CORS_HEADERS, "content-type": "application/json; charset=utf-8", "cache-control": "s-maxage=30, max-age=0" },
      });
    }
  }

  const upstream = await fetch(UCF_URL, {
    headers: {
      "user-agent": "Mozilla/5.0 (compatible; ClassProjectBot/1.0; +https://example.edu)",
      accept: "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
    },
    redirect: "follow",
  });
  if (!upstream.ok) {
    return new Response(JSON.stringify({ error: `Upstream error: ${upstream.status}` }), {
      status: 502,
      headers: { ...CORS_HEADERS, "content-type": "application/json; charset=utf-8" },
    });
  }

  const html = await upstream.text();
  // Extract text content for regex-friendly parsing
  const text = html
    .replace(/<script[\s\S]*?<\/script>/g, " ")
    .replace(/<style[\s\S]*?<\/style>/g, " ")
    .replace(/<[^>]+>/g, " ")
    .replace(/\s+/g, " ")
    .trim();

  // Debug modes to help inspect upstream content in production
  const debug = (url.searchParams.get("debug") || "").toLowerCase();
  if (debug === "raw") {
    return new Response(html, { status: 200, headers: { ...CORS_HEADERS, "content-type": "text/html; charset=utf-8" } });
  }
  if (debug === "text") {
    return new Response(text, { status: 200, headers: { ...CORS_HEADERS, "content-type": "text/plain; charset=utf-8" } });
  }

  const data = parseFromText(text);
  cache = { data, ts: now };

  return new Response(JSON.stringify(data), {
    status: 200,
    headers: { ...CORS_HEADERS, "content-type": "application/json; charset=utf-8", "cache-control": "s-maxage=30, max-age=0" },
  });
}
