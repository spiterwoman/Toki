import React, { createContext, useContext } from "react";

type Ctx = { value: string; onChange: (v: string) => void };
const SelectCtx = createContext<Ctx | null>(null);

export function Select({
  value,
  onValueChange,
  children,
}: { value: string; onValueChange: (v: string) => void; children: React.ReactNode }) {
  return (
    <SelectCtx.Provider value={{ value, onChange: onValueChange }}>
      {children}
    </SelectCtx.Provider>
  );
}

export function SelectTrigger({ children, className = "" }: { children?: React.ReactNode; className?: string }) {
  const ctx = useContext(SelectCtx)!;
  return (
    <select
      className={`input ${className}`}
      value={ctx.value}
      onChange={(e) => ctx.onChange(e.target.value)}
    >
      {children}
    </select>
  );
}

// For API compatibility; render <option> children.
export function SelectContent({ children }: { children: React.ReactNode }) {
  return <>{children}</>;
}

export function SelectItem({ value, children }: { value: string; children: React.ReactNode }) {
  return <option value={value}>{children}</option>;
}

export function SelectValue() { return null; }
