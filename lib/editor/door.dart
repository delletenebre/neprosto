part of 'model.dart';

enum DoorHinge {
  left,
  right,
  top,
  bottom;

  bool get onSide => this == left || this == right;
  String get label => switch (this) {
    left => editorStrings.leftHingedDoor,
    right => editorStrings.rightHingedDoor,
    top => editorStrings.liftUpDoor,
    bottom => editorStrings.dropDownDoor,
  };
}

bool validDoorAngle(double angle) => angle > 0 && angle <= 180;

// Wardrobes saved before hinge metadata used localized door names.
final _legacyWardrobeHinges = {
  for (final s in editorLocales.map(lookupAppLocalizations)) ...{
    s.leftHingedDoor: DoorHinge.left,
    s.rightHingedDoor: DoorHinge.right,
  },
};

/// Stock-relative edges and outside face, fixed when a panel becomes a door.
typedef DoorMount = ({bool verticalAcross, bool leftAtMax, bool frontAtMax});
const DoorMount defaultDoorMount = (
  verticalAcross: false,
  leftAtMax: false,
  frontAtMax: false,
);

DoorMount _readDoorMount(Object? data) => switch (data) {
  null => defaultDoorMount,
  {
    'verticalAcross': bool across,
    'leftAtMax': bool left,
    'frontAtMax': bool front,
  } =>
    (verticalAcross: across, leftAtMax: left, frontAtMax: front),
  _ => throw FormatException(editorStrings.invalidPartGeometry),
};

// Read a vertical face from the front. For a horizontal lid the current
// view determines which edge is at the top of the hinge diagram.
({Vector3 right, Vector3 top}) _doorFaceAxes(
  Vector3 along,
  Vector3 across,
  Vector3 towardEye,
  Vector3 screenUp,
) {
  final upReference = math.max(along.z.abs(), across.z.abs()) > .01
      ? axis(2)
      : screenUp;
  final vertical = across.dot(upReference).abs() > along.dot(upReference).abs()
      ? across
      : along;
  final top = vertical.dot(upReference) < 0 ? -vertical : vertical;
  final normal = along.cross(across);
  final front = normal.dot(towardEye) > 0 ? normal : -normal;
  return (right: top.cross(front).normalized(), top: top);
}

extension DoorGeometry on Beam {
  bool get hingeAcross => hinge!.onSide == doorMount.verticalAcross;
  bool get hingeAtMax {
    if (hinge!.onSide) return (hinge == DoorHinge.right) != doorMount.leftAtMax;
    final vertical = doorMount.verticalAcross ? across : along;
    final horizontal = doorMount.verticalAcross ? along : across;
    final front = doorMount.frontAtMax ? up : -up;
    final right = doorMount.leftAtMax ? -horizontal : horizontal;
    final topAtMax = vertical.dot(front.cross(right)) > 0;
    return (hinge == DoorHinge.top) == topAtMax;
  }

  Beam withDoorHinge(
    DoorHinge? next, {
    required Vector3 towardEye,
    required Vector3 screenUp,
    double? angle,
  }) {
    final degrees = angle ?? openingAngle;
    if (!validDoorAngle(degrees) ||
        (next == hinge && (next == null || degrees == openingAngle))) {
      return this;
    }
    final closed = doorOpen ? swingDoor(1) : this;
    var mount = closed.doorMount;
    if (hinge == null && next != null) {
      final axes = _doorFaceAxes(along, across, towardEye, screenUp);
      final verticalAcross = across.dot(axes.top).abs() > .5;
      final horizontal = verticalAcross ? along : across;
      mount = (
        verticalAcross: verticalAcross,
        leftAtMax: horizontal.dot(axes.right) < 0,
        frontAtMax: up.dot(towardEye) > 0,
      );
    }
    // Keep the template's generated label in sync; custom names are retained.
    final autoName =
        next != hinge &&
        hinge != null &&
        (_legacyWardrobeHinges[name] == hinge ||
            editorLocales
                .map(lookupAppLocalizations)
                .any(
                  (s) =>
                      (hinge == DoorHinge.top && name == s.liftUpDoor) ||
                      (hinge == DoorHinge.bottom && name == s.dropDownDoor),
                ));
    final changed = closed.copy(
      hinge: next,
      clearHinge: next == null,
      doorMount: mount,
      openingAngle: degrees,
      name: autoName ? (next?.label ?? editorStrings.doorPanel) : name,
    );
    return doorOpen && next != null ? changed.swingDoor(1) : changed;
  }

