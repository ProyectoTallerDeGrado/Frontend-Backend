# Compilar el manual con LaTeX

Archivos: `manual_usuario.tex` + carpeta `imagenes/` (9 MB, 54 capturas).

## Overleaf (sin instalar nada)
1. Crear un proyecto en overleaf.com → *Upload Project* con un .zip que contenga `manual_usuario.tex` y la carpeta `imagenes/` en la misma carpeta.
2. Menú → Compiler: **pdfLaTeX**.
3. Pulsar *Recompile* (dos veces, para que los índices se completen). Descargar el PDF.

## En Fedora
```bash
sudo dnf install texlive-scheme-medium texlive-babel-spanish texlive-tex-gyre texlive-tocloft texlive-float
cd docs/manual_usuario
pdflatex manual_usuario.tex && pdflatex manual_usuario.tex
```

## Regenerar el .tex tras editar el manual
`node build/md2tex.mjs` (lee `manual_usuario.md`, usa `build/preamble.tex`).
El `.md` sigue siendo la fuente; el `.tex` es un derivado.

> Estado: el `.tex` se generó, pero **no se compiló** porque no hay LaTeX instalado en esta máquina.
