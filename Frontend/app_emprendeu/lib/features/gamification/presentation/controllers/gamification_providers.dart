import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/result.dart';
import '../../../ventures/index.dart';
import '../../domain/entities/gamification_profile.dart';
import '../../domain/entities/journey.dart';
import '../../domain/repositories/gamification_repository.dart';
import '../../domain/usecases/complete_challenge_usecase.dart';
import '../../domain/usecases/get_gamification_profile_usecase.dart';
import '../../domain/usecases/get_journey_usecase.dart';

/// Contrato del repositorio; la implementación se inyecta en `app/providers.dart`.
final gamificationRepositoryProvider = Provider<GamificationRepository>(
  (ref) => throw UnimplementedError(
    'gamificationRepositoryProvider sin implementación',
  ),
);

final getJourneyUseCaseProvider = Provider(
  (ref) => GetJourneyUseCase(ref.watch(gamificationRepositoryProvider)),
);

final completeChallengeUseCaseProvider = Provider(
  (ref) => CompleteChallengeUseCase(ref.watch(gamificationRepositoryProvider)),
);

final getGamificationProfileUseCaseProvider = Provider(
  (ref) =>
      GetGamificationProfileUseCase(ref.watch(gamificationRepositoryProvider)),
);

/// Camino de retos del emprendimiento activo (el elegido si tiene varios).
final journeyProvider = FutureProvider<Journey>((ref) async {
  final ventureId = await ref.watch(currentVentureIdProvider.future);
  return (await ref.watch(getJourneyUseCaseProvider)(ventureId: ventureId))
      .getOrThrow();
});

/// XP, nivel y avance hacia el siguiente nivel.
final gamificationProfileProvider = FutureProvider<GamificationProfile>(
  (ref) async =>
      (await ref.watch(getGamificationProfileUseCaseProvider)()).getOrThrow(),
);