  Beam swingDoor(double fraction) {
    if (fraction == 0 || hinge == null) return this;
    final acrossVertical = hingeAcross;
    final span = acrossVertical ? along : across;
    final front = doorMount.frontAtMax ? up : -up;
    final quarterTurn = hingeAtMax != doorOpen ? -front : front;
    final angle = fraction * openingAngle * math.pi / 180;
    final turned = fraction * openingAngle == 90
        ? quarterTurn
        : span * math.cos(angle) + quarterTurn * math.sin(angle);
    final nextAlong = acrossVertical ? turned : along;
    final nextAcross = acrossVertical ? across : turned;
    final offset = hingeAtMax ? (acrossVertical ? size.x : size.y) : 0.0;
    final faceOffset = doorMount.frontAtMax ? size.z : 0.0;
    return copy(
      origin:
          origin +
          (span - turned) * offset +
          (up - nextAlong.cross(nextAcross)) * faceOffset,
      along: nextAlong,
      across: nextAcross,
      doorOpen: fraction == 1 ? !doorOpen : doorOpen,
    );
  }
}

/// Orientation of the outside face in the group's current pose. The hinge
/// sits on the bounds of all members, so it follows moves and size edits.
class GroupDoor {
  const GroupDoor(
    this.hinge,
    this.right,
    this.top, {
    this.angle = 90,
    this.isOpen = false,
  });
  final DoorHinge hinge;
  final Vector3 right, top;
  final double angle;
  final bool isOpen;

  factory GroupDoor.fit(
    List<Beam> parts,
    DoorHinge hinge,
    double angle,
    Vector3 towardEye,
    Vector3 screenUp,
  ) {
    final board = parts.reduce(
      (a, b) => a.size.x * a.size.y >= b.size.x * b.size.y ? a : b,
    );
    final basis = [board.along, board.across, board.up];
    final bounds = _boundsInBasis(parts, basis[0], basis[1], basis[2]);
    final span = bounds.high - bounds.low;
    var normal = 2;
    for (var i = 0; i < 2; i++) {
      if (span[i] < span[normal]) normal = i;
    }
    final axes = _doorFaceAxes(
      basis[(normal + 1) % 3],
      basis[(normal + 2) % 3],
      towardEye,
      screenUp,
    );
    return GroupDoor(hinge, axes.right, axes.top, angle: angle);
  }

  GroupDoor rotated(Vector3 axis, double radians, {required bool toggle}) =>
      GroupDoor(
        hinge,
        turn(right, axis, radians).normalized(),
        turn(top, axis, radians).normalized(),
        angle: angle,
        isOpen: toggle ? !isOpen : isOpen,
      );

  Project Function(double) swing(Project project, int group) {
    final parts = project.beams.where((b) => b.group == group);
    final ids = parts.map((b) => b.id).toSet();
    final front = right.cross(top);
    final bounds = _boundsInBasis(parts, right, top, front);
    final pivot =
        right * (hinge == DoorHinge.right ? bounds.high.x : bounds.low.x) +
        top * (hinge == DoorHinge.top ? bounds.high.y : bounds.low.y) +
        front * bounds.high.z;
    final axis = switch (hinge) {
      DoorHinge.left => -top,
      DoorHinge.right => top,
      DoorHinge.top => -right,
      DoorHinge.bottom => right,
    };
    final radians = (isOpen ? -angle : angle) * math.pi / 180;
    return (t) => t == 0
        ? project
        : project._rotateAround(
            ids,
            axis,
            pivot,
            radians * t,
            toggleGroup: t == 1 ? group : null,
          );
  }

  Map<String, Object?> toJson() => {
    'hinge': hinge.name,
    'right': _xyz(right),
    'top': _xyz(top),
    'angle': angle,
    'open': isOpen,
  };

  factory GroupDoor.fromJson(Map data) {
    final right = _readVector(data['right']), top = _readVector(data['top']);
    final angle = (data['angle'] as num).toDouble();
    if (!validDoorAngle(angle) ||
        (right.length - 1).abs() > 1e-5 ||
        (top.length - 1).abs() > 1e-5 ||
        right.dot(top).abs() > 1e-5) {
      throw FormatException(editorStrings.invalidPartGeometry);
    }
    return GroupDoor(
      DoorHinge.values.byName(data['hinge'] as String),
      right,
      top,
      angle: angle,
      isOpen: data['open'] as bool,
    );
  }
}

Bounds3 _boundsInBasis(Iterable<Beam> parts, Vector3 x, Vector3 y, Vector3 z) =>
    Bounds3.points(
      parts
          .expand((b) => b.corners)
          .map((p) => Vector3(p.dot(x), p.dot(y), p.dot(z))),
    );
