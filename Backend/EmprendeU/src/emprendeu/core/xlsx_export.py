"""Exportacion a Excel (.xlsx) de los reportes, junto a `csv_export.py`."""

import io
from collections.abc import Iterable, Sequence

from openpyxl import Workbook
from openpyxl.styles import Font

XLSX_MEDIA_TYPE = "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
_MAX_SHEET_TITLE = 31  # limite de Excel


def to_xlsx(
    title: str, headers: Sequence[str], rows: Iterable[Sequence[object]]
) -> bytes:
    """Libro de una hoja con encabezado en negrita.

    Los textos se escriben como texto literal: un valor que empieza por `=` no se
    evalua como formula al abrir el archivo.
    """
    workbook = Workbook()
    sheet = workbook.active
    assert sheet is not None
    sheet.title = "".join(c for c in title if c not in "[]:*?/\\")[:_MAX_SHEET_TITLE]
    sheet.append(list(headers))
    for cell in sheet[1]:
        cell.font = Font(bold=True)
    for row in rows:
        sheet.append(["" if cell is None else cell for cell in row])
    for row in sheet.iter_rows(min_row=2):
        for cell in row:
            if isinstance(cell.value, str):
                cell.data_type = "s"
    for index, header in enumerate(headers, start=1):
        sheet.column_dimensions[
            sheet.cell(row=1, column=index).column_letter
        ].width = max(12, min(48, len(str(header)) + 4))
    buffer = io.BytesIO()
    workbook.save(buffer)
    return buffer.getvalue()
