import '../l10n/strings.dart';
import 'part_finish.dart';

import 'dart:convert';
import 'dart:math' as math;

import 'package:vector_math/vector_math_64.dart' show Vector3;
export 'package:vector_math/vector_math_64.dart' show Vector3;
part 'clearance.dart';
part 'rabbet.dart';

Vector3 axis(int i) => Vector3.zero()..[i] = 1;
String mm(double value) {
  final rounded = (value * 100).round() / 100;
  return rounded == rounded.truncateToDouble()
      ? rounded.toInt().toString()
      : rounded.toString();
}

enum LengthUnit {
  millimeter(1, 3),
  centimeter(10, 4),
  inch(25.4, 5);

  final double factor;
  final int precision;
  const LengthUnit(this.factor, this.precision);
  String format(double internal) {
    final n = internal / factor;
    final v = n.toStringAsFixed(precision).replaceFirst(RegExp(r'\.?0+$'), '');
    return v == '-0' || v.isEmpty ? '0' : v;
  }

  String get symbol => switch (this) {
    LengthUnit.millimeter => editorStrings.mm,
    LengthUnit.centimeter => editorStrings.cm,
    LengthUnit.inch => '″',
  };

  String get title => switch (this) {
    LengthUnit.millimeter => editorStrings.millimeters,
    LengthUnit.centimeter => editorStrings.centimeters,
    LengthUnit.inch => editorStrings.inches,
  };
}

Vector3 turn(Vector3 p, Vector3 normal, double radians) =>
    p * math.cos(radians) +
    normal.cross(p) * math.sin(radians) +
    normal * (normal.dot(p) * (1 - math.cos(radians)));

List<double> _xyz(Vector3 v) => [v.x, v.y, v.z];
Vector3 _readVector(dynamic data) {
  if (data is! List ||
      data.length != 3 ||
      !data.every((v) => v is num && v.isFinite && v.abs() <= 1e9)) {
    throw FormatException(editorStrings.invalidVector);
  }
  return Vector3(
    (data[0] as num).toDouble(),
    (data[1] as num).toDouble(),
    (data[2] as num).toDouble(),
  );
}

// Counterclockwise winding when viewed from outside. Bits 0, 1, 2 select local X, Y, Z.
const faceCorners = [
  [0, 4, 6, 2],
  [1, 3, 7, 5],
  [0, 1, 5, 4],
  [2, 6, 7, 3],
  [0, 2, 3, 1],
  [4, 5, 7, 6],
];

typedef FaceBore = ({double u, double v, double diameter});

FaceBore? _readBore(Object? data) {
  if (data == null) return null;
  if (data case [num u, num v, num diameter]
      when u > 0 &&
          u < 1 &&
          v > 0 &&
          v < 1 &&
          diameter.isFinite &&
          diameter > 0 &&
          diameter <= 1e9) {
    return (u: u.toDouble(), v: v.toDouble(), diameter: diameter.toDouble());
  }
  throw FormatException(editorStrings.invalidPartGeometry);
}

class Beam {
  static const maxCutOffset = 1e8;
  static String defaultName(int id) => editorStrings.numberedPart(id);

  final int id;
  final String name;
  final Vector3 origin, size, along, across;
  final int? group;
  final int locks;
  final bool hidden;
  final PartFinish finish;
  final FaceBore? bore;
  final Map<RabbetEdge, Rabbet> rabbets;
  // Longitudinal offset across the full width and thickness of each end.
  final ({double y, double z}) startCut, endCut;
  bool get bevelled =>
      startCut.y != 0 || startCut.z != 0 || endCut.y != 0 || endCut.z != 0;
  double get minimumLength =>
      ((endCut.y - startCut.y).abs() + (endCut.z - startCut.z).abs()) * .5 +
      .001;
  double offsetAt(({double y, double z}) cut, double y, double z) =>
      cut.y * (y - .5) + cut.z * (z - .5);
  Vector3 pointAt(Vector3 t) {
    final left = offsetAt(startCut, t.y, t.z),
        right = size.x + offsetAt(endCut, t.y, t.z);
    return origin +
        along * (left + (right - left) * t.x) +
        across * (size.y * t.y) +
        up * (size.z * t.z);
  }

