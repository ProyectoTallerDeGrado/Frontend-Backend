# CU05 — Gestionar Emprendimiento

| Campo | Valor |
|---|---|
| Prioridad | Alta |
| Actor(es) | Coordinador (web) y emprendedor (app) |
| Cliente | Web y app móvil |
| Fase del plan | F4 |
| **Estado** | **✅ Completado (con equipo de emprendedores)** |

## Descripción

Crear, consultar y editar emprendimientos. **El coordinador crea el emprendimiento y le asigna uno o más
emprendedores (su equipo)**, y después puede agregar o quitar integrantes. Un emprendedor puede ser parte de
**varios** emprendimientos. El emprendedor solo ve y edita los suyos, sin tocar campos reservados, y ve a su
equipo en solo lectura.

## Qué se hizo

### Base (primera entrega)

- `POST /ventures`, `GET /ventures` (paginado), `GET /ventures/me`, `GET/PATCH /ventures/{id}`.
- El emprendedor solo accede a sus emprendimientos; si intenta cambiar campos de la coordinación (estado) recibe `ReservedFields` (403).
- Web `/ventures`: lista, «Nuevo emprendimiento» y «Editar» (nombre, sector, descripción y estado).
- Móvil: tarjeta para crear el emprendimiento (`CreateVentureCard`), `MyVentureCard` en Perfil y pantalla `/venture/edit`.

### Equipo del emprendimiento (segunda entrega)

1. **Crear con equipo.** `POST /ventures` recibe `integrantes: [{emprendedor_id, rol_en_emprendimiento}]`
   (1 a 20). El rol es `fundador`, `cofundador` o `miembro`. `emprendedor_id` sigue aceptándose como atajo de
   un solo integrante (queda como fundador). Errores: sin integrantes 422 `entrepreneur_required`; repetido 422
   `duplicate_member`; inexistente 422 `entrepreneur_not_found`; rol desconocido 422. Un emprendedor que crea
   desde la app queda solo, como fundador, y no puede sumar a otros (403).
2. **Gestionar el equipo** (solo personal con `emprendedores:modificacion`; el emprendedor recibe 403):
   - `GET /ventures/{id}/members`: lo ve el personal con `emprendedores:consulta` y cada integrante.
   - `POST /ventures/{id}/members`: agrega; si ya era integrante, 409 `already_member`.
   - `DELETE /ventures/{id}/members/{emprendedor_id}`: quita; si no era integrante, 404 `member_not_found`;
     **nunca queda vacío** (409 `last_member`).
   - Los cambios quedan en la auditoría (`negocio.emprendimiento`, acción `agregar_integrante` / `quitar_integrante`).
3. **`VentureOut.integrantes`**: cada emprendimiento (lista, detalle, `/me`) trae su equipo con nombre, correo,
   rol y fecha de ingreso, cargado en una sola consulta por página.
4. **Varios emprendimientos por emprendedor.** Quien sale del equipo deja de ver el emprendimiento (403). El Coach
   acepta `emprendimiento_id` en `POST /ai/chat` para asociar una conversación nueva (403 si no es suyo). El resto
   de los endpoints del emprendedor ya lo aceptaban (Camino, retos, agenda, avances, mentores, historial).
5. **Web.** «Nuevo emprendimiento» arma el equipo con filas «emprendedor + rol» (un emprendedor no se repite). La
   tabla de `/ventures` suma la columna **Equipo** y el botón **Equipo** (hoja lateral para ver, agregar y quitar;
   el botón de quitar se desactiva con un solo integrante).
6. **Móvil.**
   - `myVenturesProvider` trae todos los emprendimientos; `selectedVentureIdProvider` guarda el elegido y
     `myVentureProvider` es el elegido (o el primero). `currentVentureIdProvider` lo expone a otras features.
   - `VentureSwitcher` (solo con dos o más) aparece en Inicio y en «Mi emprendimiento».
   - Inicio, Camino (y cumplir retos), Mentorías (estado de agenda, asesores, agendar, historial, avances, también
     los guardados sin conexión) y el Coach envían el `emprendimiento_id` elegido.
   - «Mi emprendimiento» lista el equipo con su rol, en solo lectura.

