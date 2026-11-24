import '../l10n/strings.dart';

import 'dart:ui' show Color;

import 'scene.dart';

enum GridPlane {
  xy('XY', Color(0xff94a48a)),
  xz('XZ', Color(0xff889db6)),
  yz('YZ', Color(0xffae93a4));

  const GridPlane(this.axes, this.color);
  final String axes;
  final Color color;
  WorkPlane get plane => switch (this) {
    xy => WorkPlane.xy(),
    xz => WorkPlane.xz(),
    yz => WorkPlane.yz(),
  };
  String get label => switch (this) {
    GridPlane.xy => editorStrings.floor,
    GridPlane.xz => editorStrings.frontPlane,
    GridPlane.yz => editorStrings.side,
  };
}

class GridVisibility {
  const GridVisibility({
    this.automatic = true,
    this.planes = const {GridPlane.xy},
  });
  final bool automatic;
  final Set<GridPlane> planes;
  GridVisibility follow(bool value) =>
      GridVisibility(automatic: value, planes: planes);
  GridVisibility toggle(GridPlane plane) {
    final next = {...planes};
    if (!next.remove(plane)) next.add(plane);
    return GridVisibility(automatic: false, planes: Set.unmodifiable(next));
  }

  int encode() => planes.fold(
    automatic ? 8 : 0,
    (bits, plane) => bits | (1 << plane.index),
  );
  factory GridVisibility.decode(int? bits) {
    if (bits == null || bits < 0 || bits > 15) return const GridVisibility();
    return GridVisibility(
      automatic: (bits & 8) != 0,
      planes: Set.unmodifiable(
        GridPlane.values.where((plane) => bits & (1 << plane.index) != 0),
      ),
    );
  }
}
