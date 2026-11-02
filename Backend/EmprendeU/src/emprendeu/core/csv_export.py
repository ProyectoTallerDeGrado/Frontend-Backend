"""Exportacion a CSV compartida (auditoria y reportes)."""

import csv
import io
from collections.abc import Iterable, Sequence


def to_csv(headers: Sequence[str], rows: Iterable[Sequence[object]]) -> str:
    """CSV con BOM UTF-8, para que Excel muestre bien las tildes."""
    buffer = io.StringIO()
    writer = csv.writer(buffer)
    writer.writerow(headers)
    for row in rows:
        writer.writerow(["" if cell is None else cell for cell in row])
    return "\ufeff" + buffer.getvalue()
