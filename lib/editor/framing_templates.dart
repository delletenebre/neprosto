part of 'project_templates.dart';

extension _Framing on _Parts {
  void shedFloor() {
    final s = editorStrings,
        bays = (w / measure(400, 16)).ceil(),
        spacing = (w - stud) / bays;
    for (final y in [0.0, d - stud]) {
      front(s.frameRail, 0, y, 0, w, stud, h);
    }
    for (var i = 0; i <= bays; i++) {
      cross(s.floorJoist, i * spacing, stud, 0, d - 2 * stud, h, stud);
      if (i == bays) continue;
      // The two members cross in elevation but are offset in plan.
      for (final sign in [-1, 1]) {
        final y = d / 2 + sign * (stud / 2 + measure(4, .125));
        member(
          s.bridging,
          Vector3(i * spacing + stud, y, sign < 0 ? stud : h - stud),
          Vector3((i + 1) * spacing, y, sign < 0 ? h - stud : stud),
          axis(1),
          stud,
          stud,
          startPlane: axis(0),
          endPlane: axis(0),
        );
      }
    }
  }

  void windowWall() {
    final s = editorStrings,
        sill = measure(880, 34),
        lintel = measure(1980, 77);
    final pitch = measure(400, 16), left = pitch + stud, right = w - left;
    for (final z in [0.0, h - 2 * stud, h - stud]) {
      flat(s.frameRail, 0, 0, z, w, d, stud);
    }
    void upright(double x, double base, double top) =>
        side(s.uprightPost, x, 0, base, stud, d, top - base);
    for (final x in [0.0, left - stud, right, w - stud]) {
      upright(x, stud, h - 2 * stud);
    }
    for (final x in [left, right - stud]) {
      upright(x, stud, lintel);
    }
    for (final y in [0.0, d - stud]) {
      front(s.headerBeam, left, y, lintel, right - left, stud, plank);
    }
    flat(s.windowSill, left + stud, 0, sill, right - left - 2 * stud, d, stud);
    for (var x = pitch * 2; x < right - stud; x += pitch) {
      upright(x, stud, sill);
      upright(x, lintel + plank, h - 2 * stud);
    }
  }

  void cornerWalls() {
    final s = editorStrings, depth = plank;
    for (final z in [0.0, h - 2 * stud]) {
      flat(s.frameRail, 0, 0, z, w, depth, stud);
      add(s.frameRail, 0, depth, z, d - depth, depth, stud, 1, 0);
    }
    // Lap the cap over the perpendicular wall at the corner.
    flat(s.frameRail, depth, 0, h - stud, w - depth, depth, stud);
    add(s.frameRail, 0, 0, h - stud, d, depth, stud, 1, 0);
    final top = h - 3 * stud;
    final nx = (w / measure(400, 16)).ceil(),
        ny = ((d - depth) / measure(400, 16)).ceil();
    for (var i = 0; i <= nx; i++) {
      side(s.uprightPost, i * (w - stud) / nx, 0, stud, stud, depth, top);
    }
    side(s.uprightPost, depth - stud, 0, stud, stud, depth, top);
    for (var i = 0; i <= ny; i++) {
      add(
        s.uprightPost,
        0,
        depth + i * (d - depth - stud) / ny,
        stud,
        top,
        depth,
        stud,
        2,
        0,
      );
    }
  }

  void panelDoor() {
    final s = editorStrings, middle = h * .45;
    for (final x in [0.0, w - board]) {
      add(s.doorStile, x, 0, 0, h, board, d, 2, 0);
    }
    for (final (z, rail) in [
      (0.0, plank),
      (middle, board),
      (h - board, board),
    ]) {
      front(s.frameRail, board, 0, z, w - 2 * board, d, rail);
    }
    for (final (z, top) in [(plank, middle), (middle + board, h - board)]) {
      for (var i = 0; i < 7; i++) {
        add(
          s.doorPanelInfill,
          board + i * board,
          (d - skin) / 2,
          z,
          top - z,
          board,
          skin,
          2,
          0,
        );
      }
    }
  }

  void gardenGate() {
    final s = editorStrings, lower = board, upper = h - 2.25 * board;
    for (final z in [lower, upper]) {
      front(s.frameRail, 0, 0, z, w, stud, board);
    }
    final n = 9;
    for (var i = 0; i < n; i++) {
      final height = h - board * ((i - 4) / 4) * ((i - 4) / 4);
      add(
        s.gatePicket,
        i * (w - board) / (n - 1),
        stud,
        0,
        height,
        board,
        skin,
        2,
        0,
      );
    }
    member(
      s.bridging,
      Vector3(board, stud / 2, lower + board),
      Vector3(w - board, stud / 2, upper),
      axis(1),
      board,
      stud,
      startPlane: axis(2),
      endPlane: axis(2),
    );
  }

