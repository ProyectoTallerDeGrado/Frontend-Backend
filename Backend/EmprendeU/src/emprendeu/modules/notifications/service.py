"""Servicio de notificaciones: avisar a usuarios, bandeja y dispositivos push."""

from __future__ import annotations

from collections.abc import Iterable
from datetime import UTC, datetime

from sqlalchemy.ext.asyncio import AsyncSession

from emprendeu.core.pagination import PageParams
from emprendeu.modules.notifications import schemas as s
from emprendeu.modules.notifications.exceptions import NotificationNotFound
from emprendeu.modules.notifications.models import Notificacion
from emprendeu.modules.notifications.push import PushMessage, queue_push
from emprendeu.modules.notifications.repository import NotificationRepository
from emprendeu.modules.users import CurrentUser

TITLE_MAX = 120


def _out(n: Notificacion) -> s.NotificationOut:
    return s.NotificationOut(
        notificacion_id=n.notificacion_id,
        tipo=n.tipo,
        titulo=n.titulo,
        cuerpo=n.cuerpo,
        ruta=n.ruta,
        leida=n.leida_en is not None,
        creada_en=n.creada_en,
    )


class NotificationService:
    def __init__(self, session: AsyncSession) -> None:
        self._session = session
        self._repo = NotificationRepository(session)

    # --- API publica para otros modulos --------------------------------------

    async def notify(
        self,
        user_ids: Iterable[int],
        kind: str,
        title: str,
        body: str,
        *,
        route: str | None = None,
        key: str | None = None,
    ) -> int:
        """Guarda el aviso en la bandeja de cada usuario y lo deja listo para push.

        No hace commit: el aviso entra en la transaccion del llamador y el push sale
        solo si esa transaccion se confirma. Con `key`, un usuario que ya tiene un
        aviso con esa clave no recibe otro. Devuelve a cuantos usuarios se aviso.
        """
        ids = sorted(set(user_ids))
        if not ids:
            return 0
        if key:
            seen = await self._repo.existing_keys(ids, key)
            ids = [u for u in ids if u not in seen]
            if not ids:
                return 0
        title = title[:TITLE_MAX]
        await self._repo.add_many(
            [
                Notificacion(
                    usuario_id=u,
                    tipo=kind,
                    titulo=title,
                    cuerpo=body,
                    ruta=route,
                    clave=key,
                )
                for u in ids
            ]
        )
        queue_push(
            self._session,
            PushMessage(tuple(ids), title, body, {"tipo": kind, "ruta": route or ""}),
        )
        return len(ids)

    # --- bandeja (router) ------------------------------------------------------

    async def list(
        self, user: CurrentUser, unread_only: bool, params: PageParams
    ) -> tuple[list[s.NotificationOut], int]:
        rows, total = await self._repo.list_for(
            user.usuario_id, unread_only, params.offset, params.page_size
        )
        return [_out(n) for n in rows], total

    async def unread_count(self, user: CurrentUser) -> s.UnreadCount:
        return s.UnreadCount(no_leidas=await self._repo.unread_count(user.usuario_id))

    async def mark_read(
        self, user: CurrentUser, notificacion_id: int
    ) -> s.NotificationOut:
        row = await self._repo.get(notificacion_id)
        if row is None or row.usuario_id != user.usuario_id:
            raise NotificationNotFound
        if row.leida_en is None:
            row.leida_en = datetime.now(UTC)
            await self._repo.commit()
        return _out(row)

    async def mark_all_read(self, user: CurrentUser) -> s.UnreadCount:
        await self._repo.mark_all_read(user.usuario_id, datetime.now(UTC))
        await self._repo.commit()
        return s.UnreadCount(no_leidas=0)

    # --- dispositivos ------------------------------------------------------------

    async def register_device(self, user: CurrentUser, body: s.DeviceIn) -> None:
        await self._repo.upsert_device(
            user.usuario_id, body.token, body.plataforma, datetime.now(UTC)
        )
        await self._repo.commit()

    async def unregister_device(self, user: CurrentUser, token: str) -> None:
        await self._repo.delete_device(user.usuario_id, token)
        await self._repo.commit()
