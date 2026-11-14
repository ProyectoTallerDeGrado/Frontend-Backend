"use client";

import { Switch } from "@/components/ui/switch";
import { cn } from "@/lib/utils";

type ToggleSwitchProps = Omit<React.ComponentProps<typeof Switch>, "size"> & { label: string };

/** Interruptor del diseño: pista 44×26 y área de clic de 44 px. Requiere `label` accesible. */
export function ToggleSwitch({ label, className, ...props }: ToggleSwitchProps) {
  return (
    <Switch
      aria-label={label}
      className={cn(
        "h-[26px] w-11 rounded-full border-0 bg-switch-off data-checked:bg-primary data-unchecked:bg-switch-off",
        "after:-inset-x-1 after:-inset-y-2",
        "[&_[data-slot=switch-thumb]]:size-5 [&_[data-slot=switch-thumb]]:translate-x-[3px] [&_[data-slot=switch-thumb]]:bg-white [&_[data-slot=switch-thumb]]:shadow-[0_1px_3px_rgba(0,0,0,.3)] [&_[data-slot=switch-thumb]]:data-checked:translate-x-[21px]",
        className,
      )}
      {...props}
    />
  );
}
