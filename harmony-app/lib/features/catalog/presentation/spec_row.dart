import 'package:flutter/material.dart';
import '../../../core/format/dates.dart';
import '../../../core/i18n/i18n.dart';

import '../../../core/theme/design_tokens.dart';
import '../domain/apartment.dart';

/// Pictogramme fin associé à chaque équipement.
extension AmenityIcon on Amenity {
  IconData get icon => switch (this) {
        Amenity.wifi => Icons.wifi_rounded,
        Amenity.airConditioning => Icons.ac_unit_rounded,
        Amenity.parking => Icons.local_parking_rounded,
        Amenity.hotWater => Icons.water_drop_outlined,
        Amenity.generator => Icons.bolt_outlined,
        Amenity.pool => Icons.pool_outlined,
        Amenity.kitchen => Icons.kitchen_outlined,
        Amenity.tv => Icons.tv_outlined,
        Amenity.security => Icons.shield_outlined,
        Amenity.washer => Icons.local_laundry_service_outlined,
      };
}

/// « 3 ch. · 2 sdb · 160 m² » avec icônes fines.
class SpecRow extends StatelessWidget {
  const SpecRow({super.key, required this.apartment, this.color});

  final Apartment apartment;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? context.hc.textMuted;
    Widget item(IconData icon, String label, String semantic) => Semantics(
          label: semantic,
          excludeSemantics: true,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: HSize.iconSm, color: c),
              const SizedBox(width: HSpace.xxs + 2),
              Text(label, style: HText.bodySmall.copyWith(color: c)),
            ],
          ),
        );
    return Wrap(
      spacing: HSpace.md,
      runSpacing: HSpace.xxs,
      children: [
        item(Icons.bed_outlined, t('{n} ch.', {'n': apartment.bedrooms}), plural(apartment.bedrooms, 'chambre')),
        item(Icons.bathtub_outlined, t('{n} sdb', {'n': apartment.bathrooms}), plural(apartment.bathrooms, 'salle de bain', 'salles de bain')),
        item(Icons.square_foot_rounded, '${apartment.surfaceM2} m²', t('{n} mètres carrés', {'n': apartment.surfaceM2})),
        item(Icons.people_outline_rounded, '${apartment.capacity}', t('{n} voyageurs maximum', {'n': apartment.capacity})),
      ],
    );
  }
}
