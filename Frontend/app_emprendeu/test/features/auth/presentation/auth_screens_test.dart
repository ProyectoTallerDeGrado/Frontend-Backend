import 'package:app_emprendeu/core/error/failure.dart';
import 'package:app_emprendeu/core/error/result.dart';
import 'package:app_emprendeu/features/auth/domain/entities/auth_session.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/test_app.dart';
import '../fake_auth_repository.dart';

Future<void> _pump(WidgetTester tester, FakeAuthRepository repo) =>
    pumpApp(tester, TestWorld(auth: repo));

Future<void> _enter(WidgetTester tester, String label, String text) async {
  final field = find.widgetWithText(TextFormField, label);
  await tester.ensureVisible(field);
  await tester.enterText(field, text);
}

Future<void> _tap(WidgetTester tester, String text) async {
  await tester.ensureVisible(find.text(text));
  await tester.pump(const Duration(milliseconds: 300));
  await tester.tap(find.text(text));
  await tester.pump();
  // La transición de página de material_ui dura más: hasta que termina, la ruta
  // anterior sigue en pantalla y sus campos coinciden con los de la nueva.
  await tester.pump(const Duration(seconds: 1));
}

void main() {
  testWidgets('sin sesión guardada se muestra el login', (tester) async {
    await _pump(tester, FakeAuthRepository());
    expect(find.text('Tu emprendimiento, acompañado.'), findsOneWidget);
  });

  testWidgets('con sesión guardada se abre directo la cuenta', (tester) async {
    await _pump(tester, FakeAuthRepository(token: 'tok-1'));
    expect(find.text('Hola, Camila'), findsOneWidget);
  });

  testWidgets('el login valida campos vacíos sin llamar al servidor', (
    tester,
  ) async {
    final repo = FakeAuthRepository();
    await _pump(tester, repo);
    await _tap(tester, 'Ingresar');
    expect(find.text('Ingresa tu correo electrónico.'), findsOneWidget);
    expect(find.text('Ingresa tu contraseña.'), findsOneWidget);
    expect(repo.loginCalls, 0);
  });

  testWidgets('login correcto entra a la cuenta', (tester) async {
    final repo = FakeAuthRepository();
    await _pump(tester, repo);
    await _enter(tester, 'tu@correo.com', 'camila@correo.com');
    await _enter(tester, '••••••••••', 'clave-larga-1');
    await _tap(tester, 'Ingresar');
    expect(repo.loginCalls, 1);
    expect(find.text('Hola, Camila'), findsOneWidget);
    expect(repo.token, 'tok-123');
  });

  testWidgets('credenciales incorrectas muestran el error', (tester) async {
    final repo = FakeAuthRepository(
      loginResult: const Result.err(InvalidCredentialsFailure()),
    );
    await _pump(tester, repo);
    await _enter(tester, 'tu@correo.com', 'camila@correo.com');
    await _enter(tester, '••••••••••', 'mala');
    await _tap(tester, 'Ingresar');
    expect(find.text('Correo o contraseña incorrectos.'), findsOneWidget);
    expect(find.text('Tu emprendimiento, acompañado.'), findsOneWidget);
    expect(repo.token, isNull);
  });

  testWidgets('cuenta del panel web se rechaza', (tester) async {
    final repo = FakeAuthRepository(
      loginResult: const Result.ok(
        AuthSession(accessToken: 'tok-staff', user: staffUser),
      ),
    );
    await _pump(tester, repo);
    await _enter(tester, 'tu@correo.com', 'jroca@uagrm.edu.bo');
    await _enter(tester, '••••••••••', 'clave-larga-1');
    await _tap(tester, 'Ingresar');
    expect(find.textContaining('panel web'), findsOneWidget);
    expect(repo.token, isNull);
  });

  testWidgets('del login se llega al registro y se valida', (tester) async {
    await _pump(tester, FakeAuthRepository());
    await _tap(tester, 'Regístrate');
    expect(find.text('Crea tu cuenta.'), findsOneWidget);
    await _tap(tester, 'Crear cuenta');
    expect(find.text('Este campo es obligatorio.'), findsOneWidget);
    expect(find.text('Crea una contraseña.'), findsOneWidget);
  });

  testWidgets('registro correcto entra con la cuenta nueva', (tester) async {
    final repo = FakeAuthRepository();
    await _pump(tester, repo);
    await _tap(tester, 'Regístrate');
    await _enter(tester, 'Nombre y apellidos', 'Camila Justiniano');
    await _enter(tester, 'tu@correo.com', 'camila@correo.com');
    await _enter(tester, 'Mínimo 8 caracteres', 'clave-larga-1');
    await _enter(tester, 'Repite tu contraseña', 'clave-larga-1');
    await _tap(tester, 'Crear cuenta');
    expect(repo.registerCalls, 1);
    expect(find.text('Hola, Camila'), findsOneWidget);
  });

  testWidgets('correo repetido se marca en el campo', (tester) async {
    final repo = FakeAuthRepository(
      registerResult: const Result.err(
        FieldFailure('email', 'Ya existe una cuenta con ese correo.'),
      ),
    );
    await _pump(tester, repo);
    await _tap(tester, 'Regístrate');
    await _enter(tester, 'Nombre y apellidos', 'Camila Justiniano');
    await _enter(tester, 'tu@correo.com', 'camila@correo.com');
    await _enter(tester, 'Mínimo 8 caracteres', 'clave-larga-1');
    await _enter(tester, 'Repite tu contraseña', 'clave-larga-1');
    await _tap(tester, 'Crear cuenta');
    expect(find.text('Ya existe una cuenta con ese correo.'), findsOneWidget);
    expect(find.text('Crea tu cuenta.'), findsOneWidget);
  });

  testWidgets('cerrar sesión vuelve al login y borra el token', (tester) async {
    final repo = FakeAuthRepository(token: 'tok-1');
    await _pump(tester, repo);
    await _tap(tester, 'Perfil');
    await _tap(tester, 'Cerrar sesión');
    expect(find.text('Tu emprendimiento, acompañado.'), findsOneWidget);
    expect(repo.token, isNull);
  });

  group('cambiar contraseña', () {
    Future<void> openForm(WidgetTester tester, FakeAuthRepository repo) async {
      await _pump(tester, repo);
      await _tap(tester, 'Perfil');
      await _tap(tester, 'Cambiar contraseña');
    }

    testWidgets('correcto: guarda el token nuevo y sigue con sesión', (
      tester,
    ) async {
      final repo = FakeAuthRepository(token: 'tok-viejo');
      await openForm(tester, repo);
      await _enter(tester, 'Contraseña actual', 'actual-1234');
      await _enter(tester, 'Contraseña nueva', 'nueva-clave-99');
      await _enter(tester, 'Repite la contraseña nueva', 'nueva-clave-99');
      await tester.tap(find.widgetWithText(FilledButton, 'Cambiar contraseña'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(
        const Duration(seconds: 1),
      ); // termina el pop y el aviso
      expect(repo.changePasswordCalls, 1);
      expect(repo.lastCurrentPassword, 'actual-1234');
      expect(repo.lastNewPassword, 'nueva-clave-99');
      expect(repo.token, 'tok-nuevo');
      // vuelve a la cuenta (sigue autenticada) y avisa
      expect(find.text('Cerrar sesión'), findsOneWidget);
      expect(find.textContaining('Contraseña actualizada'), findsOneWidget);
    });

    testWidgets(
      'clave actual equivocada: error en el campo y no cierra la sesión',
      (tester) async {
        final repo = FakeAuthRepository(
          token: 'tok-viejo',
          changePasswordResult: const Result.err(
            FieldFailure(
              'currentPassword',
              'La contraseña actual no es correcta.',
            ),
          ),
        );
        await openForm(tester, repo);
        await _enter(tester, 'Contraseña actual', 'mala-clave');
        await _enter(tester, 'Contraseña nueva', 'nueva-clave-99');
        await _enter(tester, 'Repite la contraseña nueva', 'nueva-clave-99');
        await tester.tap(
          find.widgetWithText(FilledButton, 'Cambiar contraseña'),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        expect(
          find.text('La contraseña actual no es correcta.'),
          findsOneWidget,
        );
        expect(repo.token, 'tok-viejo');
        expect(find.text('Tu emprendimiento, acompañado.'), findsNothing);
      },
    );

    testWidgets('valida sin llamar al servidor', (tester) async {
      final repo = FakeAuthRepository(token: 'tok-viejo');
      await openForm(tester, repo);
      await _enter(tester, 'Contraseña actual', 'actual-1234');
      await _enter(tester, 'Contraseña nueva', 'actual-1234');
      await _enter(tester, 'Repite la contraseña nueva', 'otra-distinta');
      await tester.tap(find.widgetWithText(FilledButton, 'Cambiar contraseña'));
      await tester.pump();
      expect(
        find.text('La contraseña nueva debe ser distinta de la actual.'),
        findsOneWidget,
      );
      expect(find.text('Las contraseñas no coinciden.'), findsOneWidget);
      expect(repo.changePasswordCalls, 0);
    });
  });

  testWidgets('CU01: recuperar la contraseña con el código del correo', (
    tester,
  ) async {
    final repo = FakeAuthRepository();
    await _pump(tester, repo);

    await _tap(tester, '¿Olvidaste tu contraseña?');
    expect(find.text('Recupera tu contraseña.'), findsOneWidget);

    // El correo es obligatorio y válido antes de llamar al servidor.
    await _tap(tester, 'Enviar código');
    expect(find.text('Ingresa tu correo electrónico.'), findsOneWidget);
    expect(repo.resetRequestCalls, 0);

    await _enter(tester, 'tu@correo.com', 'camila@correo.com');
    await _tap(tester, 'Enviar código');
    expect(repo.resetRequestCalls, 1);
    expect(find.text('Crea una contraseña nueva.'), findsOneWidget);

    // El correo viaja prellenado; falta el código y la clave nueva.
    await _enter(tester, '123456', '654321');
    await _enter(tester, 'Mínimo 8 caracteres', 'nueva-clave-99');
    await _enter(tester, 'Repite tu contraseña', 'nueva-clave-99');
    await _tap(tester, 'Restablecer');
    expect(repo.resetCalls, 1);
    expect(repo.lastResetEmail, 'camila@correo.com');
    expect(repo.lastResetCode, '654321');
    expect(find.text('Tu emprendimiento, acompañado.'), findsOneWidget);
  });

  testWidgets('CU01: un código vencido se explica en el campo', (tester) async {
    final repo = FakeAuthRepository()
      ..resetResult = const Result.err(
        FieldFailure(
          'code',
          'El código no es válido o ya venció. Pide uno nuevo.',
        ),
      );
    await _pump(tester, repo);
    await _tap(tester, '¿Olvidaste tu contraseña?');
    await _enter(tester, 'tu@correo.com', 'camila@correo.com');
    await _tap(tester, 'Enviar código');
    await _enter(tester, '123456', '000000');
    await _enter(tester, 'Mínimo 8 caracteres', 'nueva-clave-99');
    await _enter(tester, 'Repite tu contraseña', 'nueva-clave-99');
    await _tap(tester, 'Restablecer');
    expect(
      find.text('El código no es válido o ya venció. Pide uno nuevo.'),
      findsOneWidget,
    );
  });
}
