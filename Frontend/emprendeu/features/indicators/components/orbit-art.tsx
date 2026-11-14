/**
 * Motivo de órbitas de la marca para el Resumen. Cada satélite es un emprendimiento activo
 * (hasta 18): la figura crece con el programa. Decorativo (`aria-hidden`).
 */
export function OrbitArt({ satellites }: { satellites: number }) {
  const rings = [
    { r: 70, speed: "38s", reverse: false, dash: undefined, stroke: "rgb(255 255 255 / .22)" },
    { r: 120, speed: "64s", reverse: true, dash: "3 7", stroke: "rgb(255 255 255 / .3)" },
    { r: 170, speed: "110s", reverse: false, dash: undefined, stroke: "rgb(159 180 238 / .22)" },
  ];
  const count = Math.min(18, Math.max(0, satellites));
  // Reparte los satélites entre los tres anillos (de dentro hacia fuera).
  const perRing = [Math.ceil(count / 3), Math.ceil((count - Math.ceil(count / 3)) / 2), 0];
  perRing[2] = count - perRing[0] - perRing[1];
  const colors = ["var(--accent-bright)", "white", "var(--on-navy-dim)"];

  return (
    <svg
      aria-hidden="true"
      viewBox="0 0 400 400"
      className="pointer-events-none absolute -top-24 -right-20 size-[420px] animate-[orbit-in_1.2s_cubic-bezier(.2,.8,.2,1)_both] sm:-right-8"
    >
      <circle cx="200" cy="200" r="34" fill="var(--primary)" fillOpacity=".45" className="origin-center animate-[core-pulse_4s_ease-in-out_infinite] [transform-box:fill-box]" />
      <circle cx="200" cy="200" r="16" fill="var(--primary)" />
      {rings.map((ring, ri) => (
        <g
          key={ring.r}
          style={{
            transformOrigin: "200px 200px",
            animation: `${ring.reverse ? "orbit-spin-reverse" : "orbit-spin"} ${ring.speed} linear infinite`,
          }}
        >
          <circle cx="200" cy="200" r={ring.r} fill="none" stroke={ring.stroke} strokeWidth="1.5" strokeDasharray={ring.dash} />
          {Array.from({ length: perRing[ri] }, (_, i) => {
            const angle = (i / Math.max(1, perRing[ri])) * Math.PI * 2 + ri * 0.7;
            return (
              <circle
                key={i}
                cx={200 + ring.r * Math.cos(angle)}
                cy={200 + ring.r * Math.sin(angle)}
                r={ri === 0 ? 6 : 5}
                fill={colors[(i + ri) % colors.length]}
              />
            );
          })}
        </g>
      ))}
    </svg>
  );
}
