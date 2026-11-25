part of 'project_templates.dart';

extension _CatalogHome on _Parts {
  void pantryShelfPlan() {
    final s = editorStrings, q = measure;
    for (final x in [0.0, w - q(19, 0.75)]) {
      side(s.sidePanel, x, q(13, 0.5), 0, q(19, 0.75), q(89, 3.5), h);
    }
    for (final z in [
      0.0,
      q(451, 17.75),
      q(749, 29.5),
      q(997, 39.25),
      q(1245, 49),
      q(1493, 58.75),
      q(1759, 69.25),
    ]) {
      flat(
        s.shelfPart,
        q(19, 0.75),
        q(13, 0.5),
        z,
        q(648, 25.5),
        q(89, 3.5),
        q(19, 0.75),
      );
    }
    for (final z in [
      q(60, 2.375),
      q(240, 9.4375),
      q(510, 20.0625),
      q(650, 25.5625),
      q(810, 31.875),
      q(1058, 41.625),
      q(1306, 51.4375),
      q(1554, 61.1875),
    ]) {
      front(s.frontPanel, 0, 0, z, w, q(13, 0.5), q(25, 1));
    }
  }

  void wallShelfPlan() {
    final s = editorStrings, q = measure;
    finish = FinishPreset.wood.finish;
    front(
      s.frameRail,
      q(6, 0.25),
      q(260, 10.5),
      q(6, 0.25),
      q(1188, 44.5),
      q(40, 1.5),
      q(90, 3.5),
    );
    for (var i = 0; i < 5; i++) {
      cross(
        s.crossRail(i + 1),
        q(6, 0.25) + q(287, 10.75) * i,
        q(6, 0.25),
        q(6, 0.25),
        q(254, 10.25),
        q(90, 3.5),
        q(40, 1.5),
      );
    }
    finish = FinishPreset.plywood.finish;
    for (final z in [0.0, q(96, 3.75)]) {
      flat(
        s.shelfPart,
        q(6, 0.25),
        q(6, 0.25),
        z,
        q(1188, 44.5),
        q(294, 11.75),
        q(6, 0.25),
      );
    }
    for (final x in [0.0, q(1194, 44.75)]) {
      add(
        s.sidePanel,
        x,
        q(6, 0.25),
        0,
        q(294, 11.75),
        q(102, 4),
        q(6, 0.25),
        1,
        2,
      );
    }
    front(s.frontPanel, 0, 0, 0, q(1200, 45), q(6, 0.25), q(102, 4));
  }

  void blanketLadderPlan() {
    final s = editorStrings, q = measure;
    for (final x in [0.0, q(490, 18)]) {
      post(x, 0, 0, h, q(40, 2));
    }
    for (var i = 0; i < 5; i++) {
      front(
        s.crossRail(i + 1),
        q(40, 2),
        0,
        q(300, 11.25) + i * q(340, 12.75),
        q(450, 16),
        q(40, 2),
        q(40, 2),
      );
    }
  }

  void birdhousePlan() {
    final s = editorStrings, q = measure;
    final slope = w / (2 * h);
    final inset = q(20, 0.75) * math.sqrt(1 + slope * slope);
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
    final t = q(20, .75), frontY = q(30, 1.125);
    final floorStart = frontY + t / 2, floorEnd = d - t;
    for (final y in [frontY, d - t / 2]) {
      profileBoard(
        s.sidePanel,
        Vector3(left(0), y, 0),
        Vector3(w - left(0), y, 0),
        Vector3(left(q(147, 5.5)), y, q(147, 5.5)),
        Vector3(w - left(q(147, 5.5)), y, q(147, 5.5)),
        q(20, 0.75),
      );
    }
    profileBoard(
      s.bottomPanel,
      Vector3(left(0), (floorStart + floorEnd) / 2, 0),
      Vector3(w - left(0), (floorStart + floorEnd) / 2, 0),
      Vector3(left(q(20, 0.75)), (floorStart + floorEnd) / 2, q(20, 0.75)),
      Vector3(w - left(q(20, 0.75)), (floorStart + floorEnd) / 2, q(20, 0.75)),
      floorEnd - floorStart,
      depthIsStockWidth: true,
    );
  }

