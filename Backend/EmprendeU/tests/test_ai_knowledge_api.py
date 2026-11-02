"""Fase 5: base de conocimiento (CU31) y RAG del coach (CU11)."""

from io import BytesIO

from docx import Document
from httpx import AsyncClient
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from emprendeu.modules.ai_assistant.models import (
    AnalisisSentimiento,
    ConversacionIa,
    MensajeIa,
)
from tests.conftest import MakeUser

API = "/api/v1"

COSTOS = (
    "Para calcular tus costos separa costos fijos y variables.\n\n"
    "Con los costos puedes estimar el punto de equilibrio."
)
MARKETING = (
    "El marketing digital atrae clientes: define tu marketing en redes sociales.\n\n"
    "Mide el marketing con metricas simples."
)
FALLBACK = (
    "No encontré información suficiente en la base documental del CIE-U "
    "para responder con certeza."
)


def _pdf(text: str) -> bytes:
    """PDF minimo de una pagina con `text` (sin dependencias para crearlo)."""
    stream = f"BT /F1 12 Tf 72 720 Td ({text}) Tj ET".encode()
    objects = [
        b"<< /Type /Catalog /Pages 2 0 R >>",
        b"<< /Type /Pages /Kids [3 0 R] /Count 1 >>",
        b"<< /Type /Page /Parent 2 0 R /MediaBox [0 0 612 792] /Contents 4 0 R "
        b"/Resources << /Font << /F1 5 0 R >> >> >>",
        b"<< /Length %d >>\nstream\n" % len(stream) + stream + b"\nendstream",
        b"<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>",
    ]
    out, offsets = b"%PDF-1.4\n", []
    for number, body in enumerate(objects, 1):
        offsets.append(len(out))
        out += f"{number} 0 obj\n".encode() + body + b"\nendobj\n"
    xref = len(out)
    out += f"xref\n0 {len(objects) + 1}\n".encode() + b"0000000000 65535 f \n"
    out += b"".join(f"{o:010d} 00000 n \n".encode() for o in offsets)
    out += (
        f"trailer\n<< /Size {len(objects) + 1} /Root 1 0 R >>\n"
        f"startxref\n{xref}\n%%EOF\n"
    ).encode()
    return out


def _docx(*paragraphs: str) -> bytes:
    document = Document()
    for paragraph in paragraphs:
        document.add_paragraph(paragraph)
    buffer = BytesIO()
    document.save(buffer)
    return buffer.getvalue()


async def _world(client: AsyncClient, make_user: MakeUser, login):
    await make_user(rol="administrador", email="admin@test.com")
    await make_user(rol="coordinador", email="coord@test.com")
    await make_user(rol="asesor", email="asesor@test.com")
    await make_user(email="e@test.com")
    h = {k: await login(f"{k}@test.com") for k in ("admin", "coord", "asesor", "e")}
    vid = (
        await client.post(f"{API}/ventures", json={"nombre": "Mi idea"}, headers=h["e"])
    ).json()["emprendimiento_id"]
    return h, vid


async def _ingest(client: AsyncClient, headers, title: str, text: str) -> None:
    r = await client.post(
        f"{API}/ai/knowledge",
        json={"titulo": title, "contenido": text},
        headers=headers,
    )
    assert r.status_code == 201, r.text


async def _ask(client: AsyncClient, headers, question: str, cid: int | None = None):
    body: dict = {"mensaje": question}
    if cid is not None:
        body["conversacion_id"] = cid
    r = await client.post(f"{API}/ai/chat", json=body, headers=headers)
    assert r.status_code == 200, r.text
    return r.json()


async def test_cu31_subir_archivos_txt_md_pdf_docx(
    client: AsyncClient, make_user: MakeUser, login
) -> None:
    h, _ = await _world(client, make_user, login)
    files = {
        "notas.txt": (COSTOS.encode(), "text/plain"),
        "guia.md": (("# Guia\n\n" + COSTOS).encode(), "text/markdown"),
        "marketing.pdf": (
            _pdf("Guia de marketing: marketing en redes"),
            "application/pdf",
        ),
        "plan.docx": (
            _docx(
                "Modelo de negocio", "El modelo de negocio describe como ganas dinero."
            ),
            "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
        ),
    }
    for name, (content, ctype) in files.items():
        r = await client.post(
            f"{API}/ai/knowledge/upload",
            files={"file": (name, content, ctype)},
            data={"titulo": f"Documento {name}", "descripcion": "prueba"},
            headers=h["coord"],  # la coordinacion carga documentos
        )
        assert r.status_code == 201, (name, r.text)
        body = r.json()
        assert body["estado"] == "activo" and body["total_fragmentos"] >= 1, name
        assert body["fuente"] == name  # sin fuente indicada, el nombre del archivo
    listing = (await client.get(f"{API}/ai/knowledge", headers=h["coord"])).json()
    assert len(listing) == 4 and all(d["estado"] == "activo" for d in listing)

    # el texto del PDF y del DOCX de verdad quedo indexado: el coach lo encuentra
    reply = await _ask(client, h["e"], "Como hago marketing en redes?")
    assert reply["fuentes"] == ["Documento marketing.pdf"]
    reply = await _ask(client, h["e"], "Cual es mi modelo de negocio?")
    assert reply["fuentes"] == ["Documento plan.docx"]


