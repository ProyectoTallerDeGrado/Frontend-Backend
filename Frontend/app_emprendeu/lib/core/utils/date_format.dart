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

/// «09:00» (hora local del dispositivo).
String timeOfDay(DateTime when) {
  final local = when.toLocal();
  return '${local.hour.toString().padLeft(2, '0')}:'
      '${local.minute.toString().padLeft(2, '0')}';
}

/// «Miércoles 5 de noviembre · 09:00».
String sessionWhen(DateTime when) =>
    '${longDate(when.toLocal())} · ${timeOfDay(when)}';

/// «5 nov» para chips de periodo.
String shortDay(DateTime day) =>
    '${day.day} ${_months[day.month - 1].substring(0, 3)}';

/// «Lun», «Mar»… para el selector de días.
String weekdayShort(DateTime day) => _weekdays[day.weekday - 1].substring(0, 3);
