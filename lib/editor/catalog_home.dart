part of 'project_templates.dart';

extension _CatalogHome on _Parts {
  void bagShelfPlan() {
    final s = editorStrings;
    front(s.backPanel, 0, d - 19, 0, w, 19, 140);
    flat(s.shelfPart, 0, 0, 140, w, d, 19);
  }

  void bathTrayPlan() {
    final s = editorStrings;
    flat(s.tabletop, 0, 0, 38.1, w, d, 19.05);
    for (final x in [76.2, w - 95.25]) {
      cross(s.frameRail, x, 0, 0, d, 38.1, 19.05);
    }
  }

  void pantryShelfPlan() {
    final s = editorStrings;
    for (final x in [0.0, w - 19]) {
      side(s.sidePanel, x, 13, 0, 19, 89, h);
    }
    for (final z in [0.0, 451.0, 749.0, 997.0, 1245.0, 1493.0, 1759.0]) {
      flat(s.shelfPart, 19, 13, z, 648, 89, 19);
    }
    for (final z in [
      60.0,
      240.0,
      510.0,
      650.0,
      810.0,
      1058.0,
      1306.0,
      1554.0,
    ]) {
      front(s.frontPanel, 0, 0, z, w, 13, 25);
    }
  }

  void wallShelfPlan() {
    final s = editorStrings;
    finish = FinishPreset.wood.finish;
    front(s.frameRail, 6, 260, 6, 1188, 40, 90);
    for (var i = 0; i < 5; i++) {
      cross(s.crossRail(i + 1), 6 + 287.0 * i, 6, 6, 254, 90, 40);
    }
    finish = FinishPreset.plywood.finish;
    for (final z in [0.0, 96.0]) {
      flat(s.shelfPart, 6, 6, z, 1188, 294, 6);
    }
    for (final x in [0.0, 1194.0]) {
      add(s.sidePanel, x, 6, 0, 294, 102, 6, 1, 2);
    }
    front(s.frontPanel, 0, 0, 0, 1200, 6, 102);
  }

  void blanketLadderPlan() {
    final s = editorStrings;
    for (final x in [0.0, 490.0]) {
      post(x, 0, 0, h, 40);
    }
    for (var i = 0; i < 5; i++) {
      front(s.crossRail(i + 1), 40, 0, 300 + i * 340, 450, 40, 40);
    }
  }

  void headphoneStandPlan() {
    final s = editorStrings;
    flat(s.bottomPanel, 0, 0, 0, 140, 140, 20);
    stile(s.uprightPost, 37.5, 92, 20, 65, 20, 273);
    cross(s.carryHandle, 45, 17, 243, 75, 50, 50);
  }

  void trivetPlan() {
    final s = editorStrings;
    for (var i = 0; i < 7; i++) {
      flat(s.deckBoard, 0, 24.0 * i, 7, 156, 12, 7);
      add(s.crossRail(i + 1), 24.0 * i, 0, 0, 156, 12, 7, 1, 0);
    }
  }

  void standingPlanterPlan() {
    final s = editorStrings;
    for (final x in [0.0, 340.0]) {
      for (final y in [0.0, 340.0]) {
        post(x, y, 0, 380, 40);
      }
      cross(s.planterWall, x == 0 ? 0 : 360, 40, 100, 300, 280, 20);
    }
    for (final y in [0.0, 360.0]) {
      front(s.planterWall, 40, y, 100, 300, 20, 280);
    }
    // Four rails rest between the side walls. Two cleats retain the deck.
    for (final x in [20.0, 340.0]) {
      cross(s.frameRail, x, 40, 100, 300, 20, 20);
    }
    for (var i = 0; i < 4; i++) {
      flat(s.bottomPanel, 20, 56 + i * 76, 120, 340, 40, 20);
    }
  }

  void windowBoxPlan() {
    final s = editorStrings;
    for (final y in [20.0, 200.0]) {
      front(s.planterWall, 40, y, 0, 1000, 20, 140);
    }
    for (final x in [20.0, 1040.0]) {
      cross(s.planterWall, x, 20, 0, 200, 140, 20);
    }
    for (final y in [40.0, 160.0]) {
      flat(s.frameRail, 40, y, 0, 1000, 40, 20);
    }
    for (var i = 0; i < 19; i++) {
      add(s.deckBoard, 40 + i * (970 / 18), 40, 20, 160, 30, 20, 1, 0);
    }
    for (var i = 0; i < 5; i++) {
      final z = i * 30.0;
      // Flush butt joints on the three visible faces instead of decorative mitres.
      front(s.frameRail, 0, 0, z, w, 20, 20);
      for (final x in [0.0, 1060.0]) {
        cross(s.frameRail, x, 20, z, 200, 20, 20);
      }
    }
  }

