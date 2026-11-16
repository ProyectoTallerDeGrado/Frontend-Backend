import { ImageResponse } from "next/og";

export const alt = "CIE-U · Tu idea no debería morir en un cuaderno";
export const size = { width: 1200, height: 630 };
export const contentType = "image/png";

/** Colores de marca (los mismos de `globals.css`; aquí no hay CSS, la imagen se dibuja aparte). */
const NAVY = "#021f50";
const BLUE = "#1f4fd6";
const CORAL = "#ff5468";
const MUTED = "#c9d6f5";

/** Imagen que se ve al compartir el enlace (WhatsApp, redes): el titular de la portada. */
export default function OpengraphImage() {
  return new ImageResponse(
    (
      <div
        style={{
          width: "100%",
          height: "100%",
          display: "flex",
          flexDirection: "column",
          justifyContent: "space-between",
          padding: 72,
          background: NAVY,
          color: "white",
          position: "relative",
        }}
      >
        <div
          style={{
            position: "absolute",
            right: -380,
            top: -40,
            width: 700,
            height: 700,
            borderRadius: 700,
            border: `3px solid ${BLUE}`,
            display: "flex",
            alignItems: "center",
            justifyContent: "center",
          }}
        >
          <div style={{ width: 240, height: 240, borderRadius: 240, background: BLUE, display: "flex" }} />
        </div>
        <div style={{ display: "flex", fontSize: 34, fontWeight: 700 }}>CIE-U · FCEE · UAGRM</div>
        <div style={{ display: "flex", flexDirection: "column", fontSize: 92, fontWeight: 700, lineHeight: 1.02, letterSpacing: -3 }}>
          <div style={{ display: "flex", alignItems: "center" }}>
            <span>Tu</span>
            <span style={{ background: CORAL, color: NAVY, borderRadius: 18, padding: "0 22px 6px", marginLeft: 22 }}>idea</span>
          </div>
          <span>no debería morir</span>
          <span>en un cuaderno.</span>
        </div>
        <div style={{ display: "flex", fontSize: 32, color: MUTED }}>
          Mentorías, retos, coach IA y capacitaciones. Gratis para estudiantes.
        </div>
      </div>
    ),
    size,
  );
}