  void mirrorFramePlan() {
    final s = editorStrings, q = measure;
    for (final x in [0.0, q(448, 18.5)]) {
      post(x, 0, 0, q(1727, 68), q(38, 1.5));
      // Two edge-glued pieces form each stand-off, with a 10-degree wall face.
      for (var i = 0; i < 2; i++) {
        final a = Vector3(
          x + q(19, 0.75),
          q(38, 1.5),
          q(1549, 61) + i * q(38, 1.5),
        );
        final b = Vector3(
          x + q(19, 0.75),
          q(190, 8) - (i + .5) * q(38, 1.5) * math.tan(math.pi / 18),
          a.z,
        );
        member(
          s.frameRail,
          a,
          b,
          axis(0),
          q(38, 1.5),
          q(19, 0.75),
          startPlane: axis(1),
          endPlane: Vector3(0, 1, math.tan(math.pi / 18)),
        );
      }
    }
    for (final z in [q(114, 4.5), q(597, 23.5), q(1080, 42.5), q(1562, 61.5)]) {
      front(
        s.frameRail,
        q(38, 1.5),
        q(13, 0.5),
        z,
        q(410, 17),
        q(19, 0.75),
        q(38, 1.5),
      );
    }
    flat(
      s.shelfPart,
      q(38, 1.5),
      q(10, 0.375),
      q(108, 4.25),
      q(410, 17),
      q(22, 0.875),
      q(6, 0.25),
    );
  }

  Project toyChestPlan() {
    final s = editorStrings, q = measure;
    for (final x in [q(20, 0.75), q(820, 30.75)]) {
      for (final y in [q(20, 0.75), q(520, 20.25)]) {
        for (var j = 0; j < 2; j++) {
          stile(
            s.uprightPost,
            x,
            y + j * q(20, 0.75),
            0,
            q(40, 1.5),
            q(20, 0.75),
            q(600, 23.25),
          );
        }
      }
      cross(
        s.frameRail,
        x,
        q(60, 2.25),
        q(30, 1.125),
        q(460, 18),
        q(40, 1.5),
        q(20, 0.75),
      );
    }
    for (final y in [q(40, 1.5), q(520, 20.25)]) {
      front(
        s.frameRail,
        q(60, 2.25),
        y,
        q(30, 1.125),
        q(760, 28.5),
        q(20, 0.75),
        q(40, 1.5),
      );
    }
    for (var i = 0; i < 5; i++) {
      final board = q(90, 3.375);
      final z = board + i * (h - q(20, .75) - 2 * board) / 4;
      for (final y in [q(20, 0.75), q(540, 21)]) {
        front(
          s.frontPanel,
          q(60, 2.25),
          y,
          z,
          q(760, 28.5),
          i == 4 && y > d / 2 ? d - y : q(20, 0.75),
          q(90, 3.375),
        );
      }
      for (final x in [q(20, 0.75), q(840, 31.5)]) {
        cross(
          s.sidePanel,
          x,
          q(60, 2.25),
          z,
          q(460, 18),
          q(90, 3.375),
          q(20, 0.75),
        );
      }
    }
    for (var i = 0; i < 9; i++) {
      add(
        s.deckBoard,
        q(60, 2.25) + i * q(85, 3.1875),
        q(40, 1.5),
        q(70, 2.625),
        q(500, 19.5),
        q(80, 3),
        q(20, 0.75),
        1,
        0,
      );
    }
    final lidStart = beams.length;
    for (var i = 0; i < 6; i++) {
      flat(
        s.topPanel,
        q(20, 0.75),
        q(20, .75) + i * (d - q(20, .75) - q(90, 3.375)) / 5,
        q(600, 23.25),
        q(840, 31.5),
        q(90, 3.375),
        q(20, 0.75),
      );
    }
    for (final x in [0.0, q(860, 32.25)]) {
      cross(
        s.frameRail,
        x,
        q(20, 0.75),
        q(600, 23.25),
        q(550, 21.25),
        q(20, 0.75),
        q(20, 0.75),
      );
    }
    front(
      s.frameRail,
      0,
      0,
      q(600, 23.25),
      q(880, 33),
      q(20, 0.75),
      q(20, 0.75),
    );
    for (final x in [q(65, 2.4375), q(395, 14.8125), q(725, 27.1875)]) {
      cross(
        s.frameRail,
        x,
        q(60, 2.25),
        q(580, 22.5),
        q(460, 18),
        q(20, 0.75),
        q(90, 3.375),
      );
    }
    const lid = 1;
    for (var i = lidStart; i < beams.length; i++) {
      beams[i] = beams[i].copy(group: lid);
    }
    return Project(template.title, beams, const [], unit).copy(
      groupNames: {lid: s.chestLid},
      groupDoors: {lid: GroupDoor(DoorHinge.top, axis(0), axis(1))},
    );
  }
}
