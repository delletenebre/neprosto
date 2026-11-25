part of 'project_templates.dart';

extension _Timber on _Parts {
  double get board => measure(90, 3.5);
  double get plank => measure(140, 5.5);
  double get skin => measure(20, .75);
  double get stud => measure(40, 1.5);
  double get heavy => measure(90, 3.5);

  void post(double x, double y, double z, double height, double section) =>
      add(editorStrings.uprightPost, x, y, z, height, section, section, 2, 0);
  void cross(
    String name,
    double x,
    double y,
    double z,
    double length,
    double depth,
    double thick,
  ) => add(name, x, y, z, length, depth, thick, 1, 2);

  // Endpoints are centres of the finished end faces. A plane normal specifies
  // the actual saw cut at that end, e.g. horizontal feet on a splayed leg.
  void member(
    String name,
    Vector3 a,
    Vector3 b,
    Vector3 faceNormal,
    double width,
    double thick, {
    Vector3? startPlane,
    Vector3? endPlane,
  }) {
    final delta = b - a,
        along = delta.normalized(),
        across = faceNormal.cross(along).normalized();
    final normal = along.cross(across);
    ({double y, double z}) cut(Vector3? plane) {
      if (plane == null) return (y: 0, z: 0);
      final divisor = along.dot(plane);
      return (
        y: -width * across.dot(plane) / divisor,
        z: -thick * normal.dot(plane) / divisor,
      );
    }

    beams.add(
      Beam(
        beams.length + 1,
        name,
        a - across * (width / 2) - normal * (thick / 2),
        Vector3(delta.length, width, thick),
        along,
        across,
        finish: finish,
        startCut: cut(startPlane),
        endCut: cut(endPlane),
      ),
    );
  }

  void sawhorse() {
    final s = editorStrings, inset = board, headZ = h - skin;
    flat(s.topPanel, 0, (d - plank) / 2, headZ, w, plank, skin);

    // The outside face of each leg runs from the footprint to the cap.
    // Leave room under the cap for the two aprons on those same faces.
    final nearHead = (d - plank) / 2 + skin + measure(4, .125);
    final slope = nearHead / headZ, gain = math.sqrt(1 + slope * slope);
    final halfFoot = stud * gain / 2;
    for (final (i, sign) in [-1.0, 1.0].indexed) {
      final outward = Vector3(0, sign / gain, slope / gain);
      final uphill = Vector3(0, -sign * slope / gain, 1 / gain);
      final outsideFoot = sign < 0 ? 0.0 : d;
      final foot = outsideFoot - sign * halfFoot;
      final head = foot - sign * nearHead;
      for (final (j, x) in [inset + board / 2, w - inset - board / 2].indexed) {
        member(
          s.leg(2 * j + i + 1),
          Vector3(x, foot, 0),
          Vector3(x, head, headZ),
          outward,
          board,
          stud,
          startPlane: axis(2),
          endPlane: axis(2),
        );
      }
      // The inner face of the apron bears against both legs; its highest
      // edge sits below the cap. All three pieces use the same plank stock.
      final topEdge = Vector3(
        inset,
        outsideFoot - sign * (nearHead - skin * gain),
        headZ,
      );
      final centre = topEdge - outward * (skin / 2) - uphill * (plank / 2);
      member(
        s.sideRail(i + 1),
        centre,
        centre + axis(0) * (w - 2 * inset),
        outward,
        plank,
        skin,
      );
    }
    final tieZ = h / 3, nearTie = slope * tieZ;
    for (final (i, x) in [inset - stud / 2, w - inset + stud / 2].indexed) {
      member(
        s.crossRail(i + 1),
        Vector3(x, nearTie, tieZ),
        Vector3(x, d - nearTie, tieZ),
        axis(0),
        board,
        stud,
        startPlane: Vector3(0, 1, -slope),
        endPlane: Vector3(0, 1, slope),
      );
    }
  }

  // The two adjacent inside wall faces meet the two outside post faces.
  void boxWalls(double base, int courses, {double? rearHeight}) {
    final s = editorStrings, rim = base + courses * board;
    for (final x in [skin, w - skin - stud]) {
      post(x, skin, 0, rim, stud);
      post(x, d - skin - stud, 0, rearHeight ?? rim, stud);
    }
    for (var row = 0; row < courses; row++) {
      final z = base + row * board;
      for (final y in [0.0, d - skin]) {
        front(s.planterWall, 0, y, z, w, skin, board);
      }
      for (final x in [0.0, w - skin]) {
        cross(s.planterWall, x, skin, z, d - 2 * skin, board, skin);
      }
    }
  }

