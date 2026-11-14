import 'dart:math' as math;

import '../../domain/entities/knowledge_match.dart';
import 'local_knowledge_store.dart';

/// Los [limit] fragmentos de [index] más parecidos a [query] (similitud coseno,
/// por fuerza bruta: sobra para miles de fragmentos). [own] marca el origen.
List<KnowledgeMatch> searchIndex(
  StoredIndex index,
  List<double> query,
  int limit, {
  bool own = false,
}) {
  final qNorm = math.sqrt(query.fold<double>(0, (s, x) => s + x * x));
  if (qNorm == 0) return const [];
  final scored = <KnowledgeMatch>[];
  for (final doc in index.documents.values) {
    for (final f in doc.fragments) {
      if (f.norm == 0 || f.vector.length != query.length) continue;
      var dot = 0.0;
      for (var i = 0; i < query.length; i++) {
        dot += query[i] * f.vector[i];
      }
      scored.add(
        KnowledgeMatch(
          text: f.text,
          documentId: doc.id,
          title: doc.title,
          score: dot / (f.norm * qNorm),
          own: own,
        ),
      );
    }
  }
  scored.sort((a, b) => b.score.compareTo(a.score));
  return scored.take(limit).toList();
}
