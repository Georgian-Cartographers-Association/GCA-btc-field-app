import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';

/// Where one shared space's records stand against the server.
class SyncStatus {
  /// Records with saves the server hasn't confirmed.
  final Set<String> pendingIds;

  /// Unconfirmed writes of any kind. A delete has no record left to list.
  final bool hasPending;

  /// The latest list came from this device, usually for lack of a connection.
  final bool offline;
  final DateTime? lastSynced;

  const SyncStatus({
    this.pendingIds = const {},
    this.hasPending = false,
    this.offline = false,
    this.lastSynced,
  });

  bool get isSynced => !offline && !hasPending;
}

/// Passes each shared space's status from its live stream to the screen, and
/// remembers when it last had nothing left to send.
class SyncStatusFeed {
  static final instance = SyncStatusFeed();

  final _latest = <String, SyncStatus>{};
  final _changes = StreamController<String>.broadcast();
  Future<void> _queue = Future.value();

  SyncStatus? latest(String scope) => _latest[scope];

  /// Fires with the scope whose status changed.
  Stream<String> get changes => _changes.stream;

  static String _key(String scope) => 'sync_last_$scope';

  Future<void> report(
    String scope, {
    required Set<String> pendingIds,
    required bool hasPending,
    required bool fromCache,
    DateTime Function() now = DateTime.now,
  }) {
    final result = _queue.then((_) async {
      final prefs = await SharedPreferences.getInstance();
      final synced = !fromCache && !hasPending;
      if (synced && _latest[scope]?.isSynced != true) {
        await prefs.setString(_key(scope), now().toIso8601String());
      }
      _latest[scope] = SyncStatus(
        pendingIds: pendingIds,
        hasPending: hasPending,
        offline: fromCache,
        lastSynced: DateTime.tryParse(prefs.getString(_key(scope)) ?? ''),
      );
      _changes.add(scope);
    });
    _queue = result.catchError((Object _) {});
    return result;
  }
}
