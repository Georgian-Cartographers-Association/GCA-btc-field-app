import 'dart:convert';

import '../../models/btk_record.dart';

/// How one record's version vector stands against another's. Each device counts
/// its own saves, so this doesn't depend on device clocks being right.
enum VersionOrder { same, older, newer, concurrent }

VersionOrder compareVersions(Map<String, int> a, Map<String, int> b) {
  var aAhead = false;
  var bAhead = false;
  for (final device in {...a.keys, ...b.keys}) {
    final inA = a[device] ?? 0;
    final inB = b[device] ?? 0;
    if (inA > inB) aAhead = true;
    if (inB > inA) bAhead = true;
  }
  if (aAhead && bAhead) return VersionOrder.concurrent;
  if (aAhead) return VersionOrder.newer;
  if (bAhead) return VersionOrder.older;
  return VersionOrder.same;
}

Map<String, int> mergeVersions(Map<String, int> a, Map<String, int> b) => {
      for (final device in {...a.keys, ...b.keys})
        device: (a[device] ?? 0) > (b[device] ?? 0) ? a[device]! : (b[device] ?? 0),
    };

String _content(BtkRecord r) => jsonEncode(r.toJson()
  ..remove('updatedAt')
  ..remove('versions'));

bool sameContent(BtkRecord a, BtkRecord b) => _content(a) == _content(b);

/// Whether neither copy was made from the other, so writing one loses the other.
///
/// A record last saved by an older app version has no versions. Those only have
/// their clocks to go by against each other, and against a versioned copy
/// nothing says which came first, so they count as a conflict.
bool inConflict(BtkRecord mine, BtkRecord theirs) {
  if (sameContent(mine, theirs)) return false;
  if (mine.versions.isEmpty && theirs.versions.isEmpty) {
    return theirs.updatedAt.isAfter(mine.updatedAt);
  }
  if (mine.versions.isEmpty || theirs.versions.isEmpty) return true;
  return compareVersions(mine.versions, theirs.versions) == VersionOrder.concurrent;
}

/// Whether saving [edited] would replace something it wasn't made from. Its
/// versions say which copy the edit started from, so unlike [inConflict] an older
/// one counts: a form left open while someone else's change arrived is one.
bool wouldOverwrite(BtkRecord edited, BtkRecord current) {
  if (sameContent(edited, current)) return false;
  if (edited.versions.isEmpty || current.versions.isEmpty) {
    return inConflict(edited, current);
  }
  final order = compareVersions(edited.versions, current.versions);
  return order == VersionOrder.older || order == VersionOrder.concurrent;
}