  Vector3 localAt(Vector3 world) {
    final d = world - origin,
        y = d.dot(across) / size.y,
        z = d.dot(up) / size.z;
    final left = offsetAt(startCut, y, z),
        right = size.x + offsetAt(endCut, y, z);
    return Vector3((d.dot(along) - left) / (right - left), y, z);
  }

  Vector3 faceNormal(int face) {
    if (face >= 2) {
      return [across, up][face ~/ 2 - 1] * (face.isOdd ? 1.0 : -1.0);
    }
    final cut = face == 0 ? startCut : endCut;
    return (along - across * (cut.y / size.y) - up * (cut.z / size.z))
            .normalized() *
        (face.isOdd ? 1.0 : -1.0);
  }

  bool locked(int i) => (locks & (1 << i)) != 0;
  Beam withSizeLock(int i, bool locked) =>
      copy(locks: locked ? locks | (1 << i) : locks & ~(1 << i));
  Beam(
    this.id,
    this.name,
    this.origin,
    this.size,
    this.along,
    this.across, {
    this.group,
    this.locks = 0,
    this.hidden = false,
    this.finish = woodFinish,
    this.bore,
    Map<RabbetEdge, Rabbet> rabbets = const {},
    this.startCut = (y: 0, z: 0),
    this.endCut = (y: 0, z: 0),
  }) : rabbets = rabbets.isEmpty ? const {} : Map.unmodifiable(rabbets);

  Vector3 get up => along.cross(across);
  Vector3 corner(int i) => pointAt(
    Vector3(
      (i & 1).toDouble(),
      ((i >> 1) & 1).toDouble(),
      ((i >> 2) & 1).toDouble(),
    ),
  );
  List<Vector3> get corners => List.generate(8, corner);
  Beam copy({
    String? name,
    Vector3? origin,
    Vector3? size,
    Vector3? along,
    Vector3? across,
    int? group,
    bool ungroup = false,
    int? id,
    int? locks,
    bool? hidden,
    PartFinish? finish,
    FaceBore? bore,
    Map<RabbetEdge, Rabbet>? rabbets,
    ({double y, double z})? startCut,
    ({double y, double z})? endCut,
  }) => Beam(
    id ?? this.id,
    name ?? this.name,
    origin ?? this.origin,
    size ?? this.size,
    along ?? this.along,
    across ?? this.across,
    group: ungroup ? null : group ?? this.group,
    locks: locks ?? this.locks,
    hidden: hidden ?? this.hidden,
    finish: finish ?? this.finish,
    bore: bore ?? this.bore,
    rabbets: rabbets ?? this.rabbets,
    startCut: startCut ?? this.startCut,
    endCut: endCut ?? this.endCut,
  );

