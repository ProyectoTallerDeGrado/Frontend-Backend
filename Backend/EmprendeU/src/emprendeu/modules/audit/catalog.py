"""Catalogo de acciones auditables: `categoria.accion` -> texto para la UI.

Categorias (filtros de la pantalla de auditoria): accesos, usuarios, roles,
config y negocio.
"""

ACTION_LABELS: dict[str, str] = {
    "accesos.login": "Inicio de sesión",
    "accesos.login_fallido": "Intento de acceso fallido",
    "usuarios.crear": "Creó usuario",
    "usuarios.registro": "Registro de usuario",
    "usuarios.habilitar": "Habilitó cuenta",
    "usuarios.deshabilitar": "Deshabilitó cuenta",
    "usuarios.cambiar_rol": "Cambió el rol",
    "usuarios.cambiar_clave": "Cambió su contraseña",
    "roles.modificar_permisos": "Modificó permisos",
    "config.parametros": "Cambió parámetros de seguimiento",
    "config.reto": "Actualizó el reto",
    "config.insignia": "Actualizó la insignia",
    "config.etapa": "Actualizó la etapa",
    "negocio.emprendimiento": "Actualizó el emprendimiento",
    "negocio.etapa_emprendimiento": "Cambió la etapa del emprendimiento",
    "negocio.documento": "Gestionó un documento",
    "negocio.conocimiento": "Gestionó la base de conocimiento",
}


def label_for(action: str) -> str:
    return ACTION_LABELS.get(action, action)


def category_of(action: str) -> str:
    return action.split(".", 1)[0]
