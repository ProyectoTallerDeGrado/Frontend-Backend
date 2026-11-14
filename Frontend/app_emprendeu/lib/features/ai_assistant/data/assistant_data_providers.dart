import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:path_provider/path_provider.dart';

import '../../../core/config/app_config.dart';
import '../../../core/network/providers.dart';
import '../../../core/storage/providers.dart';
import '../presentation/controllers/assistant_providers.dart';
import '../presentation/controllers/local_ai_providers.dart';
import '../presentation/controllers/local_coach_providers.dart';
import '../presentation/controllers/own_documents_providers.dart';
import 'datasources/assistant_remote_data_source.dart';
import 'datasources/knowledge_remote_data_source.dart';
import 'datasources/local_ai_engine_data_source.dart';
import 'datasources/local_knowledge_store.dart';
import 'datasources/own_file_picker_data_source.dart';
import 'datasources/text_extractor.dart';
import 'repositories/assistant_repository_impl.dart';
import 'repositories/local_ai_repository_impl.dart';
import 'repositories/local_coach_repository_impl.dart';
import 'repositories/local_knowledge_repository_impl.dart';
import 'repositories/own_documents_repository_impl.dart';

/// Un solo motor por app: lo comparten la descarga, la búsqueda y el chat.
final _engineProvider = Provider(
  (ref) => LocalAiEngineDataSource(
    chatModelUrl: AppConfig.localAiChatModelUrl,
    chatModelBytes: AppConfig.localAiChatModelBytes,
    embedderUrl: AppConfig.localAiEmbedderUrl,
    embedderBytes: AppConfig.localAiEmbedderBytes,
  ),
);

final List<Override> assistantDataOverrides = [
  assistantRepositoryProvider.overrideWith(
    (ref) => AssistantRepositoryImpl(
      AssistantRemoteDataSource(ref.watch(dioProvider)),
    ),
  ),
  localAiRepositoryProvider.overrideWith(
    (ref) => LocalAiRepositoryImpl(ref.watch(_engineProvider)),
  ),
  localKnowledgeRepositoryProvider.overrideWith(
    (ref) => LocalKnowledgeRepositoryImpl(
      KnowledgeRemoteDataSource(ref.watch(dioProvider)),
      LocalKnowledgeStore(getApplicationSupportDirectory),
      ref.watch(_engineProvider),
    ),
  ),
  ownDocumentsRepositoryProvider.overrideWith(
    (ref) => OwnDocumentsRepositoryImpl(
      // En el directorio del usuario: se borra al cerrar sesión.
      LocalKnowledgeStore(
        ref.watch(userFilesDirectoryProvider),
        fileName: 'coach_own_documents.json',
      ),
      ref.watch(_engineProvider),
      const TextExtractor(),
    ),
  ),
  ownFilePickerProvider.overrideWithValue(const FilePickerOwnFilePicker()),
  localCoachRepositoryProvider.overrideWith(
    (ref) => LocalCoachRepositoryImpl(
      ref.watch(_engineProvider),
      ref.watch(keyValueStoreProvider),
    ),
  ),
];
