part of 'model.dart';

enum HoleKind { face, edge, shaft }

typedef HoleRef = (HoleKind, int);

/// Groups refer to physical borings, so a cam and its shaft can be listed separately.
class DrillGroups {
  DrillGroups(Map<HoleRef, int> values) : members = Map.unmodifiable(values);
  final Map<HoleRef, int> members;

  factory DrillGroups.pairs(List<PanelHole> faces) {
    final ids = <HoleRef, int>{};
    for (final (i, hole) in faces.indexed) {
      if (hole.boltBore != null) {
        ids[(HoleKind.face, i)] = ids[(HoleKind.shaft, i)] = i + 1;
      }
    }
    return DrillGroups(ids);
  }

  DrillGroups assign(
    Iterable<HoleRef> refs, {
    bool ungroup = false,
    int? join,
  }) {
    final next = {...members};
    final id = join ?? (members.values.fold(0, math.max) + 1);
    for (final ref in refs) {
      if (ungroup) {
        next.remove(ref);
      } else {
        next[ref] = id;
      }
    }
    return _withoutSingles(next);
  }

  DrillGroups remove(HoleRef removed) {
    final next = <HoleRef, int>{};
    for (final e in members.entries) {
      final (kind, index) = e.key;
      if (e.key == removed ||
          removed == (HoleKind.face, index) && kind == HoleKind.shaft) {
        continue;
      }
      final shifts =
          removed.$1 != HoleKind.shaft &&
          index > removed.$2 &&
          (kind == removed.$1 ||
              kind == HoleKind.shaft && removed.$1 == HoleKind.face);
      next[(kind, shifts ? index - 1 : index)] = e.value;
    }
    return _withoutSingles(next);
  }

  static DrillGroups _withoutSingles(Map<HoleRef, int> values) {
    final counts = <int, int>{};
    for (final id in values.values) {
      counts[id] = (counts[id] ?? 0) + 1;
    }
    values.removeWhere((_, id) => counts[id] == 1);
    return DrillGroups(values);
  }

  List<List<Object>> toJson() => [
    for (final e in members.entries) [e.key.$1.name, e.key.$2, e.value],
  ];
  factory DrillGroups.fromJson(List data) {
    final values = <HoleRef, int>{};
    for (final item in data) {
      if (item case [String name, int index, int id]
          when index >= 0 && id > 0) {
        final kind = HoleKind.values.where((k) => k.name == name).firstOrNull;
        if (kind != null) values[(kind, index)] = id;
      }
    }
    return _withoutSingles(values);
  }
}

List<HoleRef> layoutRefs(DrillLayout layout, int firstFace, int firstEdge) => [
  for (final (i, hole) in layout.faces.indexed) ...[
    (HoleKind.face, firstFace + i),
    if (hole.boltBore != null) (HoleKind.shaft, firstFace + i),
  ],
  for (int i = 0; i < layout.edges.length; i++) (HoleKind.edge, firstEdge + i),
];
