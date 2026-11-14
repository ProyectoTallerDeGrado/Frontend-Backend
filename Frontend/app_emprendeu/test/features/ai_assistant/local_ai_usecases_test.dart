import 'package:app_emprendeu/core/error/failure.dart';
import 'package:app_emprendeu/core/error/result.dart';
import 'package:app_emprendeu/features/ai_assistant/domain/entities/local_ai_status.dart';
import 'package:app_emprendeu/features/ai_assistant/domain/usecases/local_ai_usecases.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_local_ai_repository.dart';

void main() {
  test('si ya está instalada no vuelve a descargar', () async {
    final ai = FakeLocalAiRepository(current: LocalAiStatus.installed);
    final result = await InstallLocalAiUseCase(ai)(onProgress: (_) {});
    expect(result, isA<Ok<void>>());
    expect(ai.installCalls, 0);
  });

  test('en un dispositivo no compatible falla sin descargar', () async {
    final ai = FakeLocalAiRepository(current: LocalAiStatus.unsupported);
    final result = await InstallLocalAiUseCase(ai)(onProgress: (_) {});
    expect(result.failureOrNull, isA<LocalAiFailure>());
    expect(ai.installCalls, 0);
  });

  test('sin instalar, descarga', () async {
    final ai = FakeLocalAiRepository();
    final pending = InstallLocalAiUseCase(ai)(onProgress: (_) {});
    await Future<void>.delayed(Duration.zero);
    ai.finish();
    expect(await pending, isA<Ok<void>>());
    expect(ai.installCalls, 1);
  });
}
