import 'package:flutter_riverpod/misc.dart' show Override;

import '../features/ai_assistant/index.dart';
import '../features/auth/index.dart';
import '../features/documents/index.dart';
import '../features/gamification/index.dart';
import '../features/mentoring/index.dart';
import '../features/needs/index.dart';
import '../features/ventures/index.dart';

/// Raíz de composición: reúne las implementaciones de `data` de cada feature.
final List<Override> appOverrides = [
  ...authDataOverrides,
  ...venturesDataOverrides,
  ...documentsDataOverrides,
  ...gamificationDataOverrides,
  ...mentoringDataOverrides,
  ...needsDataOverrides,
  ...assistantDataOverrides,
];
