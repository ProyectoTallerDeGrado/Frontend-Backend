"""Aprovisionador de cuentas para la admision (CU26).

Une `users` y `ventures`, que dependen de este modulo. Solo lo importa el router
(igual que `router.py` importa `users`), nunca el `__init__`.
"""

from __future__ import annotations

from sqlalchemy.ext.asyncio import AsyncSession

from emprendeu.modules.entrepreneurs.admission_service import Provisioned
from emprendeu.modules.entrepreneurs.models import Postulacion
from emprendeu.modules.entrepreneurs.service import EntrepreneurService
from emprendeu.modules.users import CurrentUser, build_user_service
from emprendeu.modules.ventures import VentureService
from emprendeu.modules.ventures.schemas import VentureCreate


class UsersAndVenturesProvisioner:
    def __init__(self, session: AsyncSession, actor: CurrentUser) -> None:
        self._session = session
        self._actor = actor

    async def provision(self, actor_id: int, application: Postulacion) -> Provisioned:
        user, temporary = await build_user_service(self._session).register_entrepreneur(
            self._actor,
            f"{application.nombre} {application.apellido}",
            application.email,
            application.documento_identidad or "",
            None,
            commit=False,
        )
        ref = await EntrepreneurService(self._session).ref_for_user(user.usuario_id)
        assert ref is not None  # register_entrepreneur crea el perfil
        venture = await VentureService(self._session).create(
            self._actor,
            VentureCreate(
                nombre=application.nombre_emprendimiento,
                descripcion=application.descripcion_emprendimiento,
                sector=application.sector,
                emprendedor_id=ref.emprendedor_id,
            ),
            commit=False,
        )
        return Provisioned(ref.emprendedor_id, venture.emprendimiento_id, temporary)
