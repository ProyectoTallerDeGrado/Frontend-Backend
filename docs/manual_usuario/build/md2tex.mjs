// Convierte manual_usuario.md en manual_usuario.tex (LaTeX, pdfLaTeX, formato APA 7).
// Uso: node build/md2tex.mjs   (cwd: docs/manual_usuario)
import fs from "node:fs";
import path from "node:path";

const ROOT = path.resolve(path.dirname(new URL(import.meta.url).pathname), "..");
const src = fs.readFileSync(path.join(ROOT, "manual_usuario.md"), "utf8").split("\n");

const MAP = { "\\": "\\textbackslash{}", "&": "\\&", "%": "\\%", "$": "\\$", "#": "\\#", "_": "\\_", "{": "\\{", "}": "\\}", "~": "\\textasciitilde{}", "^": "\\textasciicircum{}" };
function esc(t) {
  return t
    .replace(/[\\&%$#_{}~^]/g, (c) => MAP[c])
    .replace(/‑/g, "-")
    .replace(/→/g, "$\\rightarrow$")
    .replace(/…/g, "\\ldots{}");
}
function inline(t) {
  t = t.replace(/\{\{fig:([^}]+)\}\}/g, "$1");
  t = t.replace(/<i>(.*?)<\/i>/g, "$1").replace(/<b>(.*?)<\/b>/g, "$1");
  const codes = [];
  t = t.replace(/`([^`]+)`/g, (_, c) => { codes.push(c); return "" + (codes.length - 1) + ""; });
  t = esc(t);
  t = t.replace(/\*\*([^*]+)\*\*/g, "\\textbf{$1}").replace(/\*([^*]+)\*/g, "\\textit{$1}");
  t = t.replace(//g, "\\textit{").replace(//g, "}").replace(//g, "\\textbf{").replace(//g, "}");
  t = t.replace(/(\d+)/g, (_, n) => "\\texttt{" + esc(codes[n]) + "}");
  t = t.replace(/([^]+)/g, (_, k) => "Figura~\\ref{fig:" + k.replace(/\\_/g, "_") + "}");
  return t;
}
const plain = (t) => t.replace(/\*+/g, "").replace(/<[^>]+>/g, "");

const out = [];
let i = 0, figN = 0;
const pre = fs.readFileSync(path.join(ROOT, "build/preamble.tex"), "utf8");

// Portada: se toma de los <p class="cN"> del .md
const cover = {};
for (const l of src) { const m = l.match(/^<p class="c(\d)">(.*)<\/p>$/); if (m) (cover[m[1]] ||= []).push(m[2]); }

out.push(pre);
out.push("\\begin{document}");
out.push(`\\begin{titlepage}\\thispagestyle{empty}\\centering\\singlespacing
{\\bfseries ${inline(cover[1][0])}\\par}\\vspace{2.5cm}
{\\fontsize{30}{36}\\selectfont\\bfseries ${inline(cover[2][0])}\\par}\\vspace{.4cm}
{\\itshape ${inline(cover[3][0])}\\par}\\vspace{2cm}
{\\fontsize{22}{26}\\selectfont\\bfseries ${inline(cover[4][0])}\\par}\\vspace{.6cm}
${inline(cover[5][0])}\\par\\vspace{2.5cm}
${cover[6].map((c) => inline(c)).join("\\par\\vspace{.4cm}")}\\par
\\end{titlepage}
\\pagestyle{apa}\\setcounter{page}{2}
\\clearpage
\\tableofcontents\\clearpage
\\listoffigures\\clearpage
\\listoftables\\clearpage
\\doublespacing`);

// Salta portada e índices del .md: empezamos en el primer capítulo.
while (i < src.length && !/^# CAPÍTULO 1\./.test(src[i])) i++;

const HEAD = { 1: "section", 2: "subsection", 3: "subsubsection" };
let tabN = 0;
while (i < src.length) {
  const line = src[i];
  if (!line.trim()) { i++; continue; }
  if (line.trim() === "\\pagebreak") { out.push("\\clearpage"); i++; continue; }
  if (line.startsWith("<p class=\"ref\">")) {
    const t = line.replace(/^<p class="ref">/, "").replace(/<\/p>$/, "");
    out.push(`\\begin{hangref}${inline(t)}\\end{hangref}`); i++; continue;
  }
  let m = line.match(/^(#{1,3})(\*?) (.*)$/);
  if (m) {
    const lv = m[1].length, un = !!m[2], text = m[3];
    if (lv === 1) out.push("\\clearpage");
    const cmd = HEAD[lv];
    const t = inline(text);
    out.push(`\\${cmd}*{${t}}`);
    if (!(un && lv === 1)) out.push(`\\addcontentsline{toc}{${cmd}}{${t.replace(/\\ref\{[^}]*\}/g, "")}}`);
    i++; continue;
  }
  m = line.match(/^!\[(.*?)\]\((.*?)(?:\s+"(.*)")?\)\s*$/);
  if (m) {
    figN++;
    const key = path.basename(m[2], ".png");
    const mob = key.startsWith("movil_");
    const note = m[3] ? inline(m[3]).replace(/^Nota\./, "\\textit{Nota.}") : "";
    out.push(`\\begin{figure}[H]\\singlespacing
