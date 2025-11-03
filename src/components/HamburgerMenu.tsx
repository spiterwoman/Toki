import { Link, useLocation, useNavigate } from "react-router-dom";
import GlassCard from "./GlassCard";

type Props = { open: boolean; onClose: () => void };

const items = [
  { label: "Daily Summary", to: "/daily-summary" },
  { label: "Calendar", to: "/calendar" },
  { label: "Tasks", to: "/tasks" },
  { label: "Reminders", to: "/reminders" },
  { label: "Weather", to: "/weather" },
  { label: "NASA Photo", to: "/nasa-photo" },
  { label: "UCF Parking", to: "/parking" },
];


export default function HamburgerMenu({ open, onClose }: Props) {
  const { pathname } = useLocation();
  const nav = useNavigate();

  return (
    <>
      <div className={`scrim ${open ? "show" : ""}`} onClick={onClose} />
      <aside className={`sidebar glass ${open ? "open" : ""}`} style={{ padding: 16 }}>
        <div style={{ marginTop: 24 }}>
          <GlassCard className="vstack" style={{ padding: 16 }}>
            <h2 style={{ margin: 0 }}>Toki</h2>
            <div className="vstack" style={{ marginTop: 12 }}>
              {items.map((it) => (
                <Link
                  key={it.to}
                  to={it.to}
                  onClick={onClose}
                  className="hstack"
                  style={{
                    padding: "12px 14px",
                    borderRadius: 16,
                    background: pathname === it.to ? "rgba(255,255,255,.08)" : "transparent",
                    border: "1px solid var(--card-border)",
                    textDecoration: "none",
                    color: "inherit",
                  }}
                >
                  <span>{it.label}</span>
                </Link>
              ))}
            </div>
          </GlassCard>
        </div>

        <div style={{ position: "absolute", left: 20, right: 20, bottom: 20 }}>
          <div style={{ height: 1, background: "var(--card-border)", opacity: 0.6, marginBottom: 12 }} />
          <button
            onClick={() => nav("/login")}
            style={{
              width: "100%",
              padding: 12,
              borderRadius: 14,
              background: "rgba(255,0,0,.06)",
              border: "1px solid rgba(255,99,99,.35)",
              color: "#ff7b7b",
              fontWeight: 600,
              cursor: "pointer",
            }}
          >
            Logout
          </button>
        </div>
      </aside>
    </>
  );
}

