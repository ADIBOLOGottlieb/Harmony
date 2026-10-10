import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../core/i18n/i18n.dart';

import '../config/app_config.dart';
import '../theme/design_tokens.dart';

/// Désactivable (tests, mode économie de données) : le cadre reste affiché sans tuiles réseau.
final mapTilesEnabledProvider = Provider<bool>((ref) => true);

/// Carte statique (sans gestes) centrée sur un bien.
/// `exact` = false : cercle de quartier, jamais de repère précis avant confirmation.
class LocationMap extends ConsumerWidget {
  const LocationMap({super.key, required this.latitude, required this.longitude, this.exact = false});

  final double latitude;
  final double longitude;
  final bool exact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final center = LatLng(latitude, longitude);
    final tiles = ref.watch(mapTilesEnabledProvider);
    return Semantics(
      label: exact ? t('Carte : emplacement du logement') : t('Carte : quartier du logement'),
      image: true,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(HRadius.md),
        child: SizedBox(
          height: HSize.mapHeight,
          child: ColoredBox(
            color: context.hc.surfaceAlt,
            child: FlutterMap(
              options: MapOptions(
                initialCenter: center,
                initialZoom: exact ? 16 : 14.5,
                interactionOptions: const InteractionOptions(flags: InteractiveFlag.none),
              ),
              children: [
                if (tiles)
                  TileLayer(
                    urlTemplate: AppConfig.mapTileUrl,
                    userAgentPackageName: 'com.harmony.harmony_app',
                  ),
                if (exact)
                  MarkerLayer(markers: [
                    Marker(
                      point: center,
                      width: HSize.touch,
                      height: HSize.touch,
                      alignment: Alignment.topCenter,
                      child: Icon(Icons.location_on_rounded, size: HSize.touch, color: context.cs.primary),
                    ),
                  ])
                else
                  CircleLayer(circles: [
                    CircleMarker(
                      point: center,
                      radius: HSize.mapZoneRadius,
                      useRadiusInMeter: true,
                      color: context.hc.accent.withValues(alpha: 0.22),
                      borderColor: context.hc.accent,
                      borderStrokeWidth: 1.5,
                    ),
                  ]),
                if (tiles) const _Attribution(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Attribution extends StatelessWidget {
  const _Attribution();

  @override
  Widget build(BuildContext context) => Align(
        alignment: Alignment.bottomRight,
        child: Container(
          margin: const EdgeInsets.all(HSpace.xxs),
          padding: const EdgeInsets.symmetric(horizontal: HSpace.xxs, vertical: 2),
          decoration: BoxDecoration(color: context.cs.surface.withValues(alpha: 0.85), borderRadius: BorderRadius.circular(HRadius.xs)),
          child: Text(AppConfig.mapAttribution, style: context.tt.labelSmall),
        ),
      );
}
