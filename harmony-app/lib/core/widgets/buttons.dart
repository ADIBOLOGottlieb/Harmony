import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/design_tokens.dart';

/// Bouton principal : pilule dorée satinée, lueur, enfoncement et retour haptique.
class GoldPillButton extends StatefulWidget {
  const GoldPillButton({super.key, required this.label, required this.onPressed, this.icon, this.expand = true});

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool expand;

  @override
  State<GoldPillButton> createState() => _GoldPillButtonState();
}

class _GoldPillButtonState extends State<GoldPillButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    return Semantics(
      button: true,
      enabled: enabled,
      child: AnimatedScale(
        scale: _pressed ? .96 : 1,
        duration: HMotion.quick,
        curve: HMotion.emphasized,
        child: AnimatedOpacity(
          opacity: enabled ? 1 : .45,
          duration: HMotion.quick,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: HGradients.goldSheen,
              borderRadius: BorderRadius.circular(HRadius.pill),
              boxShadow: enabled ? HShadows.goldGlow : null,
            ),
            child: Material(
              type: MaterialType.transparency,
              child: InkWell(
                borderRadius: BorderRadius.circular(HRadius.pill),
                splashColor: HColors.ivory.withValues(alpha: .25),
                onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
                onTapCancel: () => setState(() => _pressed = false),
                onTapUp: (_) => setState(() => _pressed = false),
                onTap: enabled
                    ? () {
                        HapticFeedback.mediumImpact();
                        widget.onPressed!();
                      }
                    : null,
                child: SizedBox(
                  height: HSize.buttonHeight,
                  width: widget.expand ? double.infinity : null,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: HSpace.lg),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Text(
                            widget.label,
                            style: HText.label.copyWith(color: HColors.night, fontWeight: FontWeight.w700),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (widget.icon != null) ...[
                          const SizedBox(width: HSpace.xs),
                          Icon(widget.icon, color: HColors.night, size: HSize.icon),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Bouton rond en verre dépoli, pour les actions flottantes sur image.
class GlassIconButton extends StatelessWidget {
  const GlassIconButton({super.key, required this.icon, required this.onPressed, required this.tooltip});

  final IconData icon;
  final VoidCallback onPressed;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: ClipOval(
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Material(
            color: HColors.glass,
            shape: const CircleBorder(side: BorderSide(color: HColors.hairline)),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () {
                HapticFeedback.selectionClick();
                onPressed();
              },
              child: SizedBox.square(
                dimension: HSize.touch,
                child: Icon(icon, color: HColors.ivory, size: HSize.icon),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
