part of 'project_templates.dart';

extension _CatalogFurniture on _Parts {
  void laptopTrayPlan() {
    final s = editorStrings;
    // The published cut lengths add up to 566 mm. Straight frame tops sit
    // level; the optional splay in the source is omitted in this version.
    for (final (x, length) in [(0.0, 102.0), (102.0, 362.0), (464.0, 102.0)]) {
      flat(s.tabletop, x, 0, 236, length, d, 19);
    }
    for (final x in [32.0, w - 51]) {
      for (final z in [0.0, 172.0]) {
        cross(s.frameRail, x, 5, z, 276, 64, 19);
      }
      for (final y in [5.0, 192.0]) {
        side(s.uprightPost, x, y, 64, 19, 89, 108);
      }
    }
  }

  void diningTablePlan() {
    final s = editorStrings;
    const t = 38.1, board = 139.7, leg = 711.2, span = 508.0;
    final inset = (d - span - 2 * t) / 2;
    for (var i = 0; i < 5; i++) {
      flat(s.tabletop, 0, i * (board + 5.08), leg, w, board, t);
    }
    for (final x in [180.0, w - 180 - board]) {
      for (final y in [inset, inset + t + span]) {
        stile(s.uprightPost, x, y, 0, board, t, leg);
      }
      for (final z in [0.0, leg - t]) {
        cross(s.frameRail, x, inset + t, z, span, t, board);
      }
      cross(
        s.frameRail,
        x + (board - t) / 2,
        inset + t,
        leg - t - board,
        span,
        board,
        t,
      );
    }
  }

  void consoleTablePlan() {
    final s = editorStrings;
    const t = 19.05;
    final bay = (w - 4 * t) / 3;
    for (final x in [0.0, w - t]) {
      side(s.sidePanel, x, 0, 0, t, d, h);
    }
    for (final z in [0.0, h - t]) {
      flat(z == 0 ? s.bottomPanel : s.topPanel, t, 0, z, w - 2 * t, d, t);
    }
    for (var i = 0; i < 3; i++) {
      final x = t + i * (bay + t);
      flat(s.shelfPart, x, 0, (h - t) / 2, bay, d, t);
      if (i < 2) {
        side(s.dividerPanel, x + bay, 0, t, t, d, h - 2 * t);
      }
    }
  }

  void stoolPlan() {
    final s = editorStrings;
    for (final x in [0.0, 382.0]) {
      side(s.sidePanel, x, 0, 0, 18, 300, 500);
    }
    flat(s.seatPanel, 0, 0, 500, 400, 300, 18);
    front(s.frameRail, 18, 141, 440, 364, 18, 60);
    flat(s.shelfPart, 18, 75, 50, 364, 150, 18);
    add(s.bottomPanel, 400, 0, 0, 300, 150, 18, 1, 0);
    add(s.sidePanel, 550, 0, 0, 300, 150, 18, 1, 2);
    for (final y in [0.0, 240.0]) {
      flat(s.frameRail, 400, y, 18, 150, 60, 18);
    }
  }

  void trestleBenchPlan() {
    final s = editorStrings;
    const angle = math.pi / 12, board = 38.0;
    final top = h - board;
    final spread = top * math.tan(angle);
    flat(s.seatPanel, 0, 0, top, w, d, board);
    for (final sign in [-1, 1]) {
      final x = w / 2 + sign * (813 / 2 + board / (2 * math.cos(angle)));
      final start = Vector3(x + sign * spread, d / 2, 0);
      final end = Vector3(x, d / 2, top);
      member(
        s.uprightPost,
        start,
        end,
        (end - start).normalized().cross(axis(1)),
        d,
        board,
        startPlane: axis(2),
        endPlane: axis(2),
      );
    }
    // Rails meet the inside faces of the splayed legs along their entire ends.
    final inset = (w - 813) / 2;
    for (final y in [19.0, d - 19]) {
      profileBoard(
        s.frameRail,
        Vector3(inset, y, top),
        Vector3(w - inset, y, top),
        Vector3(inset - 89 * math.tan(angle), y, top - 89),
        Vector3(w - inset + 89 * math.tan(angle), y, top - 89),
        board,
      );
    }
  }