  void raisedBed() {
    boxWalls(0, 6);
    final top = 6 * board;
    for (final y in [skin, d - skin - stud]) {
      post((w - stud) / 2, y, 0, top, stud);
    }
    cross(
      editorStrings.frameRail,
      (w - stud) / 2,
      skin + stud,
      h / 2,
      d - 2 * (skin + stud),
      stud,
      stud,
    );
    final rim = measure(80, 3);
    final corners = [
      Vector3(0, 0, top),
      Vector3(w, 0, top),
      Vector3(w, d, top),
      Vector3(0, d, top),
    ];
    for (var i = 0; i < 4; i++) {
      final edge = corners[(i + 1) % 4] - corners[i], along = edge.normalized();
      beams.add(
        Beam(
          beams.length + 1,
          editorStrings.bedRim,
          corners[i] + along * (rim / 2),
          Vector3(edge.length - rim, rim, h - top),
          along,
          axis(2).cross(along),
          startCut: (y: rim, z: 0),
          endCut: (y: -rim, z: 0),
          finish: finish,
        ),
      );
    }
  }

  void porch() {
    final s = editorStrings, rise = measure(160, 6.25), treadWidth = w - heavy;
    final pitch = (d - plank) / 10;
    for (var tier = 0; tier < 3; tier++) {
      final top = (tier + 1) * rise,
          start = 2 * tier * pitch,
          count = tier == 2 ? 7 : 2;
      final run = (count - 1) * pitch + plank;
      front(s.frontPanel, 0, start, tier * rise, treadWidth, skin, rise - stud);
      for (var i = 0; i < count; i++) {
        flat(
          tier == 2 ? s.deckBoard : s.tread,
          0,
          start + i * pitch,
          top - stud,
          treadWidth,
          plank,
          stud,
        );
      }
      for (var i = 0; i < 4; i++) {
        final x = i * (treadWidth - stud) / 3;
        cross(
          s.frameRail,
          x,
          start + skin,
          top - stud - board,
          run - skin,
          board,
          stud,
        );
        for (final y in [start + skin, start + run - stud]) {
          post(x, y, 0, top - stud - board, stud);
        }
      }
      for (final y in [start + skin, start + run - stud]) {
        for (var i = 0; i < 3; i++) {
          final bay = (treadWidth - stud) / 3;
          front(
            s.frameRail,
            i * bay + stud,
            y,
            top - stud - board,
            bay - stud,
            stud,
            board,
          );
        }
      }
    }
    final landing = 4 * pitch, deck = 3 * rise;
    final bay = (treadWidth - stud) / 3;
    for (final x in [bay + stud, 2 * bay + stud]) {
      cross(s.frameRail, x, skin, 0, d - skin, skin, stud);
    }
    final slope = 2 * rise / landing, gain = math.sqrt(1 + slope * slope);
    final railNormal = Vector3(0, -slope / gain, 1 / gain);
    final cx = treadWidth + heavy / 2,
        railStart = h - 2 * rise,
        drop = skin * gain / 2;
    member(
      s.landingRail,
      Vector3(cx, 0, railStart - drop),
      Vector3(cx, landing, h - drop),
      railNormal,
      heavy,
      skin,
      startPlane: axis(1),
      endPlane: axis(1),
    );
    member(
      s.uprightPost,
      Vector3(cx, heavy / 2, 0),
      Vector3(cx, heavy / 2, railStart + slope * heavy / 2 - 2 * drop),
      axis(0),
      heavy,
      heavy,
      startPlane: axis(2),
      endPlane: railNormal,
    );
    for (final y in [landing, d - heavy]) {
      post(treadWidth, y, 0, h - skin, heavy);
    }
    add(
      s.landingRail,
      treadWidth,
      landing,
      h - skin,
      d - landing,
      heavy,
      skin,
      1,
      0,
    );
    final inside = d - landing - 2 * heavy, bottom = deck + measure(60, 2.5);
    cross(
      s.frameRail,
      treadWidth + (heavy - stud) / 2,
      landing + heavy,
      bottom,
      inside,
      stud,
      stud,
    );
    final bays = (inside / measure(115, 4.5)).ceil();
    for (var i = 1; i < bays; i++) {
      post(
        treadWidth + (heavy - stud) / 2,
        landing + heavy + i * inside / bays - stud / 2,
        bottom + stud,
        h - skin - bottom - stud,
        stud,
      );
    }
  }
}