  void plantPanelPlan() {
    final s = editorStrings;
    List<Vector3> rectangle(double inset) => [
      Vector3(inset, 45, inset),
      Vector3(w - inset, 45, inset),
      Vector3(w - inset, 45, h - inset),
      Vector3(inset, 45, h - inset),
    ];
    rim(s.frameRail, rectangle(0), rectangle(40), 90, depthIsStockWidth: true);
    for (var i = 0; i < 7; i++) {
      front(s.trellisSlat, 40, 0, 40 + i * 146, 1000, 40, 140);
    }
  }

  void shuttersPlan() {
    final s = editorStrings;
    for (var i = 0; i < 3; i++) {
      final x = i * 453.0;
      for (final z in [0.0, 1470.0]) {
        front(s.frameRail, x, 0, z, 450, 20, 90);
      }
      for (final dx in [0.0, 360.0]) {
        stile(s.doorStile, x + dx, 0, 90, 90, 20, 1380);
      }
      for (var j = 0; j < 15; j++) {
        front(s.doorPanelInfill, x + 90, 0, 91 + j * 92, 270, 20, 90);
      }
    }
  }

  void hexShelfPlan() {
    final s = editorStrings;
    List<Vector3> vertices(double rad) => [
      for (var i = 0; i < 6; i++)
        Vector3(
          w / 2 + rad * math.cos(i * math.pi / 3),
          d / 2,
          h / 2 + rad * math.sin(i * math.pi / 3),
        ),
    ];
    rim(
      s.shelfPart,
      vertices(w / 2),
      vertices(178),
      d,
      depthIsStockWidth: true,
    );
  }

  void candleShelfPlan() {
    final s = editorStrings;
    final rise = 70 * math.sqrt(3);
    flat(s.shelfPart, 0, 0, rise, 140, 150, 20);
    stile(s.backPanel, 0, 130, rise + 20, 140, 20, 230);
    // A 20 mm inset on each edge gives a mitre at all three corners.
    for (final sign in [-1, 1]) {
      final base = sign < 0 ? rise : rise + 250;
      rim(
        s.frameRail,
        [
          Vector3(0, 140, base),
          Vector3(140, 140, base),
          Vector3(70, 140, base + sign * rise),
        ],
        [
          Vector3(20 * math.sqrt(3), 140, base + sign * 20),
          Vector3(140 - 20 * math.sqrt(3), 140, base + sign * 20),
          Vector3(70, 140, base + sign * (rise - 40)),
        ],
        20,
      );
    }
  }

  void birdhousePlan() {
    final s = editorStrings;
    final slope = w / (2 * h);
    final inset = 20 * math.sqrt(1 + slope * slope);
    double left(double z) => z * slope + inset;
    final insidePeak = h - inset / slope;
    // A matching ridge mitre on both roof boards leaves the top opening clear.
    for (final right in [false, true]) {
      double mirror(double x) => right ? w - x : x;
      profileBoard(
        s.roofBoard,
        Vector3(mirror(0), d / 2, 0),
        Vector3(w / 2, d / 2, h),
        Vector3(mirror(inset), d / 2, 0),
        Vector3(w / 2, d / 2, insidePeak),
        d,
        depthIsStockWidth: true,
      );
    }
    for (final y in [30.0, 137.0]) {
      profileBoard(
        s.sidePanel,
        Vector3(left(0), y, 0),
        Vector3(w - left(0), y, 0),
        Vector3(left(147), y, 147),
        Vector3(w - left(147), y, 147),
        20,
      );
    }
    profileBoard(
      s.bottomPanel,
      Vector3(left(0), 83.5, 0),
      Vector3(w - left(0), 83.5, 0),
      Vector3(left(20), 83.5, 20),
      Vector3(w - left(20), 83.5, 20),
      87,
      depthIsStockWidth: true,
    );
  }

