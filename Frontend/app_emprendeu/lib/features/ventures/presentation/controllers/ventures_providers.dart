import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/result.dart';
import '../../domain/entities/venture.dart';
import '../../domain/repositories/ventures_repository.dart';
import '../../domain/usecases/create_venture_usecase.dart';
import '../../domain/usecases/get_my_venture_usecase.dart';

/// Contrato del repositorio; la implementación se inyecta en `app/providers.dart`.
final venturesRepositoryProvider = Provider<VenturesRepository>(
  (ref) =>
      throw UnimplementedError('venturesRepositoryProvider sin implementación'),
);

final getMyVentureUseCaseProvider = Provider(
  (ref) => GetMyVentureUseCase(ref.watch(venturesRepositoryProvider)),
);

final createVentureUseCaseProvider = Provider(
  (ref) => CreateVentureUseCase(ref.watch(venturesRepositoryProvider)),
);

/// Emprendimiento del usuario (`null` = todavía no registró ninguno).
final myVentureProvider = FutureProvider<Venture?>(
  (ref) async => (await ref.watch(getMyVentureUseCaseProvider)()).getOrThrow(),
);