async def test_cu31_rechazos_de_la_subida_no_dejan_rastro(
    client: AsyncClient, make_user: MakeUser, login
) -> None:
    h, _ = await _world(client, make_user, login)
    url = f"{API}/ai/knowledge/upload"

    def up(name: str, content: bytes, headers=None, **data: str):
        return client.post(
            url,
            files={"file": (name, content, "application/octet-stream")},
            data={"titulo": "T", **data},
            headers=headers or h["admin"],
        )

    exe = await up("virus.exe", b"MZ")
    assert (
        exe.status_code == 415
        and exe.json()["error"]["code"] == "file_type_not_allowed"
    )
    broken = await up("roto.pdf", b"esto no es un pdf")
    assert (
        broken.status_code == 422
        and broken.json()["error"]["code"] == "file_unreadable"
    )
    bad_docx = await up("roto.docx", b"tampoco")
    assert bad_docx.status_code == 422
    blank = await up("vacio.txt", b"   \n\n  ")
    assert (
        blank.status_code == 422 and blank.json()["error"]["code"] == "empty_knowledge"
    )
    # sin texto util en un PDF (pagina en blanco): tambien 422
    blank_pdf = await up("blanco.pdf", _pdf(""))
    assert blank_pdf.status_code == 422
    huge = await up("grande.txt", b"a" * (10 * 1024 * 1024 + 1))
    assert huge.status_code == 413
    # permisos: el asesor y el emprendedor no administran la base
    assert (await up("a.txt", COSTOS.encode(), h["asesor"])).status_code == 403
    assert (await up("a.txt", COSTOS.encode(), h["e"])).status_code == 403
    # nada quedo guardado
    assert (await client.get(f"{API}/ai/knowledge", headers=h["admin"])).json() == []


async def test_cu11_rag_con_dos_documentos_usa_el_fragmento_correcto(
    client: AsyncClient, make_user: MakeUser, login, session: AsyncSession
) -> None:
    h, vid = await _world(client, make_user, login)
    await _ingest(client, h["admin"], "Guia de costos", COSTOS)
    await _ingest(client, h["admin"], "Guia de marketing", MARKETING)
    llm = client._transport.app.state.fake_llm  # type: ignore[attr-defined]

    marketing = await _ask(client, h["e"], "Como mejoro mi marketing en redes?")
    assert marketing["fuente"] is True and marketing["fuentes"] == ["Guia de marketing"]
    assert (
        "marketing digital atrae clientes" in llm.last_system
    )  # el fragmento correcto
    assert "punto de equilibrio" not in llm.last_system  # y no el del otro documento

    costos = await _ask(
        client, h["e"], "Como calculo mis costos?", marketing["conversacion_id"]
    )
    assert costos["fuentes"] == ["Guia de costos"]
    assert "punto de equilibrio" in llm.last_system
    assert "marketing digital" not in llm.last_system

    # la conversacion queda con su emprendedor y su emprendimiento, y cada mensaje guardado
    conversation = (
        await session.execute(
            select(ConversacionIa).where(
                ConversacionIa.conversacion_ia_id == marketing["conversacion_id"]
            )
        )
    ).scalar_one()
    assert conversation.emprendimiento_id == vid and conversation.emprendedor_id
    kinds = (
        (
            await session.execute(
                select(MensajeIa.tipo)
                .where(MensajeIa.conversacion_ia_id == conversation.conversacion_ia_id)
                .order_by(MensajeIa.mensaje_ia_id)
            )
        )
        .scalars()
        .all()
    )
    assert list(kinds) == ["usuario", "asistente", "usuario", "asistente"]


