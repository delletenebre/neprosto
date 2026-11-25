part of 'project_templates.dart';

extension _CatalogFurniture on _Parts {
  void diningTablePlan() {
    final s = editorStrings, q = measure;
    final t = q(40, 1.5),
        board = q(140, 5.5),
        leg = q(710, 28.5),
        span = q(500, 20);
    final inset = (d - span - 2 * t) / 2;
    for (var i = 0; i < 5; i++) {
      flat(s.tabletop, 0, i * (board + q(5, 0.375)), leg, w, board, t);
    }
    for (final x in [q(180, 7), w - q(180, 7) - board]) {
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
    final s = editorStrings, q = measure;
    final t = q(18, 0.75);
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

  void bookcasePlan() {
    final s = editorStrings, q = measure;
    for (final x in [0.0, q(920, 35.25)]) {
      for (final y in [0.0, q(308, 11.375)]) {
        side(s.uprightPost, x, y, 0, q(20, 0.75), q(70, 2.625), h);
      }
      for (final top in [
        q(140, 5.25),
        q(700, 26.25),
        q(1260, 47.25),
        q(1800, 68),
      ]) {
        cross(
          s.crossRail(1),
          x,
          q(70, 2.625),
          top - q(40, 1.5),
          q(238, 8.75),
          q(40, 1.5),
          q(20, 0.75),
        );
        cross(
          s.frameRail,
          x == 0 ? q(20, 0.75) : q(880, 33.75),
          0,
          top - q(40, 1.5),
          q(378, 14),
          q(20, 0.75),
          q(40, 1.5),
        );
      }
    }
    for (final top in [
      q(140, 5.25),
      q(700, 26.25),
      q(1260, 47.25),
      q(1800, 68),
    ]) {
      for (var i = 0; i < 4; i++) {
        flat(
          s.shelfPart,
          q(20, 0.75),
          i * (d - q(90, 3.375)) / 3,
          top - q(20, 0.75),
          q(900, 34.5),
          q(90, 3.375),
          q(20, 0.75),
        );
      }
    }
  }

  void machineStandPlan() {
    final s = editorStrings, q = measure;
    for (final x in [0.0, q(760, 28.5)]) {
      for (final y in [0.0, q(510, 19.625)]) {
        side(s.uprightPost, x, y, 0, q(40, 1.5), q(90, 3.375), q(882, 33.25));
      }
      for (final top in [q(100, 3.75), q(882, 33.25)]) {
        cross(
          s.frameRail,
          x,
          q(90, 3.375),
          top - q(90, 3.375),
          q(420, 16.25),
          q(90, 3.375),
          q(40, 1.5),
        );
      }
    }
    for (final top in [q(100, 3.75), q(460, 17.25), q(882, 33.25)]) {
      for (final y in [0.0, q(560, 21.5)]) {
        front(
          s.frameRail,
          q(40, 1.5),
          y,
          top - q(90, 3.375),
          q(720, 27),
          q(40, 1.5),
          q(90, 3.375),
        );
      }
    }
    finish = FinishPreset.plywood.finish;
    flat(s.tabletop, 0, 0, q(882, 33.25), q(800, 30), q(600, 23), q(18, 0.75));
    flat(
      s.shelfPart,
      q(40, 1.5),
      0,
      q(460, 17.25),
      q(720, 27),
      q(600, 23),
      q(18, 0.75),
    );
    // A three-piece lower deck clears the four legs without phantom notches.
    flat(
      s.shelfPart,
      q(40, 1.5),
      0,
      q(100, 3.75),
      q(720, 27),
      q(600, 23),
      q(18, 0.75),
    );
    for (final x in [0.0, q(760, 28.5)]) {
      add(
        s.shelfPart,
        x,
        q(90, 3.375),
        q(100, 3.75),
        q(420, 16.25),
        q(40, 1.5),
        q(18, 0.75),
        1,
        0,
      );
    }
  }

  void coffeeTablePlan() {
    final s = editorStrings, q = measure;
    for (final x in [q(10, 0.375), q(950, 36.125)]) {
      for (final y in [q(10, 0.375), q(350, 13.125)]) {
        post(x, y, 0, q(382, 14.25), q(40, 1.5));
      }
      for (final z in [q(75, 2.8125), q(342, 12.75)]) {
        cross(
          s.frameRail,
          x,
          q(50, 1.875),
          z,
          q(300, 11.25),
          q(40, 1.5),
          q(40, 1.5),
        );
      }
    }
    for (final y in [q(10, 0.375), q(350, 13.125)]) {
      for (final z in [q(75, 2.8125), q(342, 12.75)]) {
        front(
          s.frameRail,
          q(50, 1.875),
          y,
          z,
          q(900, 34.25),
          q(40, 1.5),
          q(40, 1.5),
        );
      }
    }
    // Support the free-fitting lower shelf on cleats below its two long edges.
    for (final y in [q(50, 1.875), q(330, 12.375)]) {
      flat(
        s.frameRail,
        q(50, 1.875),
        y,
        q(77, 2.875),
        q(900, 34.25),
        q(20, 0.75),
        q(20, 0.75),
      );
    }
    finish = FinishPreset.plywood.finish;
    flat(
      s.shelfPart,
      q(51, 1.9375),
      q(51, 1.9375),
      q(97, 3.625),
      q(898, 34.125),
      q(298, 11.125),
      q(18, 0.75),
    );
    flat(s.tabletop, 0, 0, q(382, 14.25), q(1000, 38), q(400, 15), q(18, 0.75));
  }

  void picnicTablePlan() {
    final s = editorStrings, q = measure;
    for (var i = 0; i < 5; i++) {
      flat(
        s.tabletop,
        0,
        q(271, 10.1875) + i * q(102, 3.8125),
        q(416, 15.5),
        q(800, 30),
        q(90, 3.375),
        q(40, 1.5),
      );
    }
    for (final y in [0.0, q(848, 31.8125)]) {
      for (var i = 0; i < 2; i++) {
        flat(
          s.seatSlat(i + 1),
          0,
          y + i * q(102, 3.8125),
          q(220, 8.25),
          q(800, 30),
          q(90, 3.375),
          q(40, 1.5),
        );
      }
    }
    for (final x in [q(60, 2.25), q(700, 26.25)]) {
      cross(
        s.frameRail,
        x,
        q(295, 11.0625),
        q(326, 12.125),
        q(450, 16.875),
        q(90, 3.375),
        q(40, 1.5),
      );
      cross(
        s.frameRail,
        x,
        0,
        q(130, 4.875),
        q(1040, 39),
        q(90, 3.375),
        q(40, 1.5),
      );
      final legX = x == q(60, 2.25) ? q(120, 4.5) : q(680, 25.5);
      for (final sign in [-1, 1]) {
        member(
          s.uprightPost,
          Vector3(
            legX,
            q(520, 19.5) + sign * (q(140, 5.25) + q(416, 15.5) / math.sqrt(3)),
            0,
          ),
          Vector3(legX, q(520, 19.5) + sign * q(140, 5.25), q(416, 15.5)),
          axis(0),
          q(90, 3.375),
          q(40, 1.5),
          startPlane: axis(2),
          endPlane: axis(2),
        );
      }
    }
    front(
      s.frameRail,
      q(100, 3.75),
      q(500, 18.75),
      q(130, 4.875),
      q(600, 22.5),
      q(40, 1.5),
      q(90, 3.375),
    );
  }

  void workbenchPlan() {
    final s = editorStrings, q = measure;
    final stock = q(38, 1.5),
        legWidth = q(100, 4),
        legDepth = q(76, 3),
        legHeight = q(750, 30);
    for (final x in [q(260, 10.5), q(1140, 45.5)]) {
      for (final y in [0.0, d - legDepth]) {
        for (var i = 0; i < 2; i++) {
          stile(s.uprightPost, x, y + i * stock, 0, legWidth, stock, legHeight);
        }
      }
      for (final z in [q(100, 4), q(650, 26)]) {
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
      front(
        s.frameRail,
        q(360, 14.5),
        y,
        q(100, 4),
        q(780, 31),
        stock,
        legWidth,
      );
    }
    for (final y in [0.0, q(322, 13)]) {
      // Eight edge-laminated boards, planed down equally on the two outside faces.
      var edge = y;
      for (var i = 0; i < 8; i++) {
        final t = i == 0 || i == 7 ? q(25, 1) : stock;
        front(s.tabletop, 0, edge, legHeight, w, t, q(100, 4));
        edge += t;
      }
    }
  }

  void shoeBenchPlan() {
    final s = editorStrings, q = measure;
    final t = q(18, 0.75), base = q(50, 1.875), seat = q(410, 15.5);
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
