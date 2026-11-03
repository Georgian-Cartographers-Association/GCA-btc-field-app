import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../../l10n/generated/app_localizations.dart';

Future<bool> _ask(
    BuildContext context, String title, String message, String action) async {
  final l10n = AppLocalizations.of(context)!;
  final ok = await showDialog<bool>(
    context: context,
    builder: (dCtx) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(dCtx, false), child: Text(l10n.cancel)),
        FilledButton(
            onPressed: () => Navigator.pop(dCtx, true), child: Text(action)),
      ],
    ),
  );
  return ok == true;
}

/// Checks that GPS is on and location is allowed, and guides the user to the
/// right settings screen when it isn't. Returns true when location can be used.
Future<bool> ensureLocationAccess(BuildContext context) async {
  final l10n = AppLocalizations.of(context)!;
  if (!await Geolocator.isLocationServiceEnabled()) {
    if (!context.mounted) return false;
    if (await _ask(context, l10n.gpsOff, l10n.gpsOffMessage, l10n.enableGps)) {
      await Geolocator.openLocationSettings();
    }
    return false;
  }
  var perm = await Geolocator.checkPermission();
  if (perm == LocationPermission.denied) {
    perm = await Geolocator.requestPermission();
  }
  if (perm == LocationPermission.deniedForever) {
    if (!context.mounted) return false;
    if (await _ask(context, l10n.locationBlocked, l10n.locationBlockedMessage, l10n.settings)) {
      await Geolocator.openAppSettings();
    }
    return false;
  }
  return perm != LocationPermission.denied;
}
