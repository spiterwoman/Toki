import { useState, useRef, useEffect} from "react";
import { Mail } from "lucide-react";
import GlassCard from "../components/GlassCard";
import PageShell from "../components/PageShell";
import { Button } from "../components/ui/button";
import { InputOTP, InputOTPGroup, InputOTPSlot } from "../components/ui/input-otp";

interface VerificationPageProps {
  email: string;
  onSuccess: () => void;
}

export default function VerificationPage({ email, onSuccess }: VerificationPageProps) {
  const [otp, setOtp] = useState('');
  const [errorMsg, setErrorMsg] = useState('');
  const [loading, setLoading] = useState(false);
  const otpRef = useRef<HTMLInputElement>(null);

  useEffect(() => {
    // Focus the OTP input on mount
    if (otpRef.current) {
      otpRef.current.focus();
    }
  }, []);

  const handleVerify = async () => {
    if (otp.length !== 6) {
      setErrorMsg("Please enter the 6-digit code.");
      otpRef.current?.focus();
      return;
    }
    
    setLoading(true);
    setErrorMsg('');

    try {
      const res = await fetch('/api/verifyUser', {
        method: 'POST',
        headers: {'Content-Type': 'application/json'},
        body: JSON.stringify({
          email,
          verificationToken: otp,
          accessToken: localStorage.getItem('token'),
        }),
      });

      const data = await res.json();

      if (data.error === "success, send to Dashboard page") {
        onSuccess();
      } else if (data.error === "The JWT is no longer valid") {
        setErrorMsg("Your session expired. Please log in again.");
      } else {
        setErrorMsg("Invalid verification code. Try again.");
        otpRef.current?.focus();
      }

      } catch (err) {
      console.error(err);
      setErrorMsg("An unexpected error occurred. Please try again.");
      } finally {
        setLoading(false);
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

          {errorMsg && <div style={{ textAlign: "center", color: "rgba(255,255,255,0.6)", fontSize: "0.85rem", marginTop: 8 }}>{errorMsg}</div>}

          {/* Verify Button */}
          <Button
            onClick={handleVerify}
            style={{ marginBottom: 12 }}
            disabled={loading}
          >
            {loading ? "Verifying..." : "Verify Email"}
          </Button>
        </GlassCard>
      </div>
    </PageShell>
  );
}