"""El Excel exportado escribe los textos como texto, nunca como formulas."""

import io

from openpyxl import load_workbook

from emprendeu.core.xlsx_export import to_xlsx


def test_un_texto_que_parece_formula_no_se_evalua() -> None:
    data = to_xlsx(
        "Reporte [de] prueba: con/caracteres?*", ["Nombre", "Nota"], [["=1+1", None]]
    )
    sheet = load_workbook(io.BytesIO(data)).active
    assert sheet is not None
    assert sheet["A2"].value == "=1+1" and sheet["A2"].data_type == "s"
    assert sheet["B2"].value in ("", None)
    assert "[" not in sheet.title and len(sheet.title) <= 31