async def test_cu11_sin_fragmentos_relevantes_no_inventa(
    client: AsyncClient, make_user: MakeUser, login
) -> None:
    h, _ = await _world(client, make_user, login)
    await _ingest(client, h["admin"], "Guia de costos", COSTOS)
    llm = client._transport.app.state.fake_llm  # type: ignore[attr-defined]
    before = llm.chat_calls

    reply = await _ask(client, h["e"], "Receta de pasta con tomate")
    assert reply["respuesta"]["contenido"] == FALLBACK
    assert reply["fuente"] is False and reply["fuentes"] == []
    assert reply["derivar_mentor"] is True
    assert llm.chat_calls == before  # el modelo ni siquiera se consulta

    # un documento inactivo tampoco sirve de fuente
    listing = (await client.get(f"{API}/ai/knowledge", headers=h["admin"])).json()
    doc_id = listing[0]["documento_conocimiento_id"]
    off = await client.delete(f"{API}/ai/knowledge/{doc_id}", headers=h["coord"])
    assert off.status_code == 200 and off.json()["estado"] == "inactivo"
    again = await _ask(client, h["e"], "Como calculo mis costos?")
    assert again["fuente"] is False and again["respuesta"]["contenido"] == FALLBACK


async def test_cu11_ollama_caido_error_claro_y_nada_a_medias(
    client: AsyncClient, make_user: MakeUser, login, session: AsyncSession
) -> None:
    h, _ = await _world(client, make_user, login)
    await _ingest(client, h["admin"], "Guia de costos", COSTOS)
    llm = client._transport.app.state.fake_llm  # type: ignore[attr-defined]

    # conversacion nueva con el modelo caido: ni conversacion, ni mensajes, ni sentimiento
    llm.down = True
    down = await client.post(
        f"{API}/ai/chat", json={"mensaje": "costos"}, headers=h["e"]
    )
    assert down.status_code == 503
    error = down.json()["error"]
    assert (
        error["code"] == "ai_unavailable" and "no esta disponible" in error["message"]
    )
    assert (await client.get(f"{API}/ai/conversations/me", headers=h["e"])).json() == []
    for model in (ConversacionIa, MensajeIa, AnalisisSentimiento):
        total = (
            await session.execute(select(func.count()).select_from(model))
        ).scalar_one()
        assert total == 0, model

    # conversacion existente: tras la caida sigue con los mismos 2 mensajes
    llm.down = False
    ok = await _ask(client, h["e"], "Como calculo mis costos?")
    cid = ok["conversacion_id"]
    llm.down = True
    again = await client.post(
        f"{API}/ai/chat",
        json={"mensaje": "y mis ventas?", "conversacion_id": cid},
        headers=h["e"],
    )
    assert again.status_code == 503
    llm.down = False
    messages = (
        await client.get(f"{API}/ai/conversations/{cid}/messages", headers=h["e"])
    ).json()
    assert [m["tipo"] for m in messages] == ["usuario", "asistente"]
    sentiments = (
        await session.execute(select(func.count()).select_from(AnalisisSentimiento))
    ).scalar_one()
    assert sentiments == 1  # solo el del mensaje que si se respondio


async def test_cu31_ollama_caido_al_subir_deja_el_documento_en_error(
    client: AsyncClient, make_user: MakeUser, login
) -> None:
    h, _ = await _world(client, make_user, login)
    client._transport.app.state.fake_llm.down = True  # type: ignore[attr-defined]
    r = await client.post(
        f"{API}/ai/knowledge/upload",
        files={"file": ("guia.txt", COSTOS.encode(), "text/plain")},
        data={"titulo": "Guia"},
        headers=h["coord"],
    )
    assert r.status_code == 503
    listing = (await client.get(f"{API}/ai/knowledge", headers=h["coord"])).json()
    assert [(d["titulo"], d["estado"], d["total_fragmentos"]) for d in listing] == [
        ("Guia", "error", 0)
    ]
    # un documento en error no alimenta al coach
    client._transport.app.state.fake_llm.down = False  # type: ignore[attr-defined]
    reply = await _ask(client, h["e"], "Como calculo mis costos?")
    assert reply["fuente"] is False


async def test_rf07_el_sentimiento_se_guarda_anonimizado(
    client: AsyncClient, make_user: MakeUser, login, session: AsyncSession
) -> None:
    h, _ = await _world(client, make_user, login)
    await _ask(client, h["e"], "Estoy muy triste y cansado")
    await _ask(client, h["e"], "Tuve un gran avance, estoy feliz")
    rows = (await session.execute(select(AnalisisSentimiento))).scalars().all()
    assert len(rows) == 2
    # solo el indice, la fecha y el emprendedor; ningun enlace al texto del mensaje
    assert all(r.mensaje_ia_id is None and r.indice is not None for r in rows)
    assert all(r.emprendedor_id for r in rows)
    # y el personal sigue viendo la serie agregada (la usan las alertas)
    eid = rows[0].emprendedor_id
    series = (await client.get(f"{API}/ai/sentiment/{eid}", headers=h["coord"])).json()
    assert series[0]["mensajes"] == 2
