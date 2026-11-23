import 'dart:convert';
import 'dart:math' as math;

import 'package:vector_math/vector_math_64.dart' show Vector3;
export 'package:vector_math/vector_math_64.dart' show Vector3;
part 'clearance.dart';

Vector3 axis(int i) => Vector3.zero()..[i] = 1;
String mm(double value) {
  final rounded = (value * 100).round() / 100;
  return rounded == rounded.truncateToDouble()
      ? rounded.toInt().toString()
      : rounded.toString();
}

enum LengthUnit {
  millimeter('мм', 'Миллиметры', 1, 3),
  centimeter('см', 'Сантиметры', 10, 4),
  inch('″', 'Дюймы', 25.4, 5);

  final String symbol, title;
  final double factor;
  final int precision;
  const LengthUnit(this.symbol, this.title, this.factor, this.precision);
  String format(double internal) {
    final n = internal / factor;
    final v = n.toStringAsFixed(precision).replaceFirst(RegExp(r'\.?0+$'), '');
    return v == '-0' || v.isEmpty ? '0' : v;
  }
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
    throw const FormatException('Некорректный вектор');
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

class Beam {
  static String defaultName(int id) => 'Деталь $id';

  final int id;
  final String name;
  final Vector3 origin, size, along, across;
  final int? group;
  final int locks;
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
  Beam(
    this.id,
    this.name,
    this.origin,
    this.size,
    this.along,
    this.across, {
    this.group,
    this.locks = 0,
    this.startCut = (y: 0, z: 0),
    this.endCut = (y: 0, z: 0),
  });

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
    if (bevelled) 'cuts': [startCut.y, startCut.z, endCut.y, endCut.z],
  };
  factory Beam.fromJson(Map<String, dynamic> json) {
    final cuts = (json['cuts'] as List? ?? [0, 0, 0, 0]).cast<num>();
    if (cuts.length != 4 || cuts.any((v) => !v.isFinite || v.abs() > 1e8)) {
      throw const FormatException('Некорректный торец');
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
      startCut: (y: cuts[0].toDouble(), z: cuts[1].toDouble()),
      endCut: (y: cuts[2].toDouble(), z: cuts[3].toDouble()),
    );
    if (b.id <= 0 ||
        b.size.x < b.minimumLength ||
        [b.size.x, b.size.y, b.size.z].any((d) => d <= 0) ||
        (b.along.length - 1).abs() > .00001 ||
        (b.across.length - 1).abs() > .00001 ||
        b.along.dot(b.across).abs() > .00001) {
      throw const FormatException('Некорректная геометрия детали');
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
      throw const FormatException('Некорректная грань');
    }
    final corner = json['corner'] as int;
    if (corner < 0 || corner > 7) {
      throw const FormatException('Некорректный угол');
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
  Dimension(this.a, this.b, {this.clearance = false});
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
      Project(name, beams, dimensions, unit, size);
  Project(
    this.name,
    Iterable<Beam> beams, [
    Iterable<Dimension> dimensions = const [],
    this.unit = LengthUnit.millimeter,
    this.workspaceSize,
  ]) : beams = List.unmodifiable(beams),
       dimensions = List.unmodifiable(dimensions);
  late final Map<int, Beam> byId = {for (final b in beams) b.id: b};
  int get nextId => beams.fold(0, (v, b) => math.max(v, b.id)) + 1;
  int get nextGroup => beams.fold(0, (v, b) => math.max(v, b.group ?? 0)) + 1;
  Project copy({
    String? name,
    Iterable<Beam>? beams,
    Iterable<Dimension>? dimensions,
    LengthUnit? unit,
  }) => Project(
    name ?? this.name,
    beams ?? this.beams,
    dimensions ?? this.dimensions,
    unit ?? this.unit,
    workspaceSize,
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

  bool canSetDistance(Dimension d) =>
      d.b.beam != null &&
      !assembly(d.b.beam!).contains(d.a.beam) &&
      d.geometry(this) != null &&
      (d.clearance || d.length(this) > 1e-7);
  Project setDistance(Dimension d, double distance) {
    if (!canSetDistance(d) || distance < 0) return this;
    final g = d.geometry(this)!;
    return move(
      assembly(d.b.beam!),
      g.direction * (distance - g.from.distanceTo(g.to)),
    );
  }

  String encode() => jsonEncode({
    'version': 1,
    'unit': unit.name,
    if (workspaceSize case final size?) 'workspaceSize': _xyz(size),
    'name': name,
    'beams': beams.map((b) => b.toJson()).toList(),
    'dimensions': dimensions
        .map((d) => [d.a.toJson(), d.b.toJson(), if (d.clearance) true])
        .toList(),
  });
  factory Project.decode(String source) {
    final data = jsonDecode(source);
    if (data is! Map || data['version'] != 1) {
      throw const FormatException('Неизвестный формат проекта');
    }
    final room = data['workspaceSize'] == null
        ? null
        : _readVector(data['workspaceSize']);
    if (room != null && (room.x <= 0 || room.y <= 0 || room.z <= 0)) {
      throw const FormatException('Некорректный размер рабочего пространства');
    }
    final p = Project(
      data['name'] as String,
      (data['beams'] as List).map((e) => Beam.fromJson(e)),
      (data['dimensions'] as List).map(
        (d) => Dimension(
          Anchor.fromJson(d[0]),
          Anchor.fromJson(d[1]),
          clearance: d.length > 2 && d[2] == true,
        ),
      ),
      LengthUnit.values.byName(data['unit'] as String? ?? 'millimeter'),
      room,
    );
    if (p.beams.length != p.byId.length ||
        p.dimensions
            .expand((d) => [d.a, d.b])
            .any((a) => a.beam != null && !p.byId.containsKey(a.beam))) {
      throw const FormatException('Повреждённые ссылки на детали');
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
        'Планка сиденья ${i + 1}',
        Vector3(0, i * 92, 414),
        Vector3(1200, 84, 36),
        axis(0),
        axis(1),
      );
    }
    for (final x in [65.0, 1080.0]) {
      for (final y in [25.0, 280.0]) {
        add(
          'Ножка ${beams.length - 3}',
          Vector3(x, y, 0),
          Vector3(414, 55, 55),
          axis(2),
          axis(0),
        );
      }
    }
    for (final y in [37.0, 298.0]) {
      add(
        'Продольная царга ${beams.length - 7}',
        Vector3(120, y, 329),
        Vector3(960, 25, 85),
        axis(0),
        axis(1),
      );
    }
    for (final x in [105.0, 1120.0]) {
      add(
        'Поперечная царга ${beams.length - 9}',
        Vector3(x, 80, 329),
        Vector3(200, 25, 85),
        axis(1),
        -axis(0),
      );
    }
    return Project('Скамья', beams);
  }
}
