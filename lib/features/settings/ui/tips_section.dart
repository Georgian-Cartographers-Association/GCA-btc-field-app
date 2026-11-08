import 'package:flutter/material.dart';

import '../../../l10n/generated/app_localizations.dart';

/// Advice on getting more out of the device, folded away until wanted. A new
/// tip is one more entry in [_tips].
class TipsSection extends StatelessWidget {
  const TipsSection({super.key});

  static final List<
    (IconData, String Function(AppLocalizations), String Function(AppLocalizations))
  >
  _tips = [(Icons.mic_none, (l) => l.tipVoiceTitle, (l) => l.tipVoiceBody)];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ExpansionTile(
      leading: const Icon(Icons.lightbulb_outline),
      title: Text(l10n.tipsTitle),
      children: [
        for (final (icon, title, body) in _tips)
          ListTile(leading: Icon(icon), title: Text(title(l10n)), subtitle: Text(body(l10n))),
      ],
    );
  }
}
