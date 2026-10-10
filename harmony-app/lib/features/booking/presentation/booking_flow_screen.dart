import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/format/dates.dart';
import '../../../core/format/fcfa.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/harmony_image.dart';
import '../../catalog/data/catalog_repository.dart';
import '../../catalog/domain/apartment.dart';
import '../application/booking_draft.dart';
import '../data/booking_api.dart';
import '../domain/booking_models.dart';
import 'month_calendar.dart';

/// Étape 1 de la réservation : type de séjour, dates (calendrier réel du bien), voyageurs.
class BookingFlowScreen extends ConsumerStatefulWidget {
  const BookingFlowScreen({super.key, required this.apartmentId});

  final String apartmentId;

  @override
  ConsumerState<BookingFlowScreen> createState() => _BookingFlowScreenState();
}

class _BookingFlowScreenState extends ConsumerState<BookingFlowScreen> {
  static const _hours = ['08:00', '10:00', '12:00', '14:00', '16:00', '18:00', '20:00'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final apartment = ref.read(apartmentByIdProvider(widget.apartmentId));
      final draft = ref.read(bookingDraftProvider);
      if (apartment != null && draft?.apartmentId != apartment.id) {
        ref.read(bookingDraftProvider.notifier).start(apartment);
      }
    });
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _onDayTap(BookingDraft draft, DateTime date, Map<DateTime, DayAvailability> days) {
    HapticFeedback.selectionClick();
    final status = days[date]?.status ?? DayStatus.blocked;
    final notifier = ref.read(bookingDraftProvider.notifier);

    if (draft.stayType != StayType.night) {
      if (status == DayStatus.blocked) return _snack('Ce jour n’est pas disponible.');
      notifier.update((d) => d.copyWith(checkIn: () => date, checkOut: () => null));
      return;
    }

    final checkIn = draft.checkIn;
    // Choix de l'arrivée (ou nouvelle sélection).
    if (checkIn == null || draft.checkOut != null || !date.isAfter(checkIn)) {
      if (status != DayStatus.free) return _snack('Pas d’arrivée possible ce jour-là : la nuit est déjà prise.');
      notifier.update((d) => d.copyWith(checkIn: () => date, checkOut: () => null));
      return;
    }
    // Choix du départ : toutes les nuits entre l'arrivée et la veille du départ doivent être libres.
    for (var night = checkIn; night.isBefore(date); night = night.add(const Duration(days: 1))) {
      if (days[night]?.status != DayStatus.free) {
        notifier.update((d) => d.copyWith(checkIn: () => null, checkOut: () => null));
        return _snack('Certaines nuits de cette période sont déjà réservées.');
      }
    }
    notifier.update((d) => d.copyWith(checkOut: () => date));
  }

  @override
  Widget build(BuildContext context) {
    final apartment = ref.watch(apartmentByIdProvider(widget.apartmentId));
    final draft = ref.watch(bookingDraftProvider);
    if (apartment == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const EmptyState(icon: Icons.home_work_outlined, title: 'Bien introuvable', message: 'Ce logement n’est plus proposé.'),
      );
    }
    if (draft == null || draft.apartmentId != apartment.id) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final availability = ref.watch(availabilityProvider(apartment.id));
    final stayTypes = [
      StayType.night,
      if (apartment.shortStays?.day != null) StayType.day,
      if (apartment.shortStays?.threeHours != null) StayType.threeHours,
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Vos dates')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(HSpace.gutter, 0, HSpace.gutter, HSpace.xl),
        children: [
          _ApartmentHeader(apartment: apartment),
          const SizedBox(height: HSpace.lg),
          if (stayTypes.length > 1) ...[
            Text('Type de séjour', style: context.tt.titleMedium),
            const SizedBox(height: HSpace.xs),
            SegmentedButton<StayType>(
              showSelectedIcon: false,
              segments: [for (final t in stayTypes) ButtonSegment(value: t, label: Text(t.label))],
              selected: {draft.stayType},
              onSelectionChanged: (s) => ref.read(bookingDraftProvider.notifier).update(
                    (d) => d.copyWith(stayType: s.first, checkIn: () => null, checkOut: () => null, startTime: () => null),
                  ),
            ),
            const SizedBox(height: HSpace.lg),
          ],
          _SelectionSummary(draft: draft),
          const SizedBox(height: HSpace.md),
          availability.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(HSpace.xl),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => Card(
              child: Padding(
                padding: const EdgeInsets.all(HSpace.md),
                child: Column(
                  children: [
                    Text(ApiError.from(e).message, style: context.tt.bodyMedium, textAlign: TextAlign.center),
                    const SizedBox(height: HSpace.sm),
                    OutlinedButton(
                      onPressed: () => ref.invalidate(availabilityProvider(apartment.id)),
                      child: const Text('Réessayer'),
                    ),
                  ],
                ),
              ),
            ),
            data: (list) {
              final days = {for (final d in list) d.date: d};
              final first = todayInLome();
              return Column(
                children: [
                  for (var m = 0; m < 3; m++) ...[
                    MonthCalendar(
                      month: DateTime(first.year, first.month + m),
                      days: days,
                      start: draft.checkIn,
                      end: draft.stayType == StayType.night ? draft.checkOut : null,
                      onTap: (date) => _onDayTap(draft, date, days),
                    ),
                    const SizedBox(height: HSpace.lg),
                  ],
                ],
              );
            },
          ),
          if (draft.stayType == StayType.threeHours && draft.checkIn != null) ...[
            Text('Heure d’arrivée', style: context.tt.titleMedium),
            const SizedBox(height: HSpace.xs),
            Wrap(
              spacing: HSpace.xs,
              runSpacing: HSpace.xs,
              children: [
                for (final h in _hours)
                  ChoiceChip(
                    label: Text(h),
                    selected: draft.startTime == h,
                    onSelected: (_) => ref.read(bookingDraftProvider.notifier).update((d) => d.copyWith(startTime: () => h)),
                  ),
              ],
            ),
            const SizedBox(height: HSpace.lg),
          ],
          _GuestsRow(
            guests: draft.guests,
            capacity: apartment.capacity,
            onChanged: (g) => ref.read(bookingDraftProvider.notifier).update((d) => d.copyWith(guests: g)),
          ),
        ],
      ),
      bottomNavigationBar: _BottomBar(
        enabled: draft.isComplete,
        onContinue: () => context.push('/bien/${apartment.id}/recapitulatif'),
      ),
    );
  }
}

