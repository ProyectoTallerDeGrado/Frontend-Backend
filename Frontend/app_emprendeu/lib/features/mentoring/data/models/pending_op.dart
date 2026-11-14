/// Cambio hecho sin conexión, guardado en el dispositivo hasta poder enviarlo.
sealed class PendingOp {
  const PendingOp(this.at);

  /// Momento real en que el usuario hizo el cambio.
  final DateTime at;

  Map<String, dynamic> toJson();

  static PendingOp? fromJson(Map<String, dynamic> json) {
    final at = DateTime.tryParse(json['at'] as String? ?? '');
    if (at == null) return null;
    switch (json['type']) {
      case 'commitment':
        final id = json['id'];
        final done = json['done'];
        if (id is! int || done is! bool) return null;
        return PendingCommitmentOp(id, done, at);
      case 'progress':
        final ref = json['ref'];
        final text = json['text'];
        if (ref is! String || text is! String) return null;
        // Las colas guardadas antes de CU05 (varios emprendimientos) no lo traen.
        final venture = json['venture'];
        return PendingProgressOp(
          ref,
          text,
          at,
          ventureId: venture is int ? venture : null,
        );
    }
    return null;
  }
}

class PendingCommitmentOp extends PendingOp {
  const PendingCommitmentOp(this.commitmentId, this.done, super.at);

  final int commitmentId;
  final bool done;

  @override
  Map<String, dynamic> toJson() => {
    'type': 'commitment',
    'id': commitmentId,
    'done': done,
    'at': at.toUtc().toIso8601String(),
  };
}

class PendingProgressOp extends PendingOp {
  const PendingProgressOp(
    this.clientRef,
    this.text,
    super.at, {
    this.ventureId,
  });

  final String clientRef;
  final String text;

  /// Emprendimiento del avance; `null` = el primero del usuario.
  final int? ventureId;

  @override
  Map<String, dynamic> toJson() => {
    'type': 'progress',
    'ref': clientRef,
    'text': text,
    'venture': ?ventureId,
    'at': at.toUtc().toIso8601String(),
  };
}
