import React, { useState } from "react";
import { Link, useNavigate } from "react-router-dom";
import GlassCard from "../components/GlassCard";
import PageShell from "../components/PageShell";
import { Dialog, DialogContent, DialogHeader, DialogTitle } from "../components/ui/dialog";

export default function LoginPage() {
  const navigate = useNavigate();
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [status, setStatus] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);
  const [resetOpen, setResetOpen] = useState(false);
  const [resetEmail, setResetEmail] = useState("");
  const [resetStatus, setResetStatus] = useState<string | null>(null);
  const [resetLoading, setResetLoading] = useState(false);

  const onSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    const trimmedEmail = email.trim();
    const trimmedPassword = password.trim();
    const tempPassword = typeof window !== "undefined" ? localStorage.getItem("toki-temp-password") : null;
    const tempEmail = typeof window !== "undefined" ? localStorage.getItem("toki-temp-email") : null;

    if (tempPassword && trimmedPassword === tempPassword && trimmedEmail === (tempEmail ?? "")) {
      sessionStorage.setItem("toki-temp-login", "1");
      setStatus("Temporary password accepted. Redirecting to Settings to change your password...");
      setTimeout(() => navigate("/settings"), 700);
      return;
    }

    //login path
    try {
      setLoading(true);
      setStatus("Signing you in...");

      console.log("something");

      const res = await fetch("/api/loginUser", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ email: trimmedEmail, password: trimmedPassword }),
        credentials: "include",
      });

      
console.log("HTTP Status:", res.status);
console.log("res.ok:", res.ok);
const text = await res.text();
console.log("Raw response body:", text);


      if (!res.ok) {
        let message = "Login failed. Please check your email or password.";
        try {
          const data = await res.json();
          if (data?.message) message = data.message;
        } catch {
          //ignore json parse errors
        }
        setStatus(message);
        return;
      }

      /*const data = await res.json();
      if (data?.token) {
        localStorage.setItem("toki-auth-token", data.token);
      }
      sessionStorage.setItem("toki-logged-in", "1");
      */
      setStatus("Login successful. Redirecting...");
      navigate("/verify");
    } catch (err) {
      console.error("Login error:", err);
      setStatus("Cannot reach server. Please try again.");
    } finally {
      setLoading(false);
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
          // ignore parse error
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
        <GlassCard className="vstack" style={{ width: 420, padding: 28 }}>
          <h2 style={{ textAlign: "center", margin: 0 }}>Toki</h2>
          <div className="page-sub" style={{ textAlign: "center" }}>Your Space Calendar Companion</div>
          <form onSubmit={onSubmit} className="vstack">
            <label className="label" htmlFor="email">Email</label>
            <input
              id="email"
              className="input"
              placeholder="you@example.com"
              type="email"
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
              placeholder="Enter your password"
              value={password}
              onChange={(e) => {
                setStatus(null);
                setPassword(e.target.value);
              }}
              required
            />

            <button
              className="btn"
              type="submit"
              style={{ marginTop: 14, width: "100%" }}
              disabled={loading || !email.trim() || !password}
            >
              {loading ? "Logging in..." : "Log In"}
            </button>
            {status && (
              <div style={{ color: "var(--muted)", marginTop: 8 }} aria-live="polite">
                {status}
              </div>
            )}
          </form>
          <div style={{ textAlign: "center", fontSize: ".9rem", color: "var(--muted)" }}>
            Don't have an account? <Link to="/signup" style={{ color: "#a7c6ff" }}>Sign up</Link>
          </div>
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
              alignSelf: "center",
            }}
          >
            Forgot password?
          </button>
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
              We'll generate a temporary password so you can sign in and update your credentials.
            </div>
          </DialogHeader>
          <form className="vstack" style={{ gap: 10 }} onSubmit={onResetSubmit}>
            <label className="label" htmlFor="reset-email">Account email</label>
            <input
              id="reset-email"
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
