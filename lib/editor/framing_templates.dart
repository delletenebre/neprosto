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
        rise = measure(480, 19),
        mid = d / 2,
        pitch = rise / mid;
    final gain = math.sqrt(1 + pitch * pitch), inset = measure(150, 6);
    final eave = h - rise, cover = skin + stud;
    final tieTop = eave - (cover + plank) * gain;
    final plateTop = tieTop - plank;
    double roof(double y) => h - (y - mid).abs() * pitch;
    final seat = measure(450, 18), clearWidth = w - 2 * (inset + heavy);
    final back = d - inset - heavy,
        seatDepth = 4 * board + 3 * measure(5, .1875);
    for (final z in [measure(670, 26), measure(940, 37)]) {
      front(s.benchBack, inset + heavy, back, z, clearWidth, skin, board);
      for (final x in [inset, w - inset - stud]) {
        cross(
          s.frameRail,
          x,
          inset + heavy,
          z,
          d - 2 * (inset + heavy),
          board,
          stud,
        );
      }
    }
    for (var i = 0; i < 4; i++) {
      flat(
        s.seatSlat(i + 1),
        inset + heavy,
        back - seatDepth + i * (seatDepth - board) / 3,
        seat - skin,
        clearWidth,
        board,
        skin,
      );
    }
    front(
      s.frameRail,
      inset + heavy,
      back,
      seat - skin - board,
      clearWidth,
      stud,
      board,
    );
    for (final x in [inset + heavy, (w - stud) / 2, w - inset - heavy - stud]) {
      cross(
        s.frameRail,
        x,
        back - seatDepth,
        seat - skin - board,
        seatDepth,
        board,
        stud,
      );
      post(x, back - seatDepth, 0, seat - skin - board, stud);
    }
    for (final y in [inset, d - inset - heavy]) {
      front(
        s.frameRail,
        inset,
        y,
        plateTop - plank,
        w - 2 * inset,
        heavy,
        plank,
      );
      for (final x in [inset, w - inset - heavy]) {
        post(x, y, 0, plateTop - plank, heavy);
        final left = x == inset, face = left ? x + heavy : x;
        final reach = measure(320, 12), cy = y + heavy / 2;
        member(
          s.bridging,
          Vector3(face, cy, plateTop - plank - reach),
          Vector3(face + (left ? reach : -reach), cy, plateTop - plank),
          axis(1),
          board,
          stud,
          startPlane: axis(0),
          endPlane: axis(2),
        );
      }
    }
    final ridgeTop = roof(mid - stud / 2) - cover * gain;
    front(s.ridgeBeam, 0, mid - stud / 2, ridgeTop - plank, w, stud, plank);
    for (var i = 0; i < 5; i++) {
      final cx = inset + heavy / 2 + i * (w - 2 * inset - heavy) / 4;
      cross(
        s.roofTie,
        cx - stud / 2,
        inset,
        plateTop,
        d - 2 * inset,
        plank,
        stud,
      );
      post(
        cx - stud / 2,
        mid - stud / 2,
        tieTop,
        ridgeTop - plank - tieTop,
        stud,
      );
      for (final side in [0, 1]) {
        final y0 = side == 0 ? 0.0 : mid + stud / 2,
            y1 = side == 0 ? mid - stud / 2 : d;
        final drop = (cover + plank / 2) * gain;
        member(
          s.roofRafter,
          Vector3(cx, y0, roof(y0) - drop),
          Vector3(cx, y1, roof(y1) - drop),
          axis(0),
          plank,
          stud,
          startPlane: axis(1),
          endPlane: axis(1),
        );
        final cy = side == 0 ? inset + heavy / 2 : d - inset - heavy / 2;
        final normal = Vector3(0, side == 0 ? -pitch : pitch, 1).normalized();
        member(
          s.uprightPost,
          Vector3(cx, cy, tieTop),
          Vector3(cx, cy, roof(cy) - (cover + plank) * gain),
          axis(0),
          heavy,
          stud,
          startPlane: axis(2),
          endPlane: normal,
        );
        if (i == 0 || i == 4) {
          final face = side == 0 ? inset + heavy : d - inset - heavy,
              reach = measure(300, 12);
          member(
            s.bridging,
            Vector3(cx, face, plateTop - reach),
            Vector3(cx, face + (side == 0 ? reach : -reach), plateTop),
            axis(0),
            board,
            stud,
            startPlane: axis(1),
            endPlane: axis(2),
          );
        }
      }
    }
    for (final side in [0, 1]) {
      final tangent = Vector3(0, 1 / gain, (side == 0 ? pitch : -pitch) / gain);
      final normal = axis(0).cross(tangent);
      for (var i = 0; i < 4; i++) {
        final y = side * mid + board + i * (mid - 2 * board) / 3;
        beams.add(
          Beam(
            beams.length + 1,
            s.frameRail,
            Vector3(0, y, roof(y)) - normal * cover - tangent * (board / 2),
            Vector3(w, board, stud),
            axis(0),
            tangent,
          ),
        );
      }
      for (var i = 0; i < 16; i++) {
        roofStrip(
          i * plank,
          plank,
          side * mid,
          (side + 1) * mid,
          roof(side * mid),
          roof((side + 1) * mid),
        );
      }
    }
  }
}
