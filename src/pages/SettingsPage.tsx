import { useEffect, useState } from "react";
import GlassCard from "../components/GlassCard";
import PageShell from "../components/PageShell";

const defaultPrefs = {
  emailReports: false,
  pushReminders: false,
};

export default function SettingsPage() {
  const [prefs, setPrefs] = useState(() => ({ ...defaultPrefs }));
  const [timezone, setTimezone] = useState("");
  const [name, setName] = useState("");
  const [status, setStatus] = useState<string | null>(null);
  const [currentPassword, setCurrentPassword] = useState("");
  const [newPassword, setNewPassword] = useState("");
  const [confirmPassword, setConfirmPassword] = useState("");
  const [passwordStatus, setPasswordStatus] = useState<string | null>(null);
  const [requirePasswordChange, setRequirePasswordChange] = useState(false);

  useEffect(() => {
    if (typeof window !== "undefined" && sessionStorage.getItem("toki-temp-login") === "1") {
      setRequirePasswordChange(true);
    }
  }, []);

  const toggle = (key: keyof typeof prefs) => {
    setStatus(null);
    setPrefs((prev) => ({ ...prev, [key]: !prev[key] }));
  };

  const saveProfile = (e: React.FormEvent) => {
    e.preventDefault();
    setStatus("Profile ready to sync with backend. (not implemented)");
    console.log("Settings payload", { name, timezone, prefs });
  };

  const savePassword = (e: React.FormEvent) => {
    e.preventDefault();
    setPasswordStatus(null);
    if (!newPassword || newPassword !== confirmPassword) {
      setPasswordStatus("New passwords must match.");
      return;
    }
    setPasswordStatus("Password change request ready for backend. (Not implemented)");
    console.log("Change password payload", { currentPassword, newPassword });
    setCurrentPassword("");
    setNewPassword("");
    setConfirmPassword("");
    sessionStorage.removeItem("toki-temp-login");
    setRequirePasswordChange(false);
  };

  return (
    <PageShell title="Settings" subtitle="Personalize your Toki experience">
      <div className="vstack" style={{ gap: 20 }}>
        <GlassCard style={{ padding: 20 }}>
          <strong>Profile</strong>
          <div style={{ color: "var(--muted)", marginBottom: 16 }}>Update how others see your account.</div>
          <form className="vstack" style={{ gap: 12 }} onSubmit={saveProfile}>
            <label className="label" htmlFor="profile-name">Display name</label>
            <input
              id="profile-name"
              className="input"
              value={name}
              onChange={(e) => {
                setStatus(null);
                setName(e.target.value);
              }}
              placeholder="Enter your name"
            />

            <label className="label" htmlFor="timezone">Timezone</label>
            <select
              id="timezone"
              className="input"
              value={timezone}
              onChange={(e) => {
                setStatus(null);
                setTimezone(e.target.value);
              }}
            >
              <option value="" disabled>Select timezone</option>
              <option value="America/New_York">Eastern (EST)</option>
              <option value="America/Chicago">Central (CST)</option>
              <option value="America/Denver">Mountain (MST)</option>
              <option value="America/Los_Angeles">Pacific (PST)</option>
            </select>

            <button className="btn" type="submit" style={{ alignSelf: "flex-start" }} disabled={!name.trim() || !timezone}>
              Save Profile
            </button>
            {status && (
              <div style={{ color: "var(--muted)" }} aria-live="polite">
                {status}
              </div>
            )}
          </form>
        </GlassCard>

        <GlassCard style={{ padding: 20 }}>
          <strong>Security</strong>
          <div style={{ color: "var(--muted)", marginBottom: 12 }}>
            Use a temporary password to get in, then set a permanent one here.
          </div>
          {requirePasswordChange && (
            <div style={{ marginBottom: 12, padding: 12, borderRadius: 12, background: "rgba(255,255,255,.05)", color: "#fcd34d" }}>
              You signed in with a temporary password. Update it below before continuing.
            </div>
          )}
          <form className="vstack" style={{ gap: 12 }} onSubmit={savePassword}>
            <label className="label" htmlFor="current-password">Temporary / current password</label>
            <input
              id="current-password"
              className="input"
              type="password"
              placeholder="Enter the temporary password from your email"
              value={currentPassword}
              onChange={(e) => {
                setPasswordStatus(null);
                setCurrentPassword(e.target.value);
              }}
              required
            />

            <label className="label" htmlFor="new-password">New password</label>
            <input
              id="new-password"
              className="input"
              type="password"
              placeholder="Create a new password"
              value={newPassword}
              onChange={(e) => {
                setPasswordStatus(null);
                setNewPassword(e.target.value);
              }}
              required
            />

            <label className="label" htmlFor="confirm-password">Confirm password</label>
            <input
              id="confirm-password"
              className="input"
              type="password"
              placeholder="Re-enter the new password"
              value={confirmPassword}
              onChange={(e) => {
                setPasswordStatus(null);
                setConfirmPassword(e.target.value);
              }}
              required
            />

            <button
              className="btn"
              type="submit"
              style={{ alignSelf: "flex-start" }}
              disabled={!currentPassword || !newPassword || !confirmPassword}
            >
              Change password
            </button>
            {passwordStatus && (
              <div style={{ color: "var(--muted)" }} aria-live="polite">
                {passwordStatus}
              </div>
            )}
          </form>
        </GlassCard>

        <GlassCard style={{ padding: 20 }}>
          <strong>Notifications</strong>
          <div style={{ color: "var(--muted)", marginBottom: 12 }}>
            Decide when Toki should nudge you about important activity.
          </div>
          <div className="vstack" style={{ gap: 12 }}>
            {[
              ["emailReports", "Daily email reports"],
              ["pushReminders", "Push reminders for tasks"],
            ].map(([key, label]) => (
              <label
                key={key}
                className="hstack"
                style={{
                  justifyContent: "space-between",
                  padding: "10px 0",
                  borderBottom: "1px solid rgba(255,255,255,.08)",
                }}
              >
                <span>{label}</span>
                <input type="checkbox" checked={prefs[key as keyof typeof prefs]} onChange={() => toggle(key as keyof typeof prefs)} />
              </label>
            ))}
          </div>
        </GlassCard>
      </div>
    </PageShell>
  );
}
