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
