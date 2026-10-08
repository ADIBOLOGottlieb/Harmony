import 'package:flutter/widgets.dart';

/// Vrai si l'utilisateur a demandé de réduire les animations (réglage système).
/// Chaque mise en scène spectaculaire doit alors céder la place à un fondu simple.
bool reduceMotion(BuildContext context) =>
    MediaQuery.maybeDisableAnimationsOf(context) ?? false;
