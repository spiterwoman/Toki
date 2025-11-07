import React from "react";
type Props = React.HTMLAttributes<HTMLSpanElement> & { tone?: "ok" | "warn" | "danger" | "neutral" };

export function Badge({ className = "", tone = "neutral", ...rest }: Props) {
  const toneCls =
    tone === "ok" ? "ok" : tone === "warn" ? "warn" : tone === "danger" ? "danger" : "";
  return <span className={`badge ${toneCls} ${className}`} {...rest} />;
}
