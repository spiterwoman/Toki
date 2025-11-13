import React, { useState } from "react";
import { Link } from "react-router-dom";
import GlassCard from "../components/GlassCard";
import PageShell from "../components/PageShell";
import { Dialog, DialogContent, DialogHeader, DialogTitle } from "../components/ui/dialog";

function generateTempPassword() {
  return `TMP-${Math.random().toString(36).slice(-6).toUpperCase()}`;
}

export default function SignupPage() {
  const [name, setName] = useState("");
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [confirm, setConfirm] = useState("");
  const [status, setStatus] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [resetOpen, setResetOpen] = useState(false);
  const [resetEmail, setResetEmail] = useState("");
  const [resetStatus, setResetStatus] = useState<string | null>(null);
  const [tempPreview, setTempPreview] = useState<string | null>(null);

  const onSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    setStatus(null);
    setError(null);
    if (password !== confirm) {
      setError("Passwords must match.");
      return;
    }
    setStatus("Account details ready to sent to backend. (Not implemented)");
    console.log("Signup payload", { name: name.trim(), email: email.trim(), password });
  };

  const onResetSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    const trimmed = resetEmail.trim();
    if (!trimmed) return;
    const temp = generateTempPassword();
    localStorage.setItem("toki-temp-password", temp);
    localStorage.setItem("toki-temp-email", trimmed);
    setResetStatus(`Temporary password sent to ${trimmed}.`);
    setTempPreview(temp);
  };

  return (
    <PageShell showMenu={false}>
      <div style={{ display: "grid", placeItems: "center", height: "100vh" }}>
        <GlassCard className="vstack" style={{ width: 480, padding: 28 }}>
          <h2 style={{ textAlign: "center", margin: 0 }}>Create your account</h2>
          <div className="page-sub" style={{ textAlign: "center" }}>Join Toki to get started</div>
          <form onSubmit={onSubmit} className="vstack">
            <label className="label" htmlFor="name">Name</label>
            <input
              id="name"
              className="input"
              placeholder="Enter your name"
              value={name}
              onChange={(e) => {
                setStatus(null);
                setName(e.target.value);
              }}
              required
            />

            <label className="label" htmlFor="email" style={{ marginTop: 6 }}>Email</label>
            <input
              id="email"
              className="input"
              type="email"
              placeholder="you@example.com"
              value={email}
              onChange={(e) => {
                setStatus(null);
                setEmail(e.target.value);
              }}
              required
            />

            <label className="label" htmlFor="pw" style={{ marginTop: 6 }}>Password</label>
            <input
              id="pw"
              className="input"
              type="password"
              placeholder="Enter a secure password"
              value={password}
              onChange={(e) => {
                setStatus(null);
                setPassword(e.target.value);
              }}
              required
            />

            <label className="label" htmlFor="pw2" style={{ marginTop: 6 }}>Confirm password</label>
            <input
              id="pw2"
              className="input"
              type="password"
              placeholder="Re-enter your password"
              value={confirm}
              onChange={(e) => {
                setStatus(null);
                setConfirm(e.target.value);
              }}
              required
            />

            <button
              className="btn"
              type="submit"
              style={{ marginTop: 14, width: "100%" }}
              disabled={!name.trim() || !email.trim() || !password || !confirm}
            >
              Sign up
            </button>
            <button
              type="button"
              onClick={() => {
                setResetOpen(true);
                setResetStatus(null);
                setTempPreview(null);
              }}
              style={{
                marginTop: 8,
                background: "none",
                border: "none",
                color: "#a7c6ff",
                textDecoration: "underline",
                cursor: "pointer",
                alignSelf: "flex-start",
              }}
            >
              Forgot password?
            </button>
            {error && (
              <div style={{ color: "#f87171", marginTop: 8 }} role="alert">
                {error}
              </div>
            )}
            {status && (
              <div style={{ color: "var(--muted)", marginTop: 4 }} aria-live="polite">
                {status}
              </div>
            )}
          </form>
          <div style={{ textAlign: "center", fontSize: ".9rem", color: "var(--muted)" }}>
            Already have an account? <Link to="/login" style={{ color: "#a7c6ff" }}>Log in</Link>
          </div>
        </GlassCard>
      </div>

      <Dialog
        open={resetOpen}
        onOpenChange={(open) => {
          setResetOpen(open);
          if (!open) {
            setResetEmail("");
            setResetStatus(null);
            setTempPreview(null);
          }
        }}
      >
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Reset password</DialogTitle>
            <div style={{ color: "var(--muted)" }}>
              We'll email you a temporary password so you can log in and update your credentials.
            </div>
          </DialogHeader>
          <form className="vstack" style={{ gap: 10 }} onSubmit={onResetSubmit}>
            <label className="label" htmlFor="signup-reset-email">Account email</label>
            <input
              id="signup-reset-email"
              className="input"
              type="email"
              placeholder="you@example.com"
              value={resetEmail}
              onChange={(e) => {
                setResetStatus(null);
                setTempPreview(null);
                setResetEmail(e.target.value);
              }}
              required
            />
            <button className="btn" type="submit" style={{ alignSelf: "flex-start" }}>
              Send temporary password
            </button>
          </form>
          {resetStatus && (
            <div style={{ marginTop: 12, color: "var(--muted)" }}>
              {resetStatus} (Front-end demo shown below.)
              {tempPreview && (
                <div
                  style={{
                    marginTop: 6,
                    fontFamily: "monospace",
                    background: "rgba(255,255,255,.06)",
                    padding: 8,
                    borderRadius: 8,
                  }}
                >
                  Demo password: {tempPreview}
                </div>
              )}
            </div>
          )}
        </DialogContent>
      </Dialog>
    </PageShell>
  );
}