  static Beam between(
    int id,
    String name,
    Vector3 start,
    Vector3 end,
    Vector3 normal,
    double width,
    double height,
  ) {
    final direction = (end - start).normalized();
    var side = normal.cross(direction);
    if (side.length < 1e-7) {
      side = (direction.z.abs() > .9 ? axis(1) : axis(2)).cross(direction);
    }
    return Beam(
      id,
      name,
      start,
      Vector3(start.distanceTo(end), width, height),
      direction,
      side.normalized(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'origin': _xyz(origin),
    'size': _xyz(size),
    'along': _xyz(along),
    'across': _xyz(across),
    'group': group,
    'locks': locks,
    if (bore case final hole?) 'bore': [hole.u, hole.v, hole.diameter],
    if (rabbets.isNotEmpty)
      'rabbets': {
        for (final e in rabbets.entries)
          e.key.name: [e.value.width, e.value.depth],
      },
    if (hidden) 'hidden': true,
    if (finish != woodFinish)
      'finish': {'texture': finish.texture.name, 'rgb': finish.rgb},
    if (bevelled) 'cuts': [startCut.y, startCut.z, endCut.y, endCut.z],
  };
  factory Beam.fromJson(Map<String, dynamic> json) {
    final cuts = (json['cuts'] as List? ?? [0, 0, 0, 0]).cast<num>();
    if (cuts.length != 4 ||
        cuts.any((v) => !v.isFinite || v.abs() > maxCutOffset)) {
      throw FormatException(editorStrings.invalidEndCut);
    }
    final b = Beam(
      json['id'] as int,
      json['name'] as String,
      _readVector(json['origin']),
      _readVector(json['size']),
      _readVector(json['along']),
      _readVector(json['across']),
      group: json['group'] as int?,
      locks: json['locks'] as int? ?? 0,
      hidden: json['hidden'] as bool? ?? false,
      finish: readPartFinish(json['finish']),
      bore: _readBore(json['bore']),
      rabbets: _readRabbets(json['rabbets']),
      startCut: (y: cuts[0].toDouble(), z: cuts[1].toDouble()),
      endCut: (y: cuts[2].toDouble(), z: cuts[3].toDouble()),
    );
    if (b.id <= 0 ||
        !b.cutsFit ||
        [b.size.x, b.size.y, b.size.z].any((d) => d <= 0) ||
        (b.along.length - 1).abs() > .00001 ||
        (b.across.length - 1).abs() > .00001 ||
        b.along.dot(b.across).abs() > .00001) {
      throw FormatException(editorStrings.invalidPartGeometry);
    }
    return b;
  }
}

class Anchor {
  final Vector3 point;
  final int? beam;
  final int corner;
  final Vector3? local;
  final String label;
  String get displayLabel => switch (label) {
    'Угол' => editorStrings.corner,
    'Грань' => editorStrings.face,
    'Грань полки' => editorStrings.shelfFace,
    'Плоскость' => editorStrings.plane,
    'Центр детали' => editorStrings.partCenter,
    'Центр грани' => editorStrings.faceCenter,
    'Середина ребра' => editorStrings.edgeMidpoint,
    'Ребро' => editorStrings.rulerEdge,
    'Верхнее ребро' => editorStrings.rulerUpperEdge,
    'Нижнее ребро' => editorStrings.rulerLowerEdge,
    'Средняя линия' => editorStrings.rulerCenterline,
    _ => label,
  };
  final int? face;
  Anchor(
    this.point, [
    this.beam,
    this.corner = 0,
    this.local,
    this.label = 'Угол',
    this.face,
  ]);
  Vector3 resolve(Project project) {
    final stock = project.byId[beam];
    if (stock == null) return point;
    final t = local;
    if (t == null) return stock.corner(corner);
    return stock.pointAt(t);
  }

  Map<String, dynamic> toJson() => {
    'point': _xyz(point),
    'beam': beam,
    'corner': corner,
    if (local != null) 'local': _xyz(local!),
    'label': label,
    'face': face,
  };
  factory Anchor.fromJson(Map<String, dynamic> json) {
    final face = json['face'];
    if (face != null && (face is! int || face < 0 || face > 5)) {
      throw FormatException(editorStrings.invalidFace);
    }
    final corner = json['corner'] as int;
    if (corner < 0 || corner > 7) {
      throw FormatException(editorStrings.invalidCorner);
    }
    return Anchor(
      _readVector(json['point']),
      json['beam'] as int?,
      corner,
      json['local'] == null ? null : _readVector(json['local']),
      json['label'] as String? ?? 'Угол',
      json['face'] as int?,
    );
  }
}

class Dimension {
  final Anchor a, b;
  final bool clearance;
  final String? name;
  final bool? _locked;
  bool get locked => _locked ?? (a.beam != null || b.beam != null);
  Dimension(this.a, this.b, {this.clearance = false, this.name, this._locked});

  Dimension copy({String? name, bool? locked}) => Dimension(
    a,
    b,
    clearance: clearance,
    name: name ?? this.name,
    locked: locked ?? this.locked,
  );
  ({Vector3 from, Vector3 to, Vector3 direction})? geometry(Project p) {
    if (clearance) {
      final first = p.byId[a.beam], second = p.byId[b.beam];
      if (first == null || second == null || a.face == null || b.face == null) {
        return null;
      }
      return _faceGap(first, a.face!, second, b.face!);
    }
    final start = a.resolve(p), end = b.resolve(p);
    return (from: start, to: end, direction: (end - start).normalized());
  }

  double length(Project p) {
    final g = geometry(p);
    return g == null ? double.nan : g.from.distanceTo(g.to);
  }

  Dimension withLength(Project project, double distance) {
    if (locked || !distance.isFinite || distance <= 0) return this;
    final g = geometry(project);
    if (g == null ||
        g.direction.length2 == 0 ||
        g.from.distanceTo(g.to) == distance) {
      return this;
    }
    // Sliding shelves can move the start of a clearance along the first face.
    final first = clearance
        ? Anchor(
            g.from,
            a.beam,
            a.corner,
            project.byId[a.beam]!.localAt(g.from),
            a.label,
            a.face,
          )
        : a;
    return Dimension(
      first,
      Anchor(g.from + g.direction * distance),
      name: name,
      locked: false,
    );
  }
}

class Bounds3 {
  final Vector3 low, high;
  Bounds3(this.low, this.high);
  factory Bounds3.points(Iterable<Vector3> points) {
    final lo = Vector3.all(double.infinity),
        hi = Vector3.all(double.negativeInfinity);
    for (final p in points) {
      for (var i = 0; i < 3; i++) {
        lo[i] = math.min(lo[i], p[i]);
        hi[i] = math.max(hi[i], p[i]);
      }
    }
    return Bounds3(lo, hi);
  }
  Vector3 get center => (low + high) * .5;
}

class Project {
  final String name;
  final List<Beam> beams;
  final List<Dimension> dimensions;
  final LengthUnit unit;
  final Vector3? workspaceSize;
  Map<int, String> _groupNames = const {};
  Map<int, String> get groupNames => _groupNames;
  late final Bounds3? partBounds = beams.isEmpty
      ? null
      : Bounds3.points(beams.expand((b) => b.corners));
  List<Vector3> get workspaceCorners {
    final size = workspaceSize;
    if (size == null) return const [];
    return [
      for (var i = 0; i < 8; i++)
        Vector3(
          i.isOdd ? size.x : 0,
          i & 2 != 0 ? size.y : 0,
          i & 4 != 0 ? size.z : 0,
        ),
    ];
  }

  Project withWorkspace(Vector3? size) =>
      Project(name, beams, dimensions, unit, size, groupNames);
  Project(
    this.name,
    Iterable<Beam> beams, [
    Iterable<Dimension> dimensions = const [],
    this.unit = LengthUnit.millimeter,
    this.workspaceSize,
    Map<int, String> groupNames = const {},
  ]) : beams = List.unmodifiable(beams),
       dimensions = List.unmodifiable(dimensions) {
    if (groupNames.isNotEmpty) {
      _groupNames = Map.unmodifiable({
        for (final id in this.beams.map((b) => b.group).nonNulls)
          id: ?groupNames[id],
      });
    }
  }
  late final Map<int, Beam> byId = {for (final b in beams) b.id: b};
  late final bool hasHiddenParts = beams.any((b) => b.hidden);
  // Read-only input for drawing and picking. Edits always use the full project.
  late final Project visibleGeometry = hasHiddenParts
      ? copy(
          beams: beams.where((b) => !b.hidden),
          dimensions: dimensions.where(
            (d) =>
                byId[d.a.beam]?.hidden != true &&
                byId[d.b.beam]?.hidden != true,
          ),
        )
      : this;
  int get nextId => beams.fold(0, (v, b) => math.max(v, b.id)) + 1;
  int get nextGroup => beams.fold(0, (v, b) => math.max(v, b.group ?? 0)) + 1;
  Project copy({
    String? name,
    Iterable<Beam>? beams,
    Iterable<Dimension>? dimensions,
    LengthUnit? unit,
    Map<int, String>? groupNames,
  }) => Project(
    name ?? this.name,
    beams ?? this.beams,
    dimensions ?? this.dimensions,
    unit ?? this.unit,
    workspaceSize,
    groupNames ?? this.groupNames,
  );
  Set<int> assembly(int id) {
    final b = byId[id];
    if (b == null) return {};
    return b.group == null
        ? {id}
        : {
            for (final member in beams)
              if (member.group == b.group) member.id,
          };
  }

  Project edit(Set<int> ids, Beam Function(Beam) update) =>
      copy(beams: beams.map((b) => ids.contains(b.id) ? update(b) : b));
  Project move(Set<int> ids, Vector3 delta) =>
      edit(ids, (b) => b.copy(origin: b.origin + delta));
  Project rotate(Set<int> ids, Vector3 normal, double degrees) {
    if (ids.isEmpty) return this;
    final pivot = Bounds3.points(
      beams.where((b) => ids.contains(b.id)).expand((b) => b.corners),
    ).center;
    final angle = degrees * math.pi / 180;
    return edit(
      ids,
      (b) => b.copy(
        origin: pivot + turn(b.origin - pivot, normal, angle),
        along: turn(b.along, normal, angle).normalized(),
        across: turn(b.across, normal, angle).normalized(),
      ),
    );
  }

  Project remove(Set<int> ids) {
    final remaining = beams.where((b) => !ids.contains(b.id)).toList();
    final counts = <int?, int>{};
    for (final b in remaining) {
      counts[b.group] = (counts[b.group] ?? 0) + 1;
    }
    return copy(
      beams: remaining.map(
        (b) =>
            b.group != null && counts[b.group] == 1 ? b.copy(ungroup: true) : b,
      ),
      dimensions: dimensions.where(
        (d) => !ids.contains(d.a.beam) && !ids.contains(d.b.beam),
      ),
    );
  }

  String encode() => jsonEncode(toJson());
  Map<String, Object?> toJson() => {
    'version': 1,
    'unit': unit.name,
    if (workspaceSize case final size?) 'workspaceSize': _xyz(size),
    'name': name,
    if (groupNames.isNotEmpty)
      'groupNames': {
        for (final e in groupNames.entries) e.key.toString(): e.value,
      },
    'beams': beams.map((b) => b.toJson()).toList(),
    'dimensions': dimensions
        .map((d) => [d.a.toJson(), d.b.toJson(), d.clearance, d.name, d.locked])
        .toList(),
  };
  factory Project.decode(String source) => Project.fromJson(jsonDecode(source));
  factory Project.fromJson(Object? data) {
    if (data is! Map || data['version'] != 1) {
      throw FormatException(editorStrings.unknownProjectFormat);
    }
    final room = data['workspaceSize'] == null
        ? null
        : _readVector(data['workspaceSize']);
    if (room != null && (room.x <= 0 || room.y <= 0 || room.z <= 0)) {
      throw FormatException(editorStrings.invalidWorkspaceDimensions);
    }
    final p = Project(
      data['name'] as String,
      (data['beams'] as List).map((e) => Beam.fromJson(e)),
      (data['dimensions'] as List).map(
        (d) => Dimension(
          Anchor.fromJson(d[0]),
          Anchor.fromJson(d[1]),
          clearance: d.length > 2 && d[2] == true,
          name: d.length > 3 ? d[3] as String? : null,
          locked: d.length > 4 ? d[4] as bool? : null,
        ),
      ),
      LengthUnit.values.byName(data['unit'] as String? ?? 'millimeter'),
      room,
      {
        for (final entry in (data['groupNames'] as Map? ?? const {}).entries)
          int.parse(entry.key as String): entry.value as String,
      },
    );
    if (p.beams.length != p.byId.length ||
        p.dimensions
            .expand((d) => [d.a, d.b])
            .any((a) => a.beam != null && !p.byId.containsKey(a.beam))) {
      throw FormatException(editorStrings.brokenPartReferences);
    }
    return p;
  }

  factory Project.bench() {
    final beams = <Beam>[];
    void add(String name, Vector3 start, Vector3 size, Vector3 x, Vector3 y) {
      beams.add(Beam(beams.length + 1, name, start, size, x, y));
    }

    for (var i = 0; i < 4; i++) {
      add(
        editorStrings.seatSlat(i + 1),
        Vector3(0, i * 92, 414),
        Vector3(1200, 84, 36),
        axis(0),
        axis(1),
      );
    }
    for (final x in [65.0, 1080.0]) {
      for (final y in [25.0, 280.0]) {
        add(
          editorStrings.leg(beams.length - 3),
          Vector3(x, y, 0),
          Vector3(414, 55, 55),
          axis(2),
          axis(0),
        );
      }
    }
    for (final y in [37.0, 298.0]) {
      add(
        editorStrings.sideRail(beams.length - 7),
        Vector3(120, y, 329),
        Vector3(960, 25, 85),
        axis(0),
        axis(1),
      );
    }
    for (final x in [105.0, 1120.0]) {
      add(
        editorStrings.crossRail(beams.length - 9),
        Vector3(x, 80, 329),
        Vector3(200, 25, 85),
        axis(1),
        -axis(0),
      );
    }
    return Project(editorStrings.bench, beams);
  }
}