  void toolTotePlan() {
    final s = editorStrings;
    flat(s.bottomPanel, 19, 19, 0, 508, 140, 19);
    for (final x in [0.0, 527.0]) {
      side(s.sidePanel, x, 19, 0, 19, 140, 267);
    }
    for (final y in [0.0, 159.0]) {
      front(s.frontPanel, 0, y, 0, 546, 19, 140);
    }
    final a = Vector3(19, 48, 235), b = Vector3(527, 130, 235);
    final along = (b - a).normalized();
    member(
      s.carryHandle,
      a,
      b,
      along.cross(axis(2)),
      64,
      19,
      startPlane: axis(0),
      endPlane: axis(0),
    );
  }

  void mirrorFramePlan() {
    final s = editorStrings;
    for (final x in [0.0, 448.0]) {
      post(x, 0, 0, 1727, 38);
      // Two edge-glued pieces form each stand-off, with a 10-degree wall face.
      for (var i = 0; i < 2; i++) {
        final a = Vector3(x + 19, 38, 1549 + i * 38);
        final b = Vector3(
          x + 19,
          190 - (i + .5) * 38 * math.tan(math.pi / 18),
          a.z,
        );
        member(
          s.frameRail,
          a,
          b,
          axis(0),
          38,
          19,
          startPlane: axis(1),
          endPlane: Vector3(0, 1, math.tan(math.pi / 18)),
        );
      }
    }
    for (final z in [114.0, 597.0, 1080.0, 1562.0]) {
      front(s.frameRail, 38, 13, z, 410, 19, 38);
    }
    flat(s.shelfPart, 38, 10, 108, 410, 22, 6);
  }

  void lanternPlan() {
    final s = editorStrings;
    for (final y in [0.0, 320.0]) {
      for (final x in [0.0, 390.0]) {
        stile(s.uprightPost, x, y, 0, 90, 20, 900);
      }
      for (final z in [0.0, 810.0]) {
        front(s.frameRail, 90, y, z, 300, 20, 90);
      }
    }
    for (final x in [0.0, 460.0]) {
      for (final z in [0.0, 810.0]) {
        cross(s.frameRail, x, 20, z, 300, 90, 20);
      }
    }
    finish = FinishPreset.plywood.finish;
    flat(s.bottomPanel, 20, 20, 0, 440, 300, 20);
    flat(s.topPanel, 0, 0, 900, 480, 340, 20);
    flat(s.frameRail, 30, 30, 880, 420, 280, 20);
    flat(s.topPanel, 70, 70, 970, 340, 200, 20);
    finish = FinishPreset.wood.finish;
    for (final x in [95.5, 359.5]) {
      for (final y in [95.5, 219.5]) {
        post(x, y, 920, 50, 25);
      }
    }
  }

  void toyChestPlan() {
    final s = editorStrings;
    for (final x in [20.0, 820.0]) {
      for (final y in [20.0, 520.0]) {
        for (var j = 0; j < 2; j++) {
          stile(s.uprightPost, x, y + j * 20, 0, 40, 20, 600);
        }
      }
      cross(s.frameRail, x, 60, 30, 460, 40, 20);
    }
    for (final y in [40.0, 520.0]) {
      front(s.frameRail, 60, y, 30, 760, 20, 40);
    }
    for (var i = 0; i < 5; i++) {
      final z = 90 + i * 105.0;
      for (final y in [20.0, 540.0]) {
        front(s.frontPanel, 60, y, z, 760, 20, 90);
      }
      for (final x in [20.0, 840.0]) {
        cross(s.sidePanel, x, 60, z, 460, 90, 20);
      }
    }
    for (var i = 0; i < 9; i++) {
      add(s.deckBoard, 60 + i * 85, 40, 70, 500, 80, 20, 1, 0);
    }
    for (var i = 0; i < 6; i++) {
      flat(s.topPanel, 20, 20 + i * 92, 600, 840, 90, 20);
    }
    for (final x in [0.0, 860.0]) {
      cross(s.frameRail, x, 20, 600, 550, 20, 20);
    }
    front(s.frameRail, 0, 0, 600, 880, 20, 20);
    for (final x in [65.0, 395.0, 725.0]) {
      cross(s.frameRail, x, 60, 580, 460, 20, 90);
    }
  }
}
