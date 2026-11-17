// API pública de la feature `notifications` (bandeja y push con Firebase).
export 'data/notifications_data_providers.dart' show notificationsDataOverrides;
export 'presentation/controllers/notifications_providers.dart'
    show
        notificationsRepositoryProvider,
        pushMessagingProvider,
        unreadCountProvider;
export 'presentation/notifications_routes.dart'
    show NotificationsRoutes, notificationsRoutes;
export 'presentation/widgets/notifications_bell.dart' show NotificationsBell;
export 'presentation/widgets/push_gate.dart' show PushGate;