  void gazebo() {
    final s = editorStrings,
        ringTop = measure(2260, 89),
        beamBase = ringTop - plank;
    for (final y in [0.0, d - heavy]) {
      for (final x in [0.0, w - heavy]) {
        post(x, y, 0, beamBase, heavy);
      }
    }

    // Both directions bear on the post tops. The side beams use the part
    // of each post left behind the front and back beams.
    for (final y in [0.0, d - stud]) {
      front(s.gazeboRingBeam, 0, y, beamBase, w, stud, plank);
    }
    final reach = measure(330, 13);
    for (final x in [0.0, w - stud]) {
      cross(s.gazeboRingBeam, x, stud, beamBase, d - 2 * stud, plank, stud);
      for (final front in [true, false]) {
        final edge = front ? heavy : d - heavy;
        member(
          s.bridging,
          Vector3(x + stud / 2, edge, beamBase - reach),
          Vector3(x + stud / 2, edge + (front ? reach : -reach), beamBase),
          axis(0),
          board,
          stud,
          startPlane: axis(1),
          endPlane: axis(2),
        );
      }
      final edge = x == 0 ? heavy : w - heavy;
      member(
        s.bridging,
        Vector3(edge, d - stud / 2, beamBase - reach),
        Vector3(edge + (x == 0 ? reach : -reach), d - stud / 2, beamBase),
        axis(1),
        board,
        stud,
        startPlane: axis(0),
        endPlane: axis(2),
      );
    }

    // The bench shares the rear posts. Its seat bearers span the front rail
    // and the ledger on the face of the posts.
    final seat = measure(450, 18), gap = measure(6, .25);
    final span = w - 2 * skin, rear = d - heavy;
    final seatFront = rear - stud - skin - 3 * plank - 2 * gap;
    final railZ = seat - skin - stud - board;
    final backTop = seat + measure(410, 16);
    post((w - heavy) / 2, rear, 0, backTop, heavy);
    for (final (i, x) in [skin, (w - board) / 2, w - skin - board].indexed) {
      add(s.leg(i + 1), x, seatFront + skin, 0, railZ, board, stud, 2, 0);
    }
    for (final y in [seatFront + skin, rear - stud]) {
      front(s.frameRail, skin, y, railZ, span, stud, board);
    }
    front(
      s.frontPanel,
      skin,
      seatFront,
      seat - skin - board,
      span,
      skin,
      board,
    );
    for (var i = 0; i < 5; i++) {
      final x = skin + i * (span - board) / 4;
      add(
        s.frameRail,
        x,
        seatFront + skin,
        seat - skin - stud,
        rear - seatFront - skin,
        board,
        stud,
        1,
        0,
      );
    }
    for (var i = 0; i < 3; i++) {
      flat(
        s.seatSlat(i + 1),
        skin,
        seatFront + i * (plank + gap),
        seat - skin,
        span,
        plank,
        skin,
      );
    }

    final backBase = seat + measure(55, 2);
    for (final z in [backBase, backTop - board]) {
      front(s.frameRail, skin, rear - stud, z, span, stud, board);
    }
    final count = (span / (board + measure(30, 1.25))).round();
    for (var i = 0; i < count; i++) {
      final x = skin + i * (span - board) / (count - 1);
      add(
        s.benchBack,
        x,
        rear - stud - skin,
        backBase,
        backTop - backBase,
        board,
        skin,
        2,
        0,
      );
    }
    gazeboRoof(ringTop);
  }

  void gazeboRoof(double ringTop) {
    final s = editorStrings, half = w / 2, heel = ringTop + board;
    final pitch = (h - heel) / half, gain = math.sqrt(1 + pitch * pitch);
    // The top edge runs from the outer end of the tie to the ridge.
    // The horizontal heel cut bears on the tie; the ridge cut is plumb.
    final heelRun = board * gain / (2 * pitch);
    final ridgeCentreZ = h - board * gain / 2;
    for (var i = 0; i < 5; i++) {
      final y = i * (d - stud) / 4;
      front(s.roofTie, 0, y, ringTop, w, stud, board);
      for (final x in [heelRun, w - heelRun]) {
        member(
          s.roofRafter,
          Vector3(x, y + stud / 2, heel),
          Vector3(half, y + stud / 2, ridgeCentreZ),
          axis(1),
          board,
          stud,
          startPlane: axis(2),
          endPlane: axis(0),
        );
      }
    }

    // Lay the wide face of each batten on all five rafters of its slope.
    final first = (stud + board / 2) / gain;
    final last = half - (measure(100, 4) + board / 2) / gain;
    for (final sign in [1.0, -1.0]) {
      final normal = Vector3(-sign * pitch, 0, 1) / gain;
      for (var i = 0; i < 4; i++) {
        final run = first + i * (last - first) / 3;
        final x = sign > 0 ? run : w - run;
        final start = Vector3(x, 0, heel + pitch * run) + normal * (stud / 2);
        member(s.roofBatten, start, start + axis(1) * d, normal, board, stud);
      }
    }
  }
}
