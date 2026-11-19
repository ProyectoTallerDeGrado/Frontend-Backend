// Genera manual_usuario.pdf a partir de manual_usuario.md (dos pasadas para los números de página).
// Uso: node build/build.mjs   (cwd: docs/manual_usuario)
import fs from "node:fs";
import path from "node:path";
import { execFileSync } from "node:child_process";
import { createRequire } from "node:module";

const ROOT = path.resolve(path.dirname(new URL(import.meta.url).pathname), "..");
const PW = process.env.PLAYWRIGHT_ENTRY ||
  "/home/alan/Projects/Taller/ProyectoGrupal/Frontend-Backend/Frontend/emprendeu/node_modules/@playwright/test/index.mjs";
const CHROME = process.env.CHROME_BIN ||
  "/home/alan/.cache/ms-playwright/chromium-1255/chrome-linux64/chrome";
const { chromium } = await import(PW);

const esc = (t) => t.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");
function inline(t) {
  t = t.replace(/<(\/?(?:i|b|em|strong|br))>/g, "\u0001$1\u0002");
  t = esc(t).replace(/\u0001/g, "<").replace(/\u0002/g, ">");
  t = t.replace(/`([^`]+)`/g, "<code>$1</code>");
  t = t.replace(/\*\*([^*]+)\*\*/g, "<strong>$1</strong>");
  t = t.replace(/\*([^*]+)\*/g, "<em>$1</em>");
  return t;
}

const src = fs.readFileSync(path.join(ROOT, "manual_usuario.md"), "utf8").split("\n");
const toc = [], lof = [], lot = [];
const figByFile = {};
let figN = 0, tabN = 0, uid = 0;
const body = [];
let i = 0;

// primera pasada para numerar figuras (para referencias {{fig:...}})
for (const l of src) {
  const m = l.match(/^!\[(.*?)\]\((.*?)(?:\s+"(.*)")?\)\s*$/);
  if (m) { figN++; figByFile[path.basename(m[2], ".png")] = figN; }
}
figN = 0;

function refs(t) {
  return t.replace(/\{\{fig:([^}]+)\}\}/g, (_, k) => {
    if (!figByFile[k]) throw new Error("ref a figura inexistente " + k);
    return `Figura ${figByFile[k]}`;
  });
}

while (i < src.length) {
  const line = src[i];
  if (!line.trim()) { i++; continue; }
  if (line.trim() === "\\pagebreak") { body.push('<div class="pb"></div>'); i++; continue; }
  if (line.startsWith("<div") || line.startsWith("</div") || line.startsWith("<p class")) {
    body.push(refs(line)); i++; continue;
  }
  if (line.trim() === "[[TOC]]" || line.trim() === "[[LOF]]" || line.trim() === "[[LOT]]") {
    body.push(line.trim()); i++; continue;
  }
  let m = line.match(/^(#{1,3})(\*?) (.*)$/);
  if (m) {
    const level = m[1].length, unnum = !!m[2], text = m[3];
    const id = "h" + ++uid;
    if (!unnum || level > 1) {
      if (!(unnum && ["ÍNDICE GENERAL", "ÍNDICE DE FIGURAS", "ÍNDICE DE TABLAS"].includes(text)))
        toc.push({ level, text, id });
    }
    const cls = level === 1 ? (unnum ? "h1 unnum" : "h1 chap") : `h${level}`;
    const brk = level === 1 && !unnum ? " pbefore" : "";
    body.push(`<h${level} id="${id}" class="${cls}${brk}" data-t="${esc(text)}">${inline(text)}</h${level}>`);
    i++; continue;
  }
  m = line.match(/^!\[(.*?)\]\((.*?)(?:\s+"(.*)")?\)\s*$/);
  if (m) {
    figN++;
    const id = "f" + figN;
    lof.push({ n: figN, text: m[1], id });
    const file = path.join(ROOT, m[2]);
    if (!fs.existsSync(file)) throw new Error("falta imagen " + m[2]);
    const mob = path.basename(m[2]).startsWith("movil_");
    body.push(`<figure class="fig${mob ? " mob" : ""}" id="${id}"><p class="fl"><strong>Figura ${figN}</strong></p><p class="ft"><em>${inline(m[1])}</em></p><img src="../${m[2]}">${m[3] ? `<p class="fn">${inline(m[3]).replace(/^Nota\./, "<em>Nota.</em>")}</p>` : ""}</figure>`);
    i++; continue;
  }
  m = line.match(/^Tabla: (.*)$/);
  if (m) {
    tabN++;
    const id = "t" + tabN;
    lot.push({ n: tabN, text: m[1], id });
    i++; while (!src[i].trim()) i++;
    const rows = [];
    while (i < src.length && src[i].startsWith("|")) { rows.push(src[i]); i++; }
    const cells = (r) => r.replace(/^\||\|$/g, "").split("|").map((c) => c.trim());
    const head = cells(rows[0]);
    const data = rows.slice(2).map(cells);
    body.push(`<div class="tbl" id="${id}"><p class="fl"><strong>Tabla ${tabN}</strong></p><p class="ft"><em>${inline(m[1])}</em></p><table><thead><tr>${head.map((c) => `<th>${inline(c)}</th>`).join("")}</tr></thead><tbody>${data.map((r) => `<tr>${r.map((c) => `<td>${inline(c)}</td>`).join("")}</tr>`).join("")}</tbody></table></div>`);
    continue;
  }
  if (/^\d+\. /.test(line)) {
    const items = [];
    while (i < src.length && /^\d+\. /.test(src[i])) { items.push(src[i].replace(/^\d+\. /, "")); i++; }
    body.push(`<ol>${items.map((x) => `<li>${inline(refs(x))}</li>`).join("")}</ol>`);
    continue;
  }
  if (/^- /.test(line)) {
    const items = [];
    while (i < src.length && /^- /.test(src[i])) { items.push(src[i].slice(2)); i++; }
    body.push(`<ul>${items.map((x) => `<li>${inline(refs(x))}</li>`).join("")}</ul>`);
    continue;
  }
  // párrafo (junta líneas contiguas)
  const buf = [line]; i++;
  while (i < src.length && src[i].trim() && !/^(#|!\[|Tabla: |\d+\. |- |<|\\pagebreak|\[\[)/.test(src[i])) { buf.push(src[i]); i++; }
  body.push(`<p>${inline(refs(buf.join(" ")))}</p>`);
}

const css = fs.readFileSync(path.join(ROOT, "build/manual.css"), "utf8");
const pages = JSON.parse(fs.existsSync(path.join(ROOT, "build/pages.json")) ? fs.readFileSync(path.join(ROOT, "build/pages.json"), "utf8") : "{}");
const pg = (id) => pages[id] ?? "0";
const leader = (label, id, cls = "") => `<div class="tl ${cls}"><span class="tt">${label}</span><span class="td"></span><span class="tp">${pg(id)}</span></div>`;

function render() {
  const tocHtml = toc.map((e) => leader(inline(e.text), e.id, "l" + e.level)).join("");
  const lofHtml = lof.map((e) => leader(`Figura ${e.n}. ${inline(e.text)}`, e.id)).join("");
  const lotHtml = lot.map((e) => leader(`Tabla ${e.n}. ${inline(e.text)}`, e.id)).join("");
  return `<!doctype html><html lang="es"><head><meta charset="utf-8"><title>Manual de usuario – EmprendeU</title><style>${css}</style></head><body>${body.join("\n").replace("[[TOC]]", tocHtml).replace("[[LOF]]", lofHtml).replace("[[LOT]]", lotHtml)}</body></html>`;
}

const browser = await chromium.launch({ executablePath: CHROME });
const out = path.join(ROOT, "manual_usuario.pdf");
async function pass() {
  fs.writeFileSync(path.join(ROOT, "build/manual.html"), render());
  const page = await browser.newPage();
  await page.goto("file://" + path.join(ROOT, "build/manual.html"));
  await page.evaluate(() => document.fonts.ready);
  await page.pdf({
    path: out, format: "Letter", printBackground: true,
    margin: { top: "2.54cm", bottom: "2.54cm", left: "2.54cm", right: "2.54cm" },
    displayHeaderFooter: true, headerTemplate: "<span></span>",
    footerTemplate: `<div style="font-family:'Liberation Serif';font-size:12px;width:100%;text-align:right;padding-right:2.54cm"><span class="pageNumber"></span></div>`,
  });
  await page.close();
}
async function locate() {
  const n = Number(/Pages:\s+(\d+)/.exec(execFileSync("pdfinfo", [out]).toString())[1]);
  const res = {};
  const txt = [];
  for (let p = 1; p <= n; p++) txt.push(execFileSync("pdftotext", ["-f", String(p), "-l", String(p), "-layout", out, "-"]).toString().replace(/\s+/g, " "));
  const norm = (s) => s.replace(/<[^>]+>/g, "").replace(/\s+/g, " ").trim();
  const firstBody = txt.findIndex((t) => /CAPÍTULO 1\. INTRODUCCIÓN/.test(t) && !/\.{5,}/.test(t) && !/ÍNDICE/.test(t.slice(0, 80)));
  let start = 0;
  for (let p = 0; p < n; p++) if (/^\s*CAPÍTULO 1\. INTRODUCCIÓN\s+(?!\d)/.test(txt[p]) || (/CAPÍTULO 1\. INTRODUCCIÓN/.test(txt[p]) && !/ÍNDICE GENERAL/.test(txt[p]) && p > 2)) { start = p; break; }
  for (const e of toc) {
    const key = norm(e.text.replace(/\*+/g, ""));
    for (let p = start; p < n; p++) if (txt[p].includes(key)) { res[e.id] = p + 1; break; }
    if (e.level === 1 && !res[e.id]) for (let p = 0; p < n; p++) if (txt[p].includes(key)) { res[e.id] = p + 1; break; }
  }
  for (const f of lof) for (let p = start; p < n; p++) if (new RegExp(`Figura ${f.n}\\s`).test(txt[p]) && txt[p].includes(norm(f.text).slice(0, 30))) { res[f.id] = p + 1; break; }
  for (const t of lot) for (let p = start; p < n; p++) if (new RegExp(`Tabla ${t.n}\\s`).test(txt[p]) && txt[p].includes(norm(t.text).slice(0, 25))) { res[t.id] = p + 1; break; }
  return { res, n };
}
await pass();
let prev = "";
for (let k = 0; k < 3; k++) {
  const { res, n } = await locate();
  const j = JSON.stringify(res);
  fs.writeFileSync(path.join(ROOT, "build/pages.json"), j);
  const miss = [...toc, ...lof, ...lot].filter((e) => !res[e.id]).map((e) => e.text);
  console.log(`pasada ${k + 1}: ${n} páginas, sin ubicar: ${miss.length}`, miss.slice(0, 5));
  if (j === prev) break;
  prev = j;
  Object.assign(pages, res);
  await pass();
}
await browser.close();