extension _GardenFurniture on _Parts {
  void chaise() {
    final s = editorStrings,
        seat = measure(320, 12.5),
        bend = measure(1100, 43);
    final gap = measure(8, .3125), inset = measure(55, 2.25);
    // The seat finishes before the inclined back so both surfaces meet at the hip.
    for (var i = 0; i < 11; i++) {
      flat(
        s.seatSlat(i + 1),
        0,
        i * (bend - board) / 10,
        seat - skin,
        w,
        board,
        skin,
      );
    }
    final run = d - bend - gap - skin;
    final slope = (h - seat) / run, gain = math.sqrt(1 + slope * slope);
    final start = d - skin * slope / gain - run;
    final tangent = Vector3(0, 1 / gain, slope / gain);
    final normal = axis(0).cross(tangent);
    final topStart = Vector3(0, start, seat);
    final backLength = run * gain;
    for (var i = 0; i < 9; i++) {
      final top = topStart + tangent * (i * (backLength - board) / 8);
      // Upright view: each slat spans the chair, the grain follows its length.
      beams.add(
        Beam(
          beams.length + 1,
          s.benchBack,
          top - normal * skin,
          Vector3(w, board, skin),
          axis(0),
          tangent,
        ),
      );
    }
    for (final x in [inset, w - inset - stud]) {
      cross(s.frameRail, x, 0, seat - skin - board, bend, board, stud);
      final cx = x + stud / 2, offset = (skin + board / 2) * gain;
      member(
        s.frameRail,
        Vector3(cx, start, seat - offset),
        Vector3(cx, d, seat + slope * (d - start) - offset),
        axis(0),
        board,
        stud,
        startPlane: axis(1),
        endPlane: axis(1),
      );
      for (final y in [inset, bend - stud]) {
        post(x, y, 0, seat - skin - board, stud);
      }
      final supportY = d - measure(140, 5.5);
      // Cut the top of the rear post to bear flush against the back rail.
      final underside =
          seat + slope * (supportY - start) - (skin + board) * gain;
      member(
        s.uprightPost,
        Vector3(cx, supportY, 0),
        Vector3(cx, supportY, underside),
        axis(0),
        stud,
        stud,
        startPlane: axis(2),
        endPlane: normal,
      );
      cross(
        s.frameRail,
        x + (x == inset ? stud : -stud),
        bend - stud,
        measure(110, 4.25),
        supportY + stud / 2 - bend + stud,
        board,
        stud,
      );
    }
    for (final y in [inset, bend - stud]) {
      front(
        s.frameRail,
        inset + stud,
        y,
        seat - skin - board,
        w - 2 * (inset + stud),
        stud,
        board,
      );
    }
  }

  void pottingBench() {
    final s = editorStrings, top = measure(860, 34), shelf = measure(200, 8);
    final inner = d - 2 * stud;
    for (final x in [0.0, w - stud]) {
      post(x, 0, 0, top - skin, stud);
      post(x, d - stud, 0, h - skin, stud);
    }
    for (final z in [shelf, top - skin]) {
      for (final x in [0.0, w - stud]) {
        cross(s.frameRail, x, stud, z - board, inner, board, stud);
      }
      for (final y in [0.0, d - stud]) {
        front(s.frameRail, stud, y, z - board, w - 2 * stud, stud, board);
      }
    }
    for (var i = 0; i < 4; i++) {
      flat(
        s.shelfPart,
        0,
        stud + i * (inner - board) / 3,
        shelf,
        w,
        board,
        skin,
      );
    }
    final bay = measure(780, 32);
    cross(
      s.frameRail,
      bay - stud,
      stud,
      top - skin - board,
      inner,
      board,
      stud,
    );
    // Full front board and shorter boards frame a removable potting tray.
    flat(s.tabletop, 0, 0, top - skin, w, board, skin);
    final workDepth = d - stud - board;
    for (var i = 0; i < 4; i++) {
      flat(
        s.tabletop,
        0,
        board + i * (workDepth - board) / 3,
        top - skin,
        bay,
        board,
        skin,
      );
    }
    front(s.frameRail, bay, d - stud, top - skin, w - bay - stud, stud, skin);
    add(
      s.frameRail,
      w - stud,
      board,
      top - skin,
      d - board - stud,
      stud,
      skin,
      1,
      0,
    );
    for (var i = 0; i < 3; i++) {
      front(
        s.backPanel,
        0,
        d - stud - skin,
        top + measure(80, 3) + i * (board + skin),
        w,
        skin,
        board,
      );
    }
    flat(s.shelfPart, 0, d - plank, h - skin, w, plank, skin);
  }

