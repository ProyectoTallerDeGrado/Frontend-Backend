"""Troceado de texto en fragmentos para la base de conocimiento."""

from __future__ import annotations


def chunk_text(text: str, *, size: int = 800, overlap: int = 100) -> list[str]:
    """Parte por parrafos y agrupa hasta ~`size` caracteres con algo de solape."""
    paragraphs = [
        p.strip() for p in text.replace("\r\n", "\n").split("\n\n") if p.strip()
    ]
    chunks: list[str] = []
    current = ""
    for paragraph in paragraphs:
        while len(paragraph) > size:  # parrafo gigante: cortar duro
            head, paragraph = paragraph[:size], paragraph[size - overlap :]
            if current:
                chunks.append(current)
                current = ""
            chunks.append(head)
        if current and len(current) + len(paragraph) + 2 > size:
            chunks.append(current)
            tail = current[-overlap:] if overlap else ""
            current = f"{tail}\n\n{paragraph}".strip()
        else:
            current = f"{current}\n\n{paragraph}".strip() if current else paragraph
    if current:
        chunks.append(current)
    return chunks
