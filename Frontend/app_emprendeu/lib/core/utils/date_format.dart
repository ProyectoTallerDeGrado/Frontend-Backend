const _weekdays = [
  'Lunes',
  'Martes',
  'Miércoles',
  'Jueves',
  'Viernes',
  'Sábado',
  'Domingo',
];
const _months = [
  'enero',
  'febrero',
  'marzo',
  'abril',
  'mayo',
  'junio',
  'julio',
  'agosto',
  'septiembre',
  'octubre',
  'noviembre',
  'diciembre',
];

/// «Miércoles 21 de octubre».
String longDate(DateTime date) =>
    '${_weekdays[date.weekday - 1]} ${date.day} de ${_months[date.month - 1]}';

/// «Vence el jueves 22».
String dueLabel(DateTime? due) => due == null
    ? 'Sin fecha límite'
    : 'Vence el ${_weekdays[due.weekday - 1].toLowerCase()} ${due.day}';

/// «Ahora», «Hace 5 min», «Hace 3 h», «Ayer», «Hace 4 días», «Hace 2 semanas».
String relativeTime(DateTime when, {DateTime? now}) {
  final diff = (now ?? DateTime.now()).difference(when);
  if (diff.inMinutes < 1) return 'Ahora';
  if (diff.inMinutes < 60) return 'Hace ${diff.inMinutes} min';
  if (diff.inHours < 24) return 'Hace ${diff.inHours} h';
  if (diff.inDays == 1) return 'Ayer';
  if (diff.inDays < 14) return 'Hace ${diff.inDays} días';
  if (diff.inDays < 60) return 'Hace ${(diff.inDays / 7).floor()} semanas';
  return 'Hace ${(diff.inDays / 30).floor()} meses';
}
