import { useState, type PropsWithChildren } from "react";
import StarryBackground from "./StarryBackground";
import HamburgerMenu from "./HamburgerMenu";

type Props = PropsWithChildren<{
  title?: string;
  subtitle?: string;
  showMenu?: boolean;
}>;

export default function PageShell({ title, subtitle, showMenu = true, children }: Props) {
  const [open, setOpen] = useState(false);

  return (
    <>
      <StarryBackground />
      {showMenu && (
        <button
          className="menu-btn"
          onClick={() => setOpen((o) => !o)}
          aria-label={open ? "Close menu" : "Open menu"}
        >
          {open ? "×" : "☰"}
        </button>
      )}
      <HamburgerMenu open={open} onClose={() => setOpen(false)} />
      <div className="container">
        {title && <h1 className="page-title">{title}</h1>}
        {subtitle && <div className="page-sub">{subtitle}</div>}
        {children}
      </div>
    </>
  );
}

