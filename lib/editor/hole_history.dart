part of 'hole_dialog.dart';

// Keep exact millimetres as well as the text. Inch formatting can round a
// value, and an unfinished expression is still a valid state to return to.
typedef _LengthEdit = ({String text, double? mm});

extension on LengthEditingController {
  _LengthEdit get saved => (text: text, mm: millimeters);
  void restore(_LengthEdit edit) {
    setMillimeters(edit.mm);
    if (text != edit.text) text = edit.text;
  }
}

typedef _FaceEdit = ({
  PanelHole original,
  String name,
  DrillDatum? datum,
  int? anchor,
  bool end,
  bool far,
  bool back,
  bool chosen,
  bool keepRim,
  bool shaft,
  PanelEdge edge,
  double previewX,
  double previewY,
  double previewDiameter,
  _LengthEdit x,
  _LengthEdit y,
  _LengthEdit diameter,
  _LengthEdit depth,
  _LengthEdit center,
  _LengthEdit rim,
  _LengthEdit shaftDiameter,
  _LengthEdit shaftOffset,
});

extension on _HoleDraft {
  _FaceEdit get saved => (
    original: original,
    name: name,
    datum: datum,
    anchor: anchorFace,
    end: fromEnd,
    far: fromFar,
    back: back,
    chosen: edgeChosen,
    keepRim: keepRim,
    shaft: hasBolt,
    edge: edge,
    previewX: previewX,
    previewY: previewY,
    previewDiameter: previewDiameter,
    x: x.saved,
    y: y.saved,
    diameter: diameter.saved,
    depth: depth.saved,
    center: center.saved,
    rim: rim.saved,
    shaftDiameter: bolt.diameter.saved,
    shaftOffset: bolt.offset.saved,
  );
  void restore(_FaceEdit edit) {
    name = edit.name;
    datum = edit.datum;
    anchorFace = edit.anchor;
    fromEnd = edit.end;
    fromFar = edit.far;
    back = edit.back;
    edgeChosen = edit.chosen;
    keepRim = edit.keepRim;
    bolt.enabled = edit.shaft;
    edge = edit.edge;
    x.restore(edit.x);
    y.restore(edit.y);
    diameter.restore(edit.diameter);
    depth.restore(edit.depth);
    center.restore(edit.center);
    rim.restore(edit.rim);
    bolt.diameter.restore(edit.shaftDiameter);
    bolt.offset.restore(edit.shaftOffset);
    previewX = edit.previewX;
    previewY = edit.previewY;
    previewDiameter = edit.previewDiameter;
  }
}

class _HoleSnapshot {
  _HoleSnapshot(_HoleDialogState dialog)
    : faces = [for (final d in dialog.drafts) d.saved],
      edges = [...dialog.edges],
      groups = dialog.groups,
      datums = {...dialog.datums},
      pose = dialog.benchPose,
      selected = dialog.selected,
      edge = dialog.edgeSelection,
      extra = {...dialog.extraSelection},
      back = dialog.viewBack;
  final List<_FaceEdit> faces;
  final List<EdgeHole> edges;
  final DrillGroups groups;
  final Map<int, Offset> datums;
  final Beam? pose;
  final int selected;
  final HoleRef? edge;
  final Set<HoleRef> extra;
  final bool back;

  bool sameWork(_HoleSnapshot other) =>
      listEquals(faces, other.faces) &&
      listEquals(edges, other.edges) &&
      mapEquals(groups.members, other.groups.members) &&
      mapEquals(datums, other.datums) &&
      pose == other.pose;
}
