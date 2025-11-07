import React from "react";

type Props = React.ButtonHTMLAttributes<HTMLButtonElement> & { asChild?: boolean };

export function Button({ asChild, className = "", ...rest }: Props) {
  const cls = `btn ${className}`;
  if (asChild) return <button className={cls} {...rest} />;
  return <button className={cls} {...rest} />;
}
