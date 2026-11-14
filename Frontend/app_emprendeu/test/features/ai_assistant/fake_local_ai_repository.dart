import 'dart:async';

import 'package:app_emprendeu/core/error/failure.dart';
import 'package:app_emprendeu/core/error/result.dart';
import 'package:app_emprendeu/features/ai_assistant/domain/entities/local_ai_progress.dart';
import 'package:app_emprendeu/features/ai_assistant/domain/entities/local_ai_status.dart';
import 'package:app_emprendeu/features/ai_assistant/domain/repositories/local_ai_repository.dart';

/// IA local en memoria. La descarga queda abierta hasta [finish] o [fail].
class FakeLocalAiRepository implements LocalAiRepository {
  FakeLocalAiRepository({this.current = LocalAiStatus.notInstalled});

  LocalAiStatus current;
  int installCalls = 0;
  int removeCalls = 0;
  void Function(LocalAiProgress)? _onProgress;
  Completer<Result<void>>? _pending;

  @override
  int get downloadBytes => 2752774144;

  @override
  Future<Result<LocalAiStatus>> status() async => Ok(current);

  @override
  Future<Result<void>> install({
    required void Function(LocalAiProgress progress) onProgress,
  }) {
    installCalls++;
    _onProgress = onProgress;
    return (_pending = Completer()).future;
  }

  void report(int percent, [LocalAiStep step = LocalAiStep.chatModel]) =>
      _onProgress?.call(LocalAiProgress(step: step, percent: percent));

  void finish() {
    current = LocalAiStatus.installed;
    _pending?.complete(const Ok(null));
  }

  void fail(Failure failure) => _pending?.complete(Err(failure));

  @override
  void cancelInstall() =>
      _pending?.complete(const Err(LocalAiCancelledFailure()));

  @override
  Future<Result<void>> remove() async {
    removeCalls++;
    current = LocalAiStatus.notInstalled;
    return const Ok(null);
  }
}
