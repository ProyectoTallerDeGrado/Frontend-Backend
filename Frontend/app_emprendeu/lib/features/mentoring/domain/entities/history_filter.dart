import 'history_event.dart';

/// Cómo se muestra el historial: orden, tipos de evento y periodo (CU19).
///
/// Tiene igualdad por valor: se usa como clave de un provider y, si no la tuviera,
/// cada reconstrucción pediría los datos otra vez.
class HistoryFilter {
  const HistoryFilter({
    this.newestFirst = true,
    this.kinds = const {},
    this.from,
    this.to,
  });

  final bool newestFirst;

  /// Vacío = todos los tipos.
  final Set<HistoryKind> kinds;
  final DateTime? from;
  final DateTime? to;

  bool get isFiltered => kinds.isNotEmpty || from != null || to != null;

  HistoryFilter copyWith({
    bool? newestFirst,
    Set<HistoryKind>? kinds,
    DateTime? from,
    DateTime? to,
    bool clearPeriod = false,
  }) => HistoryFilter(
    newestFirst: newestFirst ?? this.newestFirst,
    kinds: kinds ?? this.kinds,
    from: clearPeriod ? null : (from ?? this.from),
    to: clearPeriod ? null : (to ?? this.to),
  );

  @override
  bool operator ==(Object other) =>
      other is HistoryFilter &&
      other.newestFirst == newestFirst &&
      other.from == from &&
      other.to == to &&
      other.kinds.length == kinds.length &&
      other.kinds.containsAll(kinds);

  @override
  int get hashCode => Object.hash(
    newestFirst,
    from,
    to,
    Object.hashAllUnordered(kinds.map((k) => k.index)),
  );
}
