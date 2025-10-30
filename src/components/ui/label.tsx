import React from "react";
type Props = React.LabelHTMLAttributes<HTMLLabelElement>;

export function Label({ className = "", ...rest }: Props) {
  return <label className={`label ${className}`} {...rest} />;
}
