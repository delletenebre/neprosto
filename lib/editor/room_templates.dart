part of 'project_templates.dart';

extension _RoomFurniture on _Parts {
  void hoodCabinet() {
    final s = editorStrings, t = measure(18, .75), back = measure(8, .25);
    final gap = measure(2, .125), frontY = t + gap;
    final bodyDepth = d - frontY, insideHeight = h - 2 * t;
    final chaseWidth = measure(240, 9), chaseDepth = measure(210, 8.5);
    final left = (w - chaseWidth) / 2, right = w - left;
    final rear = d - back, coverY = rear - chaseDepth - t;
    final pipeY = rear - chaseDepth / 2, bore = measure(160, 6.25);
    for (final x in [0.0, w - t]) {
      side(s.sidePanel, x, frontY, 0, t, bodyDepth, h);
    }
    for (final z in [0.0, h - t]) {
      flat(
        z == 0 ? s.bottomPanel : s.topPanel,
        t,
        frontY,
        z,
        w - 2 * t,
        bodyDepth,
        t,
      );
      beams.last = beams.last.copy(
        holes: [
          PanelHole(w / 2 - t, pipeY - frontY, bore, name: s.ductOpening),
        ],
      );
    }
    front(s.backPanel, t, rear, t, w - 2 * t, back, insideHeight);
    for (final x in [left, right - t]) {
      side(s.chaseSide, x, coverY + t, t, t, chaseDepth, insideHeight);
    }
    front(s.chaseCover, left, coverY, t, chaseWidth, t, insideHeight);
    final bay = left - t, railHeight = measure(80, 3);
    for (final x in [t, right]) {
      flat(s.shelfPart, x, frontY, h / 2, bay, rear - frontY, t);
      front(s.hangingRail, x, rear - t, h - t - railHeight, bay, t, railHeight);
    }

    for (final (i, hinge) in [DoorHinge.left, DoorHinge.right].indexed) {
      final width = (w - 4 * gap) / 2, height = h - 2 * gap;
      final x = i == 0 ? gap : w - gap - width;
      // Stock length points upwards. The reverse face of each door faces the shelves.
      final door = Beam(
        beams.length + 1,
        hinge.label,
        Vector3(x, 0, gap),
        Vector3(height, width, t),
        axis(2),
        axis(0),
        finish: finish,
        hinge: hinge,
        holes: [
          for (final z in [measure(90, 3.5), height - measure(90, 3.5)])
            PanelHole(
              z,
              measure(22, .875),
              measure(35, 1.375),
              depth: measure(12, .5),
              back: true,
              fromFarEdge: i == 1,
              name: s.hingeCup,
            ),
        ],
      );
      beams.add(door);
    }
  }

  void sinkBase() {
    final s = editorStrings, t = measure(18, .75), base = measure(100, 4);
    final setback = measure(70, 3), rail = measure(90, 3.5);
    for (final x in [0.0, w - t]) {
      side(s.sidePanel, x, setback, 0, t, d - setback, base);
      side(s.sidePanel, x, 0, base, t, d, h - base);
    }
    front(s.plinth, t, setback, 0, w - 2 * t, t, base);
    flat(s.bottomPanel, t, 0, base, w - 2 * t, d, t);
    for (final y in [0.0, d - rail]) {
      flat(s.frameRail, t, y, h - t, w - 2 * t, rail, t);
    }
    front(s.frameRail, t, d - t, base + t, w - 2 * t, t, rail);
  }

  void platformBed() {
    final s = editorStrings, rail = measure(30, 2), apron = measure(180, 7);
    final cleat = measure(30, 1.5), foot = measure(70, 3);
    final slat = measure(90, 3.5), slatT = measure(20, .75);
    final seat = h - measure(30, 1.25) - slatT;
    final length = d - 2 * rail, width = w - 2 * rail;
    for (final y in [0.0, d - rail]) {
      front(s.frameRail, 0, y, h - apron, w, rail, apron);
    }
    for (final x in [0.0, w - rail]) {
      cross(
        s.sideRail(x == 0 ? 1 : 2),
        x,
        rail,
        h - apron,
        length,
        apron,
        rail,
      );
    }
    for (final x in [rail, w - rail - cleat]) {
      cross(s.slatLedger, x, rail, seat - cleat, length, cleat, cleat);
    }
    for (final x in [0.0, w - foot]) {
      for (final y in [0.0, d - foot]) {
        post(x, y, 0, h - apron, foot);
      }
    }
    final spine = measure(70, 3);
    cross(
      s.centerRail,
      (w - cleat) / 2,
      rail,
      seat - spine,
      length,
      spine,
      cleat,
    );
    for (final y in [rail, (d - foot) / 2, d - rail - foot]) {
      post((w - foot) / 2, y, 0, seat - spine, foot);
    }
    for (var i = 0; i < 16; i++) {
      flat(
        s.bedSlat,
        rail,
        rail + i * (length - slat) / 15,
        seat,
        width,
        slat,
        slatT,
      );
    }
  }

  void basinShelf() {
    final s = editorStrings, t = measure(18, .75);
    final cutout = measure(200, 8), openingDepth = measure(230, 9);
    final frontDepth = d - openingDepth, wing = (w - cutout) / 2 - t;
    for (final x in [0.0, w - t]) {
      side(s.sidePanel, x, 0, 0, t, d, h);
    }
    for (final z in [0.0, h - t]) {
      flat(s.shelfPart, t, 0, z, w - 2 * t, frontDepth, t);
      for (final x in [t, w - t - wing]) {
        flat(s.shelfWing, x, frontDepth, z, wing, openingDepth, t);
      }
    }
    final high = measure(80, 3);
    for (final x in [t, w - t - wing]) {
      front(s.hangingRail, x, d - t, h - t - high, wing, t, high);
    }
  }

  void fileTrays() {
    final s = editorStrings, t = measure(12, .5), tray = measure(6, .25);
    final cleat = measure(10, .5), depth = d - t;
    for (final x in [0.0, w - t]) {
      side(s.sidePanel, x, 0, 0, t, depth, h);
    }
    front(s.backPanel, 0, depth, 0, w, t, h);
    for (final z in [cleat, h / 2 - tray, h - tray]) {
      for (final x in [t, w - t - cleat]) {
        cross(s.slatLedger, x, 0, z - cleat, depth, cleat, cleat);
      }
      flat(s.paperTray, t, 0, z, w - 2 * t, depth, tray);
    }
  }
}
