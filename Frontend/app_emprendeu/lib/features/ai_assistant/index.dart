// API pública de la feature `ai_assistant`.
export 'data/assistant_data_providers.dart' show assistantDataOverrides;
export 'presentation/assistant_routes.dart'
    show AssistantRoutes, assistantDetailRoutes, assistantRoutes;
export 'presentation/controllers/assistant_providers.dart'
    show assistantRepositoryProvider;
export 'presentation/controllers/local_ai_providers.dart'
    show localAiRepositoryProvider, localAiReadyProvider;
export 'presentation/controllers/local_coach_providers.dart'
    show localCoachRepositoryProvider, localKnowledgeRepositoryProvider;
export 'presentation/controllers/own_documents_providers.dart'
    show ownDocumentsRepositoryProvider, ownFilePickerProvider;
export 'presentation/widgets/local_ai_section.dart' show LocalAiSection;
