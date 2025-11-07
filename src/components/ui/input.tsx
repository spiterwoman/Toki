import React from "react";
type Props = React.InputHTMLAttributes<HTMLInputElement>;

export function Input({ className = "", ...rest }: Props) {
  return <input className={`input ${className}`} {...rest} />;
}
