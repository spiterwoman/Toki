import { useEffect, useRef } from "react";

type Star = { x: number; y: number; r: number; a: number; da: number };

export default function StarryBackground() {
  const canvasRef = useRef<HTMLCanvasElement>(null);
  const starsRef = useRef<Star[]>([]);

  useEffect(() => {
    const canvas = canvasRef.current;
    if (!canvas) return;
    const ctx = canvas.getContext("2d");
    if (!ctx) return;
    // create stars + count
    const makeStars = (w: number, h: number, dpr: number) => {
      const count = 200;
      const arr: Star[] = [];
      for (let i = 0; i < count; i++) {
        arr.push({
          x: Math.random() * w,
          y: Math.random() * h,
          r: (Math.random() * 2 + 0.5) * dpr,
          a: Math.random() * 0.7 + 0.3,
          da: (Math.random() * 0.6 + 0.2) * (Math.random() < 0.5 ? -1 : 1),
        });
      }
      starsRef.current = arr;
    };

    const resize = () => {
      const dpr = Math.max(1, Math.min(window.devicePixelRatio || 1, 2));
      const w = Math.floor(window.innerWidth);
      const h = Math.floor(window.innerHeight);
      canvas.style.width = `${w}px`;
      canvas.style.height = `${h}px`;
      canvas.width = Math.floor(w * dpr);
      canvas.height = Math.floor(h * dpr);
      ctx.setTransform(dpr, 0, 0, dpr, 0, 0);
      makeStars(w, h, 1);
    };

    resize();

    let raf = 0;
    const animate = () => {
      ctx.clearRect(0, 0, canvas.clientWidth, canvas.clientHeight);

      
      for (const s of starsRef.current) {
        ctx.beginPath();
        ctx.fillStyle = `rgba(255,255,255,${s.a.toFixed(3)})`;
        ctx.arc(s.x, s.y, s.r, 0, Math.PI * 2);
        ctx.fill();
        // twinkle
        s.a += s.da * 0.01;
        if (s.a > 1) { s.a = 1; s.da *= -1; }
        if (s.a < 0.25) { s.a = 0.25; s.da *= -1; }
      }

      raf = requestAnimationFrame(animate);
    };

    raf = requestAnimationFrame(animate);
    window.addEventListener("resize", resize);
    return () => {
      cancelAnimationFrame(raf);
      window.removeEventListener("resize", resize);
    };
  }, []);

  return (
    <div aria-hidden="true" style={{ position: "fixed", inset: 0, zIndex: -1 }}>
      <div
        style={{
          position: "absolute",
          inset: 0,
          backgroundImage: "radial-gradient(1200px 800px at 80% 0%, #1b2142 0%, rgba(11,16,32,0) 60%), radial-gradient(900px 700px at -10% 100%, #221a2a 0%, rgba(15,23,48,0) 60%)",
          opacity: 0.9,
        }}
      />
      <canvas ref={canvasRef} style={{ position: "absolute", inset: 0 }} />
      {/* planets */}
      <div
        style={{
          position: "absolute",
          top: 80,
          right: 80,
          width: 128,
          height: 128,
          borderRadius: "50%",
          opacity: 0.18,
          filter: "blur(2px)",
          background: "radial-gradient(circle at 30% 30%, #8b7dd8, #5a4a9a)",
        }}
      />
      <div
        style={{
          position: "absolute",
          bottom: 160,
          left: 40,
          width: 96,
          height: 96,
          borderRadius: "50%",
          opacity: 0.14,
          filter: "blur(2px)",
          background: "radial-gradient(circle at 30% 30%, #d88b7d, #9a5a4a)",
        }}
      />
    </div>
  );
}
