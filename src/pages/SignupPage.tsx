import React from "react";
import { useNavigate, Link } from "react-router-dom";
import GlassCard from "../components/GlassCard";
import PageShell from "../components/PageShell";

export default function SignupPage() {
  const nav = useNavigate();
  const onSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    // TODO: Hook up to real auth later
    nav("/tasks");
  };

  return (
    <PageShell showMenu={false}>
      <div style={{ display: "grid", placeItems: "center", height: "100vh" }}>
        <GlassCard className="vstack" style={{ width: 480, padding: 28 }}>
          <h2 style={{ textAlign: "center", margin: 0 }}>Create your account</h2>
          <div className="page-sub" style={{ textAlign: "center" }}>Join Toki to get started</div>
          <form onSubmit={onSubmit} className="vstack">
            <label className="label" htmlFor="name">Name</label>
            <input id="name" className="input" placeholder="Ada Lovelace" required />

            <label className="label" htmlFor="email" style={{ marginTop: 6 }}>Email</label>
            <input id="email" className="input" type="email" placeholder="astronaut@toki.space" required />

            <label className="label" htmlFor="pw" style={{ marginTop: 6 }}>Password</label>
            <input id="pw" className="input" type="password" placeholder="••••••••" required />

            <label className="label" htmlFor="pw2" style={{ marginTop: 6 }}>Confirm password</label>
            <input id="pw2" className="input" type="password" placeholder="••••••••" required />

            <button className="btn" type="submit" style={{ marginTop: 14, width: "100%" }}>Sign up</button>
          </form>
          <div style={{ textAlign: "center", fontSize: ".9rem", color: "var(--muted)" }}>
            Already have an account? <Link to="/login" style={{ color: "#a7c6ff" }}>Log in</Link>
          </div>
        </GlassCard>
      </div>
    </PageShell>
  );
}

