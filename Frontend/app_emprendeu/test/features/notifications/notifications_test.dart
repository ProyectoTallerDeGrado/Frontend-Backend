import 'package:app_emprendeu/features/notifications/domain/entities/app_notification.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_app.dart';
import '../auth/fake_auth_repository.dart';
import 'fake_notifications.dart';

Future<void> _tap(WidgetTester tester, Finder target) async {
  await tester.ensureVisible(target);
  await tester.pump(const Duration(milliseconds: 300));
  await tester.tap(target);
  await settle(tester);
}

void main() {
  group('safeRoute', () {
    test('acepta pantallas conocidas y rechaza el resto', () {
      expect(safeRoute('/mentoring/session/3'), '/mentoring/session/3');
      expect(safeRoute('/training'), '/training');
      expect(safeRoute('/admin'), isNull);
      expect(safeRoute('/trainingx'), isNull);
      expect(safeRoute('https://evil.com'), isNull);
      expect(safeRoute('/mentoring/../admin'), isNull);
      expect(safeRoute(''), isNull);
      expect(safeRoute(null), isNull);
    });
  });

  testWidgets('la campana muestra los no leídos y abre la bandeja', (
    tester,
  ) async {
    final repo = FakeNotificationsRepository(
      items: [
        notice(1, title: 'Mentoría cancelada', route: '/mentoring/session/7'),
        notice(2, title: 'Nueva capacitación', kind: 'capacitacion_nueva'),
        notice(3, title: 'Leída', read: true),
      ],
    );
    await pumpApp(
      tester,
      TestWorld(
        auth: FakeAuthRepository(token: 'tok-1'),
        notifications: repo,
      ),
    );
    expect(
      find.descendant(of: find.byType(Badge), matching: find.text('2')),
      findsOneWidget,
    );

    await _tap(tester, find.byTooltip('Notificaciones'));
    expect(find.text('Mentoría cancelada'), findsOneWidget);
    expect(find.text('Nueva capacitación'), findsOneWidget);

    await _tap(tester, find.text('Marcar todo leído'));
    expect(repo.markAllCalls, 1);
    expect(find.text('Marcar todo leído'), findsNothing);
  });

  testWidgets('tocar un aviso lo marca leído y abre su pantalla', (
    tester,
  ) async {
    final repo = FakeNotificationsRepository(
      items: [notice(1, title: 'Revisa tus tareas', route: '/mentoring/tasks')],
    );
    await pumpApp(
      tester,
      TestWorld(
        auth: FakeAuthRepository(token: 'tok-1'),
        notifications: repo,
      ),
    );
    await _tap(tester, find.byTooltip('Notificaciones'));
    await _tap(tester, find.text('Revisa tus tareas'));
    expect(repo.items.single.read, isTrue);
    expect(find.text('Notificaciones'), findsNothing);
  });

  testWidgets('sin avisos lo explica', (tester) async {
    await pumpApp(tester, TestWorld(auth: FakeAuthRepository(token: 'tok-1')));
    await _tap(tester, find.byTooltip('Notificaciones'));
    expect(find.text('Sin notificaciones'), findsOneWidget);
  });

  testWidgets(
    'con sesión registra el token; el push abierto muestra el aviso',
    (tester) async {
      final repo = FakeNotificationsRepository();
      final push = FakePushMessaging();
      await pumpApp(
        tester,
        TestWorld(
          auth: FakeAuthRepository(token: 'tok-1'),
          notifications: repo,
          push: push,
        ),
      );
      expect(repo.registered, [('fcm-1', 'android')]);

      push.refresh.add('fcm-2');
      await settle(tester);
      expect(repo.registered.last, ('fcm-2', 'android'));

      push.foreground.add(
        const PushNotice(
          title: 'Tienes una mentoría pronto',
          body: 'Finanzas · 18/11 15:00',
          route: '/mentoring/session/3',
        ),
      );
      await settle(tester);
      expect(find.text('Tienes una mentoría pronto'), findsOneWidget);
      expect(find.widgetWithText(SnackBarAction, 'Ver'), findsOneWidget);
    },
  );

  testWidgets('cerrar sesión invalida el token del celular', (tester) async {
    final push = FakePushMessaging();
    await pumpApp(
      tester,
      TestWorld(
        auth: FakeAuthRepository(token: 'tok-1'),
        push: push,
      ),
    );
    await _tap(tester, find.text('Perfil'));
    await _tap(tester, find.text('Cerrar sesión'));
    expect(push.deleteCalls, 1);
  });

  testWidgets('sin Firebase no registra nada y la app funciona', (
    tester,
  ) async {
    final repo = FakeNotificationsRepository();
    await pumpApp(
      tester,
      TestWorld(
        auth: FakeAuthRepository(token: 'tok-1'),
        notifications: repo,
        push: FakePushMessaging(enabled: false),
      ),
    );
    expect(repo.registered, isEmpty);
    expect(find.byTooltip('Notificaciones'), findsOneWidget);
  });
}
