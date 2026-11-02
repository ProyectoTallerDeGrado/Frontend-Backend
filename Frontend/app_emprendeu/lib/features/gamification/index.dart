// API pública de la feature `gamification`.
export 'data/gamification_data_providers.dart' show gamificationDataOverrides;
export 'domain/entities/gamification_profile.dart'
    show BadgeProgress, GamificationProfile, XpMovement;
export 'domain/entities/journey.dart'
    show ChallengeStatus, Journey, JourneyChallenge, JourneyStage, StageStatus;
export 'presentation/controllers/gamification_providers.dart'
    show
        gamificationProfileProvider,
        gamificationRepositoryProvider,
        journeyProvider;
export 'presentation/gamification_routes.dart'
    show GamificationRoutes, gamificationRoutes;
export 'presentation/widgets/xp_badges_section.dart' show XpBadgesSection;