class _ApartmentHeader extends StatelessWidget {
  const _ApartmentHeader({required this.apartment});

  final Apartment apartment;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(HRadius.sm),
          child: SizedBox(width: 72, height: 56, child: HarmonyImage(apartment.cover)),
        ),
        const SizedBox(width: HSpace.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(apartment.title, style: context.tt.titleMedium),
              Text('${fcfa(apartment.pricePerNight)} / nuit', style: context.tt.bodyMedium),
            ],
          ),
        ),
      ],
    );
  }
}

class _SelectionSummary extends StatelessWidget {
  const _SelectionSummary({required this.draft});

  final BookingDraft draft;

  @override
  Widget build(BuildContext context) {
    String text;
    final checkIn = draft.checkIn;
    if (checkIn == null) {
      text = draft.stayType == StayType.night ? 'Touchez votre date d’arrivée.' : 'Touchez le jour souhaité.';
    } else if (draft.stayType == StayType.night) {
      text = draft.checkOut == null
          ? 'Arrivée le ${shortDate(checkIn)} à partir de 14 h. Touchez maintenant la date de départ.'
          : '${plural(draft.checkOut!.difference(checkIn).inDays, 'nuit')} · arrivée le ${shortDate(checkIn)} (14 h), départ le ${shortDate(draft.checkOut!)} (11 h)';
    } else if (draft.stayType == StayType.day) {
      text = 'Journée du ${shortDate(checkIn)}, de 10 h à 18 h.';
    } else {
      text = draft.startTime == null ? 'Choisissez l’heure d’arrivée ci-dessous.' : 'Le ${shortDate(checkIn)} à ${draft.startTime}, pendant 3 heures.';
    }
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(HSpace.md),
        decoration: BoxDecoration(color: context.hc.surfaceAlt, borderRadius: BorderRadius.circular(HRadius.md)),
        child: Row(
          children: [
            Icon(Icons.event_available_outlined, color: context.hc.accentText),
            const SizedBox(width: HSpace.sm),
            Expanded(child: Text(text, style: HText.bodySmall.copyWith(color: context.cs.onSurface))),
          ],
        ),
      ),
    );
  }
}

class _GuestsRow extends StatelessWidget {
  const _GuestsRow({required this.guests, required this.capacity, required this.onChanged});

  final int guests;
  final int capacity;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Voyageurs', style: context.tt.titleMedium),
              Text('Jusqu’à $capacity personnes', style: context.tt.bodyMedium),
            ],
          ),
        ),
        IconButton.outlined(
          tooltip: 'Retirer un voyageur',
          onPressed: guests > 1 ? () => onChanged(guests - 1) : null,
          icon: const Icon(Icons.remove_rounded),
        ),
        SizedBox(width: HSize.touch, child: Text('$guests', textAlign: TextAlign.center, style: context.tt.titleLarge)),
        IconButton.outlined(
          tooltip: 'Ajouter un voyageur',
          onPressed: guests < capacity ? () => onChanged(guests + 1) : null,
          icon: const Icon(Icons.add_rounded),
        ),
      ],
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({required this.enabled, required this.onContinue});

  final bool enabled;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.cs.surfaceContainerLowest,
        border: Border(top: BorderSide(color: context.hc.hairline)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(HSpace.gutter, HSpace.sm, HSpace.gutter, HSpace.sm),
          child: FilledButton(
            onPressed: enabled ? onContinue : null,
            child: const Text('Voir le récapitulatif'),
          ),
        ),
      ),
    );
  }
}
