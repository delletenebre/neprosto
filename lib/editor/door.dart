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
      // For vertical panels use project height. On a horizontal panel use
      // the current view to choose the edge that reads as upright.
      final upReference = math.max(along.z.abs(), across.z.abs()) > .01
          ? axis(2)
          : screenUp;
      final verticalAcross =
          across.dot(upReference).abs() > along.dot(upReference).abs();
      final vertical = verticalAcross ? across : along;
      final horizontal = verticalAcross ? along : across;
      final frontAtMax = up.dot(towardEye) > 0;
      final front = frontAtMax ? up : -up;
      final rising = vertical.dot(upReference) < 0 ? -vertical : vertical;
      mount = (
        verticalAcross: verticalAcross,
        leftAtMax: horizontal.dot(rising.cross(front)) < 0,
        frontAtMax: frontAtMax,
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
