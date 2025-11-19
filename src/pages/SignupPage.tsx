import React, { useState } from "react";
import { Link, useNavigate } from "react-router-dom";
import GlassCard from "../components/GlassCard";
import PageShell from "../components/PageShell";

export default function SignupPage() {
  const navigate = useNavigate();

  const [name, setName] = useState("");
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [confirm, setConfirm] = useState("");
  const [status, setStatus] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);

  const onSubmit = async (e: React.FormEvent) => {
    e.preventDefault();

    const trimmedName = name.trim();
    const trimmedEmail = email.trim();
    const trimmedPassword = password.trim();
    const trimmedConfirm = confirm.trim();

    if (!trimmedName || !trimmedEmail || !trimmedPassword) {
      setStatus("Please fill in all fields.");
      return;
    }

    if (trimmedPassword !== trimmedConfirm) {
      setStatus("Passwords do not match.");
      return;
    }

    try {
      setLoading(true);
      setStatus("Creating your account...");

      const res = await fetch("/api/addUser", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        credentials: "include",
        body: JSON.stringify({
          name: trimmedName,
          email: trimmedEmail,
          password: trimmedPassword,
        }),
      });

      if (!res.ok) {
        let message = "Sign up failed. Please try again.";
        try {
          const data = await res.json();
          if (data?.message) message = data.message;
        } catch {
        }
        setStatus(message);
        return;
      }

      setStatus("Account created! Redirecting you to log in...");
      setTimeout(() => {
        navigate("/login");
      }, 800);
    } catch (err) {
      console.error("Signup error:", err);
      setStatus("Cannot reach server. Please try again.");
    } finally {
      setLoading(false);
    }
  };

  const buttonDisabled =
    loading ||
    !name.trim() ||
    !email.trim() ||
    !password ||
    !confirm ||
    password !== confirm;

  return (
    <PageShell showMenu={false}>
      <div style={{ display: "grid", placeItems: "center", height: "100vh" }}>
        <GlassCard className="vstack" style={{ width: 420, padding: 28 }}>
          <h2 style={{ textAlign: "center", margin: 0 }}>Create your account</h2>
          <div className="page-sub" style={{ textAlign: "center" }}>
            Join Toki to get started
          </div>

          <form onSubmit={onSubmit} className="vstack">
            <label className="label" htmlFor="name">
              Name
            </label>
            <input
              id="name"
              className="input"
              placeholder="Your name"
              value={name}
              onChange={(e) => {
                setStatus(null);
                setName(e.target.value);
              }}
              required
            />

            <label className="label" htmlFor="email" style={{ marginTop: 6 }}>
              Email
            </label>
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

            <label className="label" htmlFor="pw" style={{ marginTop: 6 }}>
              Password
            </label>
            <input
              id="pw"
              className="input"
              type="password"
              placeholder="Enter a password"
              value={password}
              onChange={(e) => {
                setStatus(null);
                setPassword(e.target.value);
              }}
              required
            />

            <label className="label" htmlFor="pw2" style={{ marginTop: 6 }}>
              Confirm password
            </label>
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

            {password && confirm && password !== confirm && (
              <div
                style={{
                  color: "var(--danger)",
                  fontSize: 13,
                  marginTop: 4,
                }}
              >
                Passwords do not match.
              </div>
            )}

            <button
              className="btn"
              type="submit"
              style={{ marginTop: 14, width: "100%" }}
              disabled={buttonDisabled}
            >
              {loading ? "Signing up..." : "Sign up"}
            </button>

            {status && (
              <div
                style={{ color: "var(--muted)", marginTop: 8 }}
                aria-live="polite"
              >
                {status}
              </div>
            )}
          </form>

          <div
            style={{
              textAlign: "center",
              fontSize: ".9rem",
              color: "var(--muted)",
              marginTop: 12,
            }}
          >
            Already have an account?{" "}
            <Link to="/login" style={{ color: "#a7c6ff" }}>
              Log in
            </Link>
          </div>
        </GlassCard>
      </div>
    </PageShell>
  );
}
