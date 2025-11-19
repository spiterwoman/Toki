import React, { useState } from "react";
import { Link, useNavigate } from "react-router-dom";
import GlassCard from "../components/GlassCard";
import PageShell from "../components/PageShell";
import { Dialog, DialogContent, DialogHeader, DialogTitle } from "../components/ui/dialog";

const storeAuth = (data: any) => {
  if (data?.token) localStorage.setItem("toki-auth-token", data.token);
  if (data?.userId) localStorage.setItem("toki-user-id", data.userId);
};

export default function SignupPage() {
  const navigate = useNavigate();
  const [name, setName] = useState("");
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [confirm, setConfirm] = useState("");
  const [status, setStatus] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [signupLoading, setSignupLoading] = useState(false);
  const [resetOpen, setResetOpen] = useState(false);
  const [resetEmail, setResetEmail] = useState("");
  const [resetStatus, setResetStatus] = useState<string | null>(null);
  const [resetLoading, setResetLoading] = useState(false);

  const onSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setStatus(null);
    setError(null);
    if (password !== confirm) {
      setError("Passwords must match.");
      return;
    }
    try {
      setSignupLoading(true);
      setStatus("Creating your account...");
      const res = await fetch("/api/addUser", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ firstName: name.trim(), email: email.trim(), password }),
      });
      if (!res.ok) {
        let message = "Signup failed. Please try again.";
        try {
          const data = await res.json();
          if (data?.message) message = data.message;
        } catch {
          // ignore parse errors
        }
        setStatus(message);
        return;
      }
      const data = await res.json();
      storeAuth(data);
      setStatus("Account created. Redirecting to login...");
      setTimeout(() => navigate("/login"), 800);
    } catch (err) {
      console.error("Signup error:", err);
      setStatus("Cannot reach server. Please try again.");
    } finally {
      setSignupLoading(false);
    }
  };

  const onResetSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    const trimmed = resetEmail.trim();
    if (!trimmed) return;
    try {
      setResetLoading(true);
      setResetStatus("Sending temporary password...");
      const res = await fetch("/api/forgotPass", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ email: trimmed }),
      });
      if (!res.ok) {
        let message = "Could not send temporary password. Please try again.";
        try {
          const data = await res.json();
          if (data?.message) message = data.message;
        } catch {
          // ignore parse errors
        }
        setResetStatus(message);
        return;
      }
      setResetStatus(`Temporary password sent to ${trimmed}. Redirecting to login...`);
      setTimeout(() => {
        setResetOpen(false);
        setResetEmail("");
        navigate("/login");
      }, 1200);
    } catch (err) {
      console.error("Forgot password error:", err);
      setResetStatus("Cannot reach server. Please try again.");
    } finally {
      setResetLoading(false);
    }
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
              disabled={signupLoading || !name.trim() || !email.trim() || !password || !confirm}
            >
              {signupLoading ? "Signing up..." : "Sign up"}
            </button>
            <button
              type="button"
              onClick={() => {
                setResetOpen(true);
                setResetStatus(null);
                setResetEmail("");
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
                setResetEmail(e.target.value);
              }}
              required
            />
            <button className="btn" type="submit" style={{ alignSelf: "flex-start" }}>
              {resetLoading ? "Sending..." : "Send temporary password"}
            </button>
          </form>
          {resetStatus && (
            <div style={{ marginTop: 12, color: "var(--muted)" }}>
              {resetStatus}
            </div>
          )}
        </DialogContent>
      </Dialog>
    </PageShell>
  );
}