  void bookcasePlan() {
    final s = editorStrings;
    for (final x in [0.0, 920.0]) {
      for (final y in [0.0, 308.0]) {
        side(s.uprightPost, x, y, 0, 20, 70, h);
      }
      for (final top in [140.0, 700.0, 1260.0, 1800.0]) {
        cross(s.crossRail(1), x, 70, top - 40, 238, 40, 20);
        cross(s.frameRail, x == 0 ? 20 : 880, 0, top - 40, 378, 20, 40);
      }
    }
    for (final top in [140.0, 700.0, 1260.0, 1800.0]) {
      for (var i = 0; i < 4; i++) {
        flat(s.shelfPart, 20, i * 96, top - 20, 900, 90, 20);
      }
    }
  }

  void machineStandPlan() {
    final s = editorStrings;
    for (final x in [0.0, 760.0]) {
      for (final y in [0.0, 510.0]) {
        side(s.uprightPost, x, y, 0, 40, 90, 882);
      }
      for (final top in [100.0, 882.0]) {
        cross(s.frameRail, x, 90, top - 90, 420, 90, 40);
      }
    }
    for (final top in [100.0, 460.0, 882.0]) {
      for (final y in [0.0, 560.0]) {
        front(s.frameRail, 40, y, top - 90, 720, 40, 90);
      }
    }
    finish = FinishPreset.plywood.finish;
    flat(s.tabletop, 0, 0, 882, 800, 600, 18);
    flat(s.shelfPart, 40, 0, 460, 720, 600, 18);
    // A three-piece lower deck clears the four legs without phantom notches.
    flat(s.shelfPart, 40, 0, 100, 720, 600, 18);
    for (final x in [0.0, 760.0]) {
      add(s.shelfPart, x, 90, 100, 420, 40, 18, 1, 0);
    }
  }

  void coffeeTablePlan() {
    final s = editorStrings;
    for (final x in [10.0, 950.0]) {
      for (final y in [10.0, 350.0]) {
        post(x, y, 0, 382, 40);
      }
      for (final z in [75.0, 342.0]) {
        cross(s.frameRail, x, 50, z, 300, 40, 40);
      }
    }
    for (final y in [10.0, 350.0]) {
      for (final z in [75.0, 342.0]) {
        front(s.frameRail, 50, y, z, 900, 40, 40);
      }
    }
    // Support the free-fitting lower shelf on cleats below its two long edges.
    for (final y in [50.0, 330.0]) {
      flat(s.frameRail, 50, y, 77, 900, 20, 20);
    }
    finish = FinishPreset.plywood.finish;
    flat(s.shelfPart, 51, 51, 97, 898, 298, 18);
    flat(s.tabletop, 0, 0, 382, 1000, 400, 18);
  }

  void picnicTablePlan() {
    final s = editorStrings;
    for (var i = 0; i < 5; i++) {
      flat(s.tabletop, 0, 271 + i * 102, 416, 800, 90, 40);
    }
    for (final y in [0.0, 848.0]) {
      for (var i = 0; i < 2; i++) {
        flat(s.seatSlat(i + 1), 0, y + i * 102, 220, 800, 90, 40);
      }
    }
    for (final x in [60.0, 700.0]) {
      cross(s.frameRail, x, 295, 326, 450, 90, 40);
      cross(s.frameRail, x, 0, 130, 1040, 90, 40);
      final legX = x == 60 ? 120.0 : 680.0;
      for (final sign in [-1, 1]) {
        member(
          s.uprightPost,
          Vector3(legX, 520 + sign * (140 + 416 / math.sqrt(3)), 0),
          Vector3(legX, 520 + sign * 140, 416),
          axis(0),
          90,
          40,
          startPlane: axis(2),
          endPlane: axis(2),
        );
      }
    }
    front(s.frameRail, 100, 500, 130, 600, 40, 90);
  }