  // Plumb-cut decking on a sloped surface. top0 and top1 refer to the
  // finished upper face so neighbouring roof slopes share the same ridge.
  void roofStrip(
    double x,
    double width,
    double y0,
    double y1,
    double top0,
    double top1,
  ) {
    final slope = (top1 - top0) / (y1 - y0),
        gain = math.sqrt(1 + slope * slope);
    final normal = Vector3(0, -slope / gain, 1 / gain);
    final drop = skin * gain / 2;
    member(
      editorStrings.roofBoard,
      Vector3(x + width / 2, y0, top0 - drop),
      Vector3(x + width / 2, y1, top1 - drop),
      normal,
      width,
      skin,
      startPlane: axis(1),
      endPlane: axis(1),
    );
  }

  void logStore() {
    final s = editorStrings, rise = measure(140, 5.5), slope = rise / d;
    final gain = math.sqrt(1 + slope * slope),
        normal = Vector3(0, -slope / gain, 1 / gain);
    double roof(double y) => h - rise + y * slope;
    final inset = measure(40, 1.5), floor = measure(130, 5);
    for (var i = 0; i < 10; i++) {
      roofStrip(i * plank, plank, 0, d, h - rise, h);
    }
    // Three purlins support the roof boards across their span.
    for (final y in [inset + stud / 2, d / 2, d - inset - stud / 2]) {
      beams.add(
        Beam(
          beams.length + 1,
          s.frameRail,
          Vector3(0, y, roof(y)) -
              normal * (skin + board) -
              Vector3(0, 1 / gain, slope / gain) * (stud / 2),
          Vector3(w, stud, board),
          axis(0),
          Vector3(0, 1 / gain, slope / gain),
        ),
      );
    }
    for (final x in [inset, w - inset - stud]) {
      final start = inset, end = d - inset;
      final drop = (skin + board + board / 2) * gain;
      member(
        s.roofRafter,
        Vector3(x + stud / 2, start, roof(start) - drop),
        Vector3(x + stud / 2, end, roof(end) - drop),
        axis(0),
        board,
        stud,
        startPlane: axis(1),
        endPlane: axis(1),
      );
      for (final y in [start + stud / 2, end - stud / 2]) {
        member(
          s.uprightPost,
          Vector3(x + stud / 2, y, 0),
          Vector3(x + stud / 2, y, roof(y) - (skin + 2 * board) * gain),
          axis(0),
          stud,
          stud,
          startPlane: axis(2),
          endPlane: normal,
        );
      }
      for (var i = 0; i < 4; i++) {
        cross(
          s.sidePanel,
          x,
          start + stud,
          floor + board + i * 2.3 * board,
          end - start - 2 * stud,
          board,
          skin,
        );
      }
    }
    final y0 = inset + stud, y1 = d - inset - stud;
    for (final x in [inset, (w - stud) / 2, w - inset - stud]) {
      cross(s.frameRail, x, y0, floor - board, y1 - y0, board, stud);
    }
    for (final y in [inset, d - inset - stud]) {
      front(
        s.frameRail,
        inset + stud,
        y,
        floor - board,
        w - 2 * (inset + stud),
        stud,
        board,
      );
    }
    final count = ((y1 - y0) / board).floor();
    for (var i = 0; i < count; i++) {
      flat(
        s.deckBoard,
        inset,
        y0 + i * (y1 - y0 - board) / (count - 1),
        floor,
        w - 2 * inset,
        board,
        skin,
      );
    }
    for (var i = 0; i < 4; i++) {
      front(
        s.backPanel,
        inset + stud,
        d - inset - stud,
        floor + board + i * 2.3 * board,
        w - 2 * (inset + stud),
        skin,
        board,
      );
    }
  }
}

extension _JoinersBench on _Parts {}
