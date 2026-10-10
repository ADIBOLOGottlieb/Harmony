import 'package:flutter/material.dart';
import '../../core/i18n/i18n.dart';

const _monthsFr = ['janv.', 'févr.', 'mars', 'avr.', 'mai', 'juin', 'juil.', 'août', 'sept.', 'oct.', 'nov.', 'déc.'];
const _monthsEn = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
List<String> get _months => I18n.current == AppLanguage.en ? _monthsEn : _monthsFr;

/// « 12 oct. »
String shortDate(DateTime d) => _en ? '${_months[d.month - 1]} ${d.day}' : '${d.day} ${_months[d.month - 1]}';

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

/// « 3 nuits » : le mot est traduit, puis accordé (pluriel à partir de 2 en français, sauf 1 en anglais).
String plural(int n, String singular, [String? pluralForm]) {
  final one = t(singular);
  // Mot invariable en français (« avis ») : pluriel anglais régulier du mot traduit.
  final many = I18n.current == AppLanguage.en && pluralForm == singular ? '${one}s' : t(pluralForm ?? '${singular}s');
  final isPlural = I18n.current == AppLanguage.en ? n != 1 : n > 1;
  return '$n ${isPlural ? many : one}';
}

const _monthsLongFr = [
  'janvier', 'février', 'mars', 'avril', 'mai', 'juin', 'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre',
];
const _monthsLongEn = [
  'January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December',
];
const _weekdaysFr = ['lun.', 'mar.', 'mer.', 'jeu.', 'ven.', 'sam.', 'dim.'];
const _weekdaysEn = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
bool get _en => I18n.current == AppLanguage.en;
List<String> get _monthsLong => _en ? _monthsLongEn : _monthsLongFr;
List<String> get _weekdays => _en ? _weekdaysEn : _weekdaysFr;

/// « octobre 2026 »
String monthTitle(DateTime d) => '${_monthsLong[d.month - 1]} ${d.year}';

/// Les dates de l'API sont en UTC, qui est aussi l'heure de Lomé (UTC+0, sans heure d'été).
DateTime lome(DateTime d) => d.toUtc();

/// « mar. 20 oct. 2026 »
String fullDate(DateTime d) {
  final l = lome(d);
  if (_en) return '${_weekdays[l.weekday - 1]}, ${_months[l.month - 1]} ${l.day}, ${l.year}';
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