  void gardenBenchPlan() {
    final s = editorStrings;
    for (final x in [0.0, 1590.0]) {
      for (final y in [20.0, 590.0]) {
        post(x, y, 0, 600, 90);
      }
      cross(s.landingRail, x, 0, 600, 700, 40, 90);
      cross(s.frameRail, x + 25, 110, 340, 480, 90, 40);
    }
    for (final y in [20.0, 640.0]) {
      front(s.frameRail, 90, y, 340, 1500, 40, 90);
    }
    for (final x in [370.0, 820.0, 1270.0]) {
      cross(s.frameRail, x, 60, 340, 580, 90, 40);
    }
    for (var i = 0; i < 7; i++) {
      final end = i == 0 || i == 6;
      flat(
        s.seatSlat(i + 1),
        end ? 90 : 0,
        20 + i * 95,
        430,
        end ? 1500 : 1680,
        90,
        40,
      );
    }
    // The back is assembled between the armrests. Trim its rail ends to
    // seat on the deck; the slats follow the same 15-degree rake.
    const angle = math.pi / 12;
    final along = Vector3(0, math.sin(angle), math.cos(angle));
    final normal = Vector3(0, -math.cos(angle), math.sin(angle));
    final base = Vector3(0, 510, 470);
    final span = (h - base.z - 40 * normal.z) / along.z;
    // Upper and lower rails run between the two full-height end stiles.
    // Inner stiles stop at the rails. The lower rail sits above the seat.
    for (final x in [90.0, 1550.0]) {
      final a = base + Vector3(x + 20, 0, 0) - normal * 20;
      final foot = a + along * ((470 - a.z) / along.z);
      member(
        s.uprightPost,
        foot,
        a + along * span,
        axis(0),
        40,
        40,
        startPlane: axis(2),
      );
    }
    const bottomRail = 12.0;
    for (final z in [bottomRail, span - 40]) {
      beams.add(
        Beam(
          beams.length + 1,
          s.frameRail,
          base + Vector3(130, 0, 0) + along * z - normal * 40,
          Vector3(1420, 40, 40),
          axis(0),
          along,
          finish: finish,
        ),
      );
    }
    for (final x in [590.0, 1050.0]) {
      final centre = base + Vector3(x + 20, 0, 0) - normal * 20;
      member(
        s.uprightPost,
        centre + along * (bottomRail + 40),
        centre + along * (span - 40),
        axis(0),
        40,
        40,
      );
    }
    for (var i = 0; i < 5; i++) {
      final end = i < 2;
      final start = base + along * (span - 90 - (4 - i) * 95);
      beams.add(
        Beam(
          beams.length + 1,
          s.benchBack,
          start + Vector3(end ? 90 : 0, 0, 0),
          Vector3(end ? 1500 : 1680, 90, 40),
          axis(0),
          along,
          finish: finish,
        ),
      );
    }
  }

  void workbenchPlan() {
    final s = editorStrings;
    const stock = 38.1, legWidth = 101.6, legDepth = 76.2, legHeight = 762.0;
    for (final x in [266.7, 1155.7]) {
      for (final y in [0.0, d - legDepth]) {
        for (var i = 0; i < 2; i++) {
          stile(s.uprightPost, x, y + i * stock, 0, legWidth, stock, legHeight);
        }
      }
      for (final z in [101.6, 660.4]) {
        cross(
          s.frameRail,
          x + (legWidth - stock) / 2,
          legDepth,
          z,
          d - 2 * legDepth,
          legWidth,
          stock,
        );
      }
    }
    for (final y in [0.0, d - stock]) {
      front(s.frameRail, 368.3, y, 101.6, 787.4, stock, legWidth);
    }
    for (final y in [0.0, 330.2]) {
      // Eight edge-laminated boards, planed down equally on the two outside faces.
      var edge = y;
      for (var i = 0; i < 8; i++) {
        final t = i == 0 || i == 7 ? 25.4 : stock;
        front(s.tabletop, 0, edge, legHeight, w, t, 101.6);
        edge += t;
      }
    }
  }

  void shoeBenchPlan() {
    final s = editorStrings;
    const t = 18.0, base = 50.0, seat = 410.0;
    for (final x in [0.0, w - t]) {
      side(s.frameRail, x, t, 0, t, d - 2 * t, base);
      side(s.sidePanel, x, t, base + t, t, d - 2 * t, seat - base - 2 * t);
      side(s.frameRail, x, t, seat, t, d - 2 * t, h - seat);
    }
    for (final y in [0.0, d - t]) {
      front(s.frameRail, 0, y, 0, w, t, base);
    }
    flat(s.bottomPanel, 0, t, base, w, d - 2 * t, t);
    for (var i = 1; i < 3; i++) {
      side(
        s.dividerPanel,
        i * (w - t) / 3,
        t,
        base + t,
        t,
        d - 2 * t,
        seat - base - 2 * t,
      );
    }
    front(s.backPanel, 0, d - t, base, w, t, seat - base);
    flat(s.seatPanel, 0, 0, seat - t, w, d - t, t);
    front(s.frameRail, 0, d - t, seat, w, t, h - seat);
  }
}
