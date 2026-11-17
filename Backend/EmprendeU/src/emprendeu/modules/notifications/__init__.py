"""Modulo notifications: bandeja de avisos y notificaciones push (FCM) del celular.

API publica: `NotificationService.notify` (lo usan mentoring, training, ventures y
gamification) y los ganchos del envio push (`set_push_dispatcher`,
`wait_for_pushes`). El `router` lo importa `api/v1.py`.
"""

from emprendeu.modules.notifications.models import DispositivoPush, Notificacion
from emprendeu.modules.notifications.push import (
    FcmSender,
    PushDispatcher,
    PushMessage,
    PushResult,
    set_push_dispatcher,
    wait_for_pushes,
)
from emprendeu.modules.notifications.service import NotificationService

__all__ = [
    "DispositivoPush",
    "FcmSender",
    "Notificacion",
    "NotificationService",
    "PushDispatcher",
    "PushMessage",
    "PushResult",
    "set_push_dispatcher",
    "wait_for_pushes",
]
