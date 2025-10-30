import type { PropsWithChildren, CSSProperties } from "react";

type Props = PropsWithChildren<{ className?: string; style?: CSSProperties }>;

export default function GlassCard({ className = "", style, children }: Props) {
  return (
    <div className={`glass ${className}`} style={style}>
      {children}
    </div>
  );
}
