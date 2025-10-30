import React from "react";
import { useNavigate, Link } from "react-router-dom";
import GlassCard from "../components/GlassCard";
import PageShell from "../components/PageShell";

export default function LoginPage(){
  const nav = useNavigate();
  const onSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    nav("/tasks");
  };

  return (
    <PageShell showMenu={false}>
      <div style={{ display:"grid", placeItems:"center", height:"100vh" }}>
        <GlassCard className="vstack" style={{ width: 420, padding: 28 }}>
          <h2 style={{ textAlign:"center", margin: 0 }}>Toki</h2>
          <div className="page-sub" style={{ textAlign:"center" }}>Your Space Calendar Companion</div>
          <form onSubmit={onSubmit} className="vstack">
            <label className="label" htmlFor="email">Email</label>
            <input id="email" className="input" placeholder="astronaut@toki.space" required />

            <label className="label" htmlFor="pw" style={{ marginTop: 6 }}>Password</label>
            <input id="pw" className="input" type="password" placeholder="••••••••" required />

            <button className="btn" type="submit" style={{ marginTop: 14, width:"100%" }}>Log In</button>
          </form>
          <div style={{ textAlign:"center", fontSize:".9rem", color:"var(--muted)" }}>
            Don't have an account? <Link to="/signup" style={{ color:"#a7c6ff" }}>Sign up</Link>
          </div>
        </GlassCard>
      </div>
    </PageShell>
  );
}
