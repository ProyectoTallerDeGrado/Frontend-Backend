"""Acceso a datos de notificaciones y dispositivos."""

from __future__ import annotations

from datetime import datetime

from sqlalchemy import delete, func, select, update
from sqlalchemy.dialects.postgresql import insert
from sqlalchemy.ext.asyncio import AsyncSession

from emprendeu.modules.notifications.models import DispositivoPush, Notificacion


class NotificationRepository:
    def __init__(self, session: AsyncSession) -> None:
        self._session = session

    async def commit(self) -> None:
        await self._session.commit()

    # --- bandeja ---------------------------------------------------------------

    async def add_many(self, rows: list[Notificacion]) -> None:
        self._session.add_all(rows)
        await self._session.flush()

    async def existing_keys(self, user_ids: list[int], clave: str) -> set[int]:
        """Usuarios que ya recibieron el aviso con esta clave."""
        rows = await self._session.scalars(
            select(Notificacion.usuario_id).where(
                Notificacion.usuario_id.in_(user_ids), Notificacion.clave == clave
            )
        )
        return set(rows)

    async def list_for(
        self, usuario_id: int, unread_only: bool, offset: int, limit: int
    ) -> tuple[list[Notificacion], int]:
        where = [Notificacion.usuario_id == usuario_id]
        if unread_only:
            where.append(Notificacion.leida_en.is_(None))
        total = await self._session.scalar(
            select(func.count()).select_from(Notificacion).where(*where)
        )
        rows = await self._session.scalars(
            select(Notificacion)
            .where(*where)
            .order_by(
                Notificacion.creada_en.desc(), Notificacion.notificacion_id.desc()
            )
            .offset(offset)
            .limit(limit)
        )
        return list(rows), total or 0

    async def unread_count(self, usuario_id: int) -> int:
        return (
            await self._session.scalar(
                select(func.count())
                .select_from(Notificacion)
                .where(
                    Notificacion.usuario_id == usuario_id,
                    Notificacion.leida_en.is_(None),
                )
            )
            or 0
        )

    async def get(self, notificacion_id: int) -> Notificacion | None:
        return await self._session.get(Notificacion, notificacion_id)

    async def mark_all_read(self, usuario_id: int, moment: datetime) -> int:
        result = await self._session.execute(
            update(Notificacion)
            .where(
                Notificacion.usuario_id == usuario_id,
                Notificacion.leida_en.is_(None),
            )
            .values(leida_en=moment)
        )
        return result.rowcount or 0  # type: ignore[attr-defined]

    # --- dispositivos ------------------------------------------------------------

    async def upsert_device(
        self, usuario_id: int, token: str, plataforma: str, moment: datetime
    ) -> None:
        """Un token pertenece a un solo usuario: si otra cuenta inicia sesion en el
        mismo celular, el token pasa a ella."""
        stmt = insert(DispositivoPush).values(
            usuario_id=usuario_id,
            token=token,
            plataforma=plataforma,
            creado_en=moment,
            actualizado_en=moment,
        )
        await self._session.execute(
            stmt.on_conflict_do_update(
                constraint="uq_dispositivos_push_token",
                set_={
                    "usuario_id": stmt.excluded.usuario_id,
                    "plataforma": stmt.excluded.plataforma,
                    "actualizado_en": stmt.excluded.actualizado_en,
                },
            )
        )

    async def delete_device(self, usuario_id: int, token: str) -> int:
        result = await self._session.execute(
            delete(DispositivoPush).where(
                DispositivoPush.usuario_id == usuario_id,
                DispositivoPush.token == token,
            )
        )
        return result.rowcount or 0  # type: ignore[attr-defined]

    async def tokens_for(self, user_ids: list[int]) -> list[tuple[int, str]]:
        rows = await self._session.execute(
            select(DispositivoPush.usuario_id, DispositivoPush.token).where(
                DispositivoPush.usuario_id.in_(user_ids)
            )
        )
        return [(u, t) for u, t in rows.all()]

    async def delete_tokens(self, tokens: list[str]) -> None:
        if tokens:
            await self._session.execute(
                delete(DispositivoPush).where(DispositivoPush.token.in_(tokens))
            )
