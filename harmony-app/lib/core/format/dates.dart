import 'package:flutter/material.dart';

const _months = ['janv.', 'févr.', 'mars', 'avr.', 'mai', 'juin', 'juil.', 'août', 'sept.', 'oct.', 'nov.', 'déc.'];

/// « 12 oct. »
String shortDate(DateTime d) => '${d.day} ${_months[d.month - 1]}';

/// « 12 – 15 oct. » ou « 30 oct. – 2 nov. »
String dateRangeLabel(DateTimeRange r) {
  if (r.start.month == r.end.month && r.start.year == r.end.year) {
    return '${r.start.day} – ${shortDate(r.end)}';
  }
  return '${shortDate(r.start)} – ${shortDate(r.end)}';
}

/// Nombre de nuits entre l'arrivée et le départ (dates calendaires).
int nightsIn(DateTimeRange r) {
  final start = DateUtils.dateOnly(r.start);
  final end = DateUtils.dateOnly(r.end);
  return end.difference(start).inDays;
}

String plural(int n, String singular, [String? pluralForm]) => '$n ${n > 1 ? (pluralForm ?? '${singular}s') : singular}';

const _monthsLong = [
  'janvier', 'février', 'mars', 'avril', 'mai', 'juin', 'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre',
];
const _weekdays = ['lun.', 'mar.', 'mer.', 'jeu.', 'ven.', 'sam.', 'dim.'];

/// « octobre 2026 »
String monthTitle(DateTime d) => '${_monthsLong[d.month - 1]} ${d.year}';

/// Les dates de l'API sont en UTC, qui est aussi l'heure de Lomé (UTC+0, sans heure d'été).
DateTime lome(DateTime d) => d.toUtc();

/// « mar. 20 oct. 2026 »
String fullDate(DateTime d) {
  final l = lome(d);
  return '${_weekdays[l.weekday - 1]} ${l.day} ${_months[l.month - 1]} ${l.year}';
}

/// « 14:00 »
String timeOfDay(DateTime d) {
  final l = lome(d);
  return '${l.hour.toString().padLeft(2, '0')}:${l.minute.toString().padLeft(2, '0')}';
}

/// « 2026-10-20 » (format attendu par l'API).
String isoDay(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// Aujourd'hui à Lomé, sans heure.
DateTime todayInLome() {
  final now = DateTime.now().toUtc();
  return DateTime(now.year, now.month, now.day);
}
