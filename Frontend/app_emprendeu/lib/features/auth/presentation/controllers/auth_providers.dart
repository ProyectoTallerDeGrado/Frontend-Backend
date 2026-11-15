import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/change_password_usecase.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';
import '../../domain/usecases/password_reset_usecases.dart';
import '../../domain/usecases/register_usecase.dart';
import '../../domain/usecases/restore_session_usecase.dart';

/// Contrato del repositorio. La implementación real se inyecta en la raíz de la
/// app (`app/providers.dart`), así `presentation` nunca importa `data`.
final authRepositoryProvider = Provider<AuthRepository>(
  (ref) =>
      throw UnimplementedError('authRepositoryProvider sin implementación'),
);

final loginUseCaseProvider = Provider(
  (ref) => LoginUseCase(ref.watch(authRepositoryProvider)),
);

final changePasswordUseCaseProvider = Provider(
  (ref) => ChangePasswordUseCase(ref.watch(authRepositoryProvider)),
);

final registerUseCaseProvider = Provider(
  (ref) => RegisterUseCase(
    ref.watch(authRepositoryProvider),
    ref.watch(loginUseCaseProvider),
  ),
);

final requestPasswordResetUseCaseProvider = Provider(
  (ref) => RequestPasswordResetUseCase(ref.watch(authRepositoryProvider)),
);

final resetPasswordUseCaseProvider = Provider(
  (ref) => ResetPasswordUseCase(ref.watch(authRepositoryProvider)),
);

final restoreSessionUseCaseProvider = Provider(
  (ref) => RestoreSessionUseCase(ref.watch(authRepositoryProvider)),
);

final logoutUseCaseProvider = Provider(
  (ref) => LogoutUseCase(ref.watch(authRepositoryProvider)),
);
