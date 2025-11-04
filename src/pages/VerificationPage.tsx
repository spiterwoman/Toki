import React, { useState, useEffect, useRef } from "react";
import { Mail } from "lucide-react";
import GlassCard from "../components/GlassCard";
import PageShell from "../components/PageShell";
import { Button } from "../components/ui/button";
import { InputOTP, InputOTPGroup, InputOTPSlot } from "../components/ui/input-otp";

interface VerificationPageProps {
  onVerify: () => void;
}

export default function VerificationPage({ onVerify }: VerificationPageProps) {
  const [otp, setOtp] = useState('');
  const otpRef = useRef<HTMLInputElement>(null);

  useEffect(() => {
    // Focus the OTP input on mount
    if (otpRef.current) {
      otpRef.current.focus();
    }
  }, []);

  const handleVerify = () => {
    if (otp.length === 6) {
      const success = onVerify();
      
      // If verification failed, refocus the input
      if(!success){
        otpRef.current?.focus();
      }
    } else {
      otpRef.current?.focus();
    }
  };

  return (
    <PageShell showMenu={false}>
      <div style={{ display: "grid", placeItems: "center", height: "100vh" }}>
        <GlassCard className="vstack" style={{ width: 420, padding: 28 }}>
          {/* Header */}
          <div style={{ textAlign: "center", marginBottom: 24 }}>
            <div style={{ display: "flex", justifyContent: "center", marginBottom: 16 }}>
              <div
                style={{
                  width: "64px",
                  height: "64px",
                  borderRadius: "50%",
                  backgroundColor: "rgba(128, 90, 213, 0.2)",
                  alignItems: "center",
                  justifyContent: "center",
                  display: "flex",
                }}
              >
                <Mail className="w-8 h-8" style={{ color: "#a78bfa" }} />
              </div>
            </div>
            <h2 style={{ margin: 0, fontSize: "1.875rem", color: "#fff" }}>Verify Your Email</h2>
            <div style={{ fontSize: "0.875rem", color: "rgba(255,255,255,0.6)", marginTop: 4 }}>
              We've sent a verification code to your email
            </div>
          </div>

          {/* OTP Input */}
          <InputOTP 
            ref={otpRef}
            maxLength={6} 
            value={otp} 
            onChange={(val) => setOtp(val.replace(/\D/g, ""))}
          >
            <InputOTPGroup style={{ display: "flex", justifyContent: "center", gap: "8px" }}>
                {Array.from({ length: 6 }).map((_, index) => (
                <InputOTPSlot
                    key={index}
                    index={index}
                    style={{
                    width: "40px",
                    height: "40px",
                    border: "1px solid rgba(255,255,255,0.2)",
                    borderRadius: "6px",
                    textAlign: "center",
                    lineHeight: "40px",
                    fontSize: "1.2rem",
                    color: "#fff",
                    backgroundColor: "rgba(255,255,255,0.1)",
                    boxShadow: otp[index] === undefined && index === otp.length ? "0 0 0 3px rgba(110,168,255,.15)" : "none",
                }}
                />
                ))}
            </InputOTPGroup>
          </InputOTP>

          {/* Verify Button */}
          <Button
            onClick={handleVerify}
            style={{ marginBottom: 12 }}
          >
            Verify Email
          </Button>

          {/* Resend */}
          <div style={{ textAlign: "center", fontSize: "0.9rem", color: "rgba(255,255,255,0.6)" }}>
            Didn't receive the code?
            <button style={{ 
                fontSize: "0.9rem",
                color: "#a7c6ff", 
                background: "none", 
                border: "none", 
                cursor: "pointer",
                textDecoration: "underline"}}
                >
              Resend
            </button>
          </div>
        </GlassCard>
      </div>
    </PageShell>
  );
}