\\caption{${inline(m[1])}}\\label{fig:${key}}
\\centering\\fbox{\\includegraphics[${mob ? "height=0.52\\textheight" : "width=0.97\\textwidth"},keepaspectratio]{${m[2]}}}
${note ? `\\par\\vspace{3pt}\\begin{flushleft}\\small ${note}\\end{flushleft}` : ""}
\\end{figure}`);
    i++; continue;
  }
  m = line.match(/^Tabla: (.*)$/);
  if (m) {
    tabN++;
    const cap = inline(m[1]);
    i++; while (!src[i].trim()) i++;
    const rows = [];
    while (i < src.length && src[i].startsWith("|")) { rows.push(src[i]); i++; }
    const cells = (r) => r.replace(/^\||\|$/g, "").split("|").map((c) => c.trim());
    const head = cells(rows[0]), data = rows.slice(2).map(cells);
    const n = head.length;
    out.push(`\\begin{table}[H]\\singlespacing\\small
\\caption{${cap}}
\\begin{tabularx}{\\textwidth}{${"X".repeat(n)}}
\\toprule
${head.map((c) => `\\textbf{${inline(c)}}`).join(" & ")} \\\\
\\midrule
${data.map((r) => "\\relax " + r.map((c) => inline(c)).join(" & ") + " \\\\").join("\n")}
\\bottomrule
\\end{tabularx}
\\end{table}`);
    continue;
  }
  if (/^\d+\. /.test(line)) {
    const items = [];
    while (i < src.length && /^\d+\. /.test(src[i])) { items.push(src[i].replace(/^\d+\. /, "")); i++; }
    out.push(`\\begin{enumerate}\n${items.map((x) => `\\item ${inline(x)}`).join("\n")}\n\\end{enumerate}`);
    continue;
  }
  if (/^- /.test(line)) {
    const items = [];
    while (i < src.length && /^- /.test(src[i])) { items.push(src[i].slice(2)); i++; }
    out.push(`\\begin{itemize}\n${items.map((x) => `\\item ${inline(x)}`).join("\n")}\n\\end{itemize}`);
    continue;
  }
  const buf = [line]; i++;
  while (i < src.length && src[i].trim() && !/^(#|!\[|Tabla: |\d+\. |- |<|\\pagebreak|\[\[)/.test(src[i])) { buf.push(src[i]); i++; }
  out.push(inline(buf.join(" ")) + "\n");
}
out.push("\\end{document}");
const tex = out.join("\n\n").replace(/\n{3,}/g, "\n\n");
fs.writeFileSync(path.join(ROOT, "manual_usuario.tex"), tex);
const imgs = [...tex.matchAll(/\\includegraphics\[[^\]]*\]\{([^}]+)\}/g)].map((x) => x[1]);
const missing = imgs.filter((f) => !fs.existsSync(path.join(ROOT, f)));
console.log(`manual_usuario.tex: ${figN} figuras, ${tabN} tablas, imágenes faltantes: ${missing.length}`);
