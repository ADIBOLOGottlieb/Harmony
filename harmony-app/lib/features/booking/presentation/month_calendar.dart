import 'package:flutter/material.dart';

import '../../../core/format/dates.dart';
import '../../../core/theme/design_tokens.dart';
import '../domain/booking_models.dart';

/// Calendrier d'un mois : jours libres, réservés, bloqués ou passés, et plage choisie.
class MonthCalendar extends StatelessWidget {
  const MonthCalendar({
    super.key,
    required this.month,
    required this.days,
    required this.onTap,
    this.start,
    this.end,
  });

  /// Premier jour du mois affiché.
  final DateTime month;
  final Map<DateTime, DayAvailability> days;
  final ValueChanged<DateTime> onTap;
  final DateTime? start;
  final DateTime? end;

  static const _weekdays = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];

  @override
  Widget build(BuildContext context) {
    final first = DateTime(month.year, month.month);
    final daysInMonth = DateUtils.getDaysInMonth(month.year, month.month);
    final leading = first.weekday - 1; // lundi en premier
    final cells = leading + daysInMonth;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: HSpace.sm),
          child: Text(
            monthTitle(first).replaceFirstMapped(RegExp(r'^\w'), (m) => m[0]!.toUpperCase()),
            style: context.tt.titleLarge,
          ),
        ),
        Row(
          children: [
            for (final w in _weekdays)
              Expanded(child: Center(child: Text(w, style: HText.labelSmall.copyWith(color: context.hc.textMuted)))),
          ],
        ),
        const SizedBox(height: HSpace.xxs),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: (cells / 7).ceil() * 7,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7, mainAxisExtent: HSize.touch + 4),
          itemBuilder: (context, i) {
            final dayNumber = i - leading + 1;
            if (dayNumber < 1 || dayNumber > daysInMonth) return const SizedBox.shrink();
            final date = DateTime(month.year, month.month, dayNumber);
            return _DayCell(
              date: date,
              availability: days[date],
              isStart: start != null && DateUtils.isSameDay(start, date),
              isEnd: end != null && DateUtils.isSameDay(end, date),
              inRange: start != null && end != null && date.isAfter(start!) && date.isBefore(end!),
              onTap: () => onTap(date),
            );
          },
        ),
      ],
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.date,
    required this.availability,
    required this.isStart,
    required this.isEnd,
    required this.inRange,
    required this.onTap,
  });

  final DateTime date;
  final DayAvailability? availability;
  final bool isStart;
  final bool isEnd;
  final bool inRange;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final status = availability?.status ?? DayStatus.blocked;
    final unavailable = status != DayStatus.free;
    final selected = isStart || isEnd;
    final label = switch (status) {
      DayStatus.free => 'libre',
      DayStatus.booked => 'réservé',
      DayStatus.blocked => 'indisponible',
      DayStatus.past => 'passé',
    };

    final textColor = selected
        ? context.cs.onPrimary
        : unavailable
            ? context.hc.textMuted.withValues(alpha: .55)
            : context.cs.onSurface;

    return Semantics(
      button: true,
      selected: selected,
      label: '${fullDate(DateTime.utc(date.year, date.month, date.day))}, $label',
      excludeSemantics: true,
      child: InkWell(
        onTap: status == DayStatus.past ? null : onTap,
        customBorder: const CircleBorder(),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 2),
          decoration: BoxDecoration(
            color: selected ? context.cs.primary : (inRange ? context.hc.accentSoft : null),
            borderRadius: BorderRadius.circular(HRadius.sm),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${date.day}',
                style: HText.labelSmall.copyWith(
                  fontSize: 15,
                  color: textColor,
                  decoration: status == DayStatus.booked || status == DayStatus.blocked ? TextDecoration.lineThrough : null,
                ),
              ),
              if (!unavailable && availability != null)
                Text(
                  '${(availability!.price / 1000).round()}k',
                  style: HText.labelSmall.copyWith(fontSize: 10, color: selected ? context.cs.onPrimary : context.hc.textMuted),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