## Dónde está implementado

| Capa | Archivos |
|---|---|
| Backend | `modules/entrepreneurs/` (`MemberRef`, `members_of_ventures`, `unlink_venture`, `link_venture` → `bool`); `modules/ventures/` (`schemas.py`: `MemberIn`, `MemberOut`, `VentureCreate.integrantes`; `service.py`: `_team_for_staff`, `_team_for_entrepreneur`, `add_member`, `remove_member`, `list_members`; `router.py`; `exceptions.py`); `modules/ai_assistant/` (`ChatRequest.emprendimiento_id`) |
| Migración | Ninguna: se usa la tabla existente `emprendimiento_emprendedores` (ya era N:N, con `rol_en_emprendimiento` y `fecha_ingreso`) |
| Web | `features/ventures/components/` (`team-picker.tsx`, `team-sheet.tsx` nuevos; `venture-form-sheet.tsx`, `ventures-screen.tsx`), `schemas/ventures-schemas.ts`, `server/actions.ts` (`addVentureMemberAction`, `removeVentureMemberAction`), `types.ts` |
| Móvil | `features/ventures/` (`venture.dart` con `VentureMember`, `venture_dto.dart`, `get_my_ventures_usecase.dart`, `ventures_providers.dart`, `venture_switcher.dart`, `my_venture_card.dart`); `gamification`, `mentoring` y `ai_assistant` (parámetro `ventureId` de datasource a provider); `home_screen.dart` |

## Por qué se hizo así

- **La base ya lo permitía.** `emprendimiento_emprendedores` es N:N con rol y fecha de ingreso, así que no hizo falta
  migración, solo reglas y endpoints.
- **Roles fijos** (`fundador`, `cofundador`, `miembro`): se filtran y muestran igual en web y móvil.
- **Al menos un integrante** para que ningún emprendimiento quede sin responsable ni visible para nadie en la app.
- **El equipo lo arma la coordinación**: el emprendedor solo lo consulta, así se evita que alguien se sume solo a un
  emprendimiento ajeno.
- **`emprendimiento_id` explícito en vez de un estado oculto en el backend**: el servidor no guarda «el emprendimiento
  activo»; cada cliente lo envía. Sin indicarlo, el backend usa el primero, así que los clientes viejos siguen
  funcionando.

## Verificación

- `Backend/EmprendeU/tests/test_venture_members_api.py`:
  - `test_cu05_equipo_del_emprendimiento` (validaciones de alta, crear con dos, ambos lo ven, agregar, duplicado, permisos, quitar, último integrante, equipo en la lista).
  - `test_cu05_un_emprendedor_en_varios_emprendimientos` (Camino por emprendimiento, conversación del Coach en el elegido, ajeno 403).
- Siguen pasando `test_entrepreneurs_api.py::test_cu05_emprendimiento_propio_y_campos_reservados` y `test_audit_ventures_api.py::test_emprendedor_crea_su_emprendimiento_y_ve_su_etapa`.
- `Frontend/app_emprendeu/test/features/ventures/ventures_screens_test.dart`: equipo visible, selector con varios (Inicio pide el Camino del elegido) y sin selector con uno.
- Resultado al hacer el cambio: backend `uv run pytest` → 83 pasaron, `ruff check` y `ruff format --check` limpios; móvil `flutter analyze` sin problemas y `flutter test` → 86 pasaron, 3 omitidas (integración opt-in); web `pnpm lint` y `pnpm build` sin errores.
- **No se probó a mano** en el navegador ni en un dispositivo.

## Pendiente

- El emprendimiento elegido en el móvil **no se recuerda** al cerrar la app (vuelve al primero).
- Sin conexión, la copia guardada de avances es una sola: si se cambia de emprendimiento sin red, puede mostrar los avances del anterior.
- El XP del Camino de un emprendimiento suma el XP total de sus integrantes, que incluye lo ganado en otros emprendimientos (el XP se guarda por emprendedor).
- La web no ofrece **cambiar el rol** de un integrante (hay que quitarlo y volver a agregarlo).
