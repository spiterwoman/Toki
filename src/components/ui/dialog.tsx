import {
  createContext,
  useContext,
  useEffect,
  useRef,
  Children,
  cloneElement,
  type ReactNode,
  type ReactElement,
} from "react";

type Ctx = { open: boolean; setOpen: (v: boolean) => void };
const DialogCtx = createContext<Ctx | null>(null);

export function Dialog({
  open,
  onOpenChange,
  children,
}: {
  open: boolean;
  onOpenChange: (v: boolean) => void;
  children: ReactNode;
}) {
  return (
    <DialogCtx.Provider value={{ open, setOpen: onOpenChange }}>
      {children}
    </DialogCtx.Provider>
  );
}

type AnyEl = ReactElement<any, any>;

export function DialogTrigger({
  children,
}: {
  children: AnyEl;
}) {
  const ctx = useContext(DialogCtx);
  if (!ctx) throw new Error("DialogTrigger must be used inside <Dialog>");
  const child = Children.only(children) as AnyEl;
  const originalOnClick = (child.props as any).onClick as
    | ((e: any) => void)
    | undefined;

  return cloneElement(child, {
    onClick: (e: any) => {
      originalOnClick?.(e);
      ctx.setOpen(true);
    },
  });
}

export function DialogContent({
  children,
  className = "",
}: {
  children: ReactNode;
  className?: string;
}) {
  const ctx = useContext(DialogCtx);
  if (!ctx) throw new Error("DialogContent must be used inside <Dialog>");
  const ref = useRef<HTMLDivElement>(null);

  useEffect(() => {
    const onKey = (e: KeyboardEvent) => {
      if (e.key === "Escape") ctx.setOpen(false);
    };
    if (ctx.open) document.addEventListener("keydown", onKey);
    return () => document.removeEventListener("keydown", onKey);
  }, [ctx]);

  if (!ctx.open) return null;

  return (
    <>
      <div className="scrim show" onClick={() => ctx.setOpen(false)} />
      <div
        ref={ref}
        className={`glass ${className}`}
        style={{
          position: "fixed",
          left: "50%",
          top: "18%",
          transform: "translateX(-50%)",
          minWidth: 360,
          maxWidth: "min(92vw, 560px)",
          padding: 20,
          zIndex: 60,
          background: "rgba(10,15,35,.92)",
        }}
      >
        {children}
      </div>
    </>
  );
}

export function DialogHeader({ children }: { children: ReactNode }) {
  return <div style={{ marginBottom: 8 }}>{children}</div>;
}

export function DialogTitle({
  children,
  className = "",
}: {
  children: ReactNode;
  className?: string;
}) {
  return (
    <h3 className={className} style={{ margin: 0 }}>
      {children}
    </h3>
  );
}
