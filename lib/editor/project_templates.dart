import 'dart:math' as math;

import '../l10n/strings.dart';
import 'model.dart';
import 'part_finish.dart';

part 'outdoor_templates.dart';
part 'framing_templates.dart';

enum TemplateCategory {
  shelving,
  seating,
  tables,
  cabinets,
  workshop,
  garden,
  construction;

  String get label => switch (this) {
    shelving => editorStrings.categoryShelving,
    seating => editorStrings.categorySeating,
    tables => editorStrings.categoryTables,
    cabinets => editorStrings.categoryCabinets,
    workshop => editorStrings.categoryWorkshop,
    garden => editorStrings.categoryGarden,
    construction => editorStrings.categoryConstruction,
  };
}

enum FurnitureTemplate {
  signatureCabinet(
    TemplateCategory.cabinets,
    FinishPreset.mdf,
    (960, 320, 740),
    (38, 12.5, 29),
  ),
  bookcase(
    TemplateCategory.shelving,
    FinishPreset.oakBoard,
    (760, 300, 1440),
    (30, 12, 56),
  ),
  cubeShelf(
    TemplateCategory.shelving,
    FinishPreset.whiteBoard,
    (1020, 330, 1020),
    (40, 13, 40),
  ),
  wallShelf(
    TemplateCategory.shelving,
    FinishPreset.plywood,
    (740, 180, 160),
    (29, 7, 6),
  ),
  stool(
    TemplateCategory.seating,
    FinishPreset.wood,
    (360, 360, 450),
    (14, 14, 18),
  ),
  stepStool(
    TemplateCategory.seating,
    FinishPreset.plywood,
    (400, 400, 360),
    (16, 16, 14),
  ),
  gardenBench(
    TemplateCategory.garden,
    FinishPreset.wood,
    (1490, 460, 850),
    (47.5, 18, 33.5),
  ),
  diningTable(
    TemplateCategory.tables,
    FinishPreset.wood,
    (1490, 810, 750),
    (59, 31.5, 30),
  ),
  writingDesk(
    TemplateCategory.tables,
    FinishPreset.oakBoard,
    (1200, 600, 740),
    (47.5, 23.75, 29),
  ),
  bedsideCabinet(
    TemplateCategory.cabinets,
    FinishPreset.mdf,
    (450, 400, 600),
    (18, 16, 24),
  ),
  tvStand(
    TemplateCategory.cabinets,
    FinishPreset.oakBoard,
    (1400, 380, 420),
    (55, 15, 16.5),
  ),
  drawerChest(
    TemplateCategory.cabinets,
    FinishPreset.mdf,
    (800, 430, 860),
    (32, 17, 34),
  ),
  workbench(
    TemplateCategory.workshop,
    FinishPreset.wood,
    (1490, 690, 900),
    (59, 27, 35.5),
  ),
  toolTote(
    TemplateCategory.workshop,
    FinishPreset.plywood,
    (480, 240, 300),
    (19, 9.5, 12),
  ),
  picnicTable(
    TemplateCategory.garden,
    FinishPreset.wood,
    (1490, 1500, 740),
    (59, 59, 29),
  ),
  sawhorse(
    TemplateCategory.workshop,
    FinishPreset.wood,
    (900, 480, 740),
    (36, 19, 29),
  ),
  clampRack(
    TemplateCategory.workshop,
    FinishPreset.wood,
    (750, 220, 270),
    (30, 9, 10.5),
  ),
  raisedBed(
    TemplateCategory.garden,
    FinishPreset.wood,
    (1490, 740, 540),
    (59, 29, 21),
  ),
  standingPlanter(
    TemplateCategory.garden,
    FinishPreset.wood,
    (990, 490, 800),
    (39, 19.5, 32),
  ),
  trellisPlanter(
    TemplateCategory.garden,
    FinishPreset.wood,
    (900, 440, 1620),
    (36, 17.5, 64),
  ),
  porch(
    TemplateCategory.garden,
    FinishPreset.wood,
    (1200, 1600, 1500),
    (48, 63, 61),
  ),
  chaise(
    TemplateCategory.garden,
    FinishPreset.wood,
    (640, 1840, 820),
    (25, 72, 32),
  ),
  pottingBench(
    TemplateCategory.garden,
    FinishPreset.wood,
    (1200, 540, 1400),
    (48, 21, 55),
  ),
  logStore(
    TemplateCategory.garden,
    FinishPreset.wood,
    (1400, 650, 1420),
    (55, 26, 56),
  ),
  gazebo(
    TemplateCategory.garden,
    FinishPreset.wood,
    (2240, 2200, 2750),
    (88, 86, 108),
  ),
  shedFloor(
    TemplateCategory.construction,
    FinishPreset.wood,
    (2400, 1800, 190),
    (96, 72, 7.25),
  ),
  windowWall(
    TemplateCategory.construction,
    FinishPreset.wood,
    (2400, 140, 2400),
    (96, 5.5, 94),
  ),
  cornerWalls(
    TemplateCategory.construction,
    FinishPreset.wood,
    (1600, 1200, 2400),
    (64, 48, 94),
  ),
  panelDoor(
    TemplateCategory.construction,
    FinishPreset.wood,
    (810, 40, 2000),
    (31.5, 1.5, 80),
  ),
  gardenGate(
    TemplateCategory.garden,
    FinishPreset.wood,
    (900, 60, 1300),
    (36, 2.25, 52),
  );

  const FurnitureTemplate(
    this.category,
    this.material,
    this.metric,
    this.imperial,
  );
  final TemplateCategory category;
  final FinishPreset material;
  final (double, double, double) metric, imperial;

  String get title => switch (this) {
    signatureCabinet => editorStrings.templateSignatureCabinet,
    bookcase => editorStrings.templateBookcase,
    cubeShelf => editorStrings.templateCubeShelf,
    wallShelf => editorStrings.templateWallShelf,
    stool => editorStrings.templateStool,
    stepStool => editorStrings.templateStepStool,
    gardenBench => editorStrings.templateGardenBench,
    diningTable => editorStrings.templateDiningTable,
    writingDesk => editorStrings.templateWritingDesk,
    bedsideCabinet => editorStrings.templateBedsideCabinet,
    tvStand => editorStrings.templateTvStand,
    drawerChest => editorStrings.templateDrawerChest,
    workbench => editorStrings.templateWorkbench,
    toolTote => editorStrings.templateToolTote,
    picnicTable => editorStrings.templatePicnicTable,
    sawhorse => editorStrings.templateSawhorse,
    clampRack => editorStrings.templateClampRack,
    raisedBed => editorStrings.templateRaisedBed,
    standingPlanter => editorStrings.templateStandingPlanter,
    trellisPlanter => editorStrings.templateTrellisPlanter,
    porch => editorStrings.templatePorch,
    chaise => editorStrings.templateChaise,
    pottingBench => editorStrings.templatePottingBench,
    logStore => editorStrings.templateLogStore,
    gazebo => editorStrings.templateGazebo,
    shedFloor => editorStrings.templateShedFloor,
    windowWall => editorStrings.templateWindowWall,
    cornerWalls => editorStrings.templateCornerWalls,
    panelDoor => editorStrings.templatePanelDoor,
    gardenGate => editorStrings.templateGardenGate,
  };

  String? get constructionNote => switch (this) {
    gazebo || logStore => editorStrings.roofNote,
    porch => editorStrings.porchNote,
    shedFloor => editorStrings.framingNote,
    windowWall || cornerWalls => editorStrings.wallFrameNote,
    panelDoor => editorStrings.doorNote,
    gardenGate => editorStrings.gateNote,
    _ => null,
  };

  Project build(LengthUnit unit) {
    final parts = _Parts(this, unit);
    final s = editorStrings;
    final w = parts.w, d = parts.d, h = parts.h, t = parts.thickness;
    final q = parts.measure;
    final flat = parts.flat, side = parts.side, front = parts.front;
    switch (this) {
      case signatureCabinet:
        parts.signatureCabinet();
      case bookcase:
        parts.cabinet(rows: 5);
        front(s.backPanel, 0, d - t, 0, w, t, h);
      case cubeShelf:
        final bay = (w - 4 * t) / 3;
        flat(s.bottomPanel, 0, 0, 0, w, d, t);
        for (var col = 0; col < 4; col++) {
          final levels = math.min(3, 4 - col);
          side(s.dividerPanel, col * (t + bay), 0, t, t, d, h * levels / 3 - t);
          for (var level = 1; level <= 3 - col; level++) {
            flat(
              s.shelfPart,
              col * (t + bay) + t,
              0,
              h * level / 3 - t,
              bay,
              d,
              t,
            );
          }
        }
      case wallShelf:
        flat(s.shelfPart, 0, 0, 0, w, d, t);
        front(s.backPanel, 0, d - t, t, w, t, h - t);
        front(s.frontPanel, 0, 0, t, w, t, q(35, 1.5));
        for (final x in [0.0, w - t]) {
          side(s.sidePanel, x, t, t, t, d - 2 * t, h - t);
        }
      case stool:
        parts.woodFrame(slats: 4, seat: true);
      case stepStool:
        // Side supports are rectangular stock, including the upper riser.
        for (final x in [0.0, w - t]) {
          side(s.sidePanel, x, 0, 0, t, d, h / 2 - t);
          side(s.sidePanel, x, d / 2, h / 2 - t, t, d / 2, h / 2);
        }
        flat(s.tread, 0, 0, h / 2 - t, w, d / 2, t);
        flat(s.tread, 0, d / 2, h - t, w, d / 2, t);
        front(s.backPanel, t, d - t, 0, w - 2 * t, t, h - t);
        front(s.frontPanel, t, d / 2 - t, 0, w - 2 * t, t, h / 2 - t);
      case gardenBench:
        parts.slattedBench();
      case diningTable:
        parts.woodFrame(slats: 9);
      case writingDesk:
        flat(s.tabletop, 0, 0, h - t, w, d, t);
        final bay = q(365, 14);
        for (final x in [0.0, w - bay, w - t]) {
          side(s.sidePanel, x, 0, 0, t, d, h - t);
        }
        front(
          s.backPanel,
          t,
          d - t,
          h - q(260, 10) - t,
          w - bay - t,
          t,
          q(260, 10),
        );
        front(s.backPanel, w - bay + t, d - t, 0, bay - 2 * t, t, h - t);
        for (final z in [q(80, 3), q(365, 14)]) {
          flat(s.shelfPart, w - bay + t, 0, z, bay - 2 * t, d - t, t);
        }
      case bedsideCabinet:
        parts.cabinet(rows: 2, inset: t);
        front(s.backPanel, 0, d - t, 0, w, t, h);
        final reveal = q(2, 1 / 16);
        front(
          s.doorPanel,
          reveal,
          0,
          reveal,
          w - 2 * reveal,
          t,
          h / 2 - reveal,
        );
      case tvStand:
        parts.cabinet(columns: 3, inset: t);
        front(s.backPanel, 0, d - t, 0, w, t, h);
        final reveal = q(2, 1 / 16);
        final doorWidth = (w - 4 * t) / 3 + 1.5 * t;
        for (final x in [0.0, w - doorWidth]) {
          front(
            s.doorPanel,
            x + reveal,
            0,
            reveal,
            doorWidth - 2 * reveal,
            t,
            h - 2 * reveal,
          );
        }
      case drawerChest:
        parts.cabinet(inset: t);
        front(s.backPanel, 0, d - t, 0, w, t, h);
        final opening = (h - 2 * t) / 4, gap = q(24, 1), clearance = q(12, .5);
        for (var i = 0; i < 4; i++) {
          final z = t + i * opening, x = t + clearance, y = t;
          final width = w - 2 * x, depth = d - 3 * t;
          front(
            s.drawerFront,
            gap,
            0,
            z + gap / 2,
            w - 2 * gap,
            t,
            opening - gap,
          );
          flat(s.bottomPanel, x, y, z, width, depth, t);
          for (final edge in [x, w - x - t]) {
            side(s.sidePanel, edge, y, z + t, t, depth, opening - 3 * t);
          }
          front(
            s.backPanel,
            x + t,
            y + depth - t,
            z + t,
            width - 2 * t,
            t,
            opening - 3 * t,
          );
        }
      case workbench:
        parts.joinersBench();
      case toolTote:
        flat(s.bottomPanel, 0, 0, 0, w, d, t);
        for (final x in [0.0, w - t]) {
          side(s.sidePanel, x, 0, t, t, d, h - t);
        }
        for (final y in [0.0, d - t]) {
          front(s.sidePanel, t, y, t, w - 2 * t, t, h / 2 - t);
        }
        front(
          s.carryHandle,
          t,
          (d - t) / 2,
          h - q(40, 1.5),
          w - 2 * t,
          t,
          q(40, 1.5),
        );
      case picnicTable:
        parts.picnic();
      case sawhorse:
        parts.sawhorse();
      case clampRack:
        parts.clampRack();
      case raisedBed:
        parts.raisedBed();
      case standingPlanter:
        parts.standingPlanter();
      case trellisPlanter:
        parts.trellisPlanter();
      case porch:
        parts.porch();
      case chaise:
        parts.chaise();
      case pottingBench:
        parts.pottingBench();
      case logStore:
        parts.logStore();
      case gazebo:
        parts.gazebo();
      case shedFloor:
        parts.shedFloor();
      case windowWall:
        parts.windowWall();
      case cornerWalls:
        parts.cornerWalls();
      case panelDoor:
        parts.panelDoor();
      case gardenGate:
        parts.gardenGate();
    }
    return Project(title, parts.beams, const [], unit);
  }
}

// All origins below denote the minimum world coordinates of the cut piece.
// Beam.size always holds the stock length, face width and cutting thickness.
class _Parts {
  _Parts(this.template, this.unit);
  final FurnitureTemplate template;
  final LengthUnit unit;
  final beams = <Beam>[];
  late PartFinish finish = template.material.finish;
  late final w = measure(template.metric.$1, template.imperial.$1);
  late final d = measure(template.metric.$2, template.imperial.$2);
  late final h = measure(template.metric.$3, template.imperial.$3);
  late final thickness = switch (template) {
    FurnitureTemplate.toolTote => measure(12, .5),
    _
        when template.material == FinishPreset.whiteBoard ||
            template.material == FinishPreset.oakBoard =>
      measure(16, .75),
    _ => measure(18, .75),
  };
  double measure(double metric, double inches) =>
      unit == LengthUnit.inch ? inches * unit.factor : metric;

  void add(
    String name,
    double x,
    double y,
    double z,
    double length,
    double width,
    double thick,
    int lengthAxis,
    int widthAxis,
  ) {
    final along = axis(lengthAxis), across = axis(widthAxis);
    final normal = along.cross(across);
    final origin = Vector3(x, y, z);
    if (normal.x + normal.y + normal.z < 0) origin.sub(normal * thick);
    // A board mounted on edge and the same board laid flat share one purchase.
    final turnStock = template.material == FinishPreset.wood && width < thick;
    beams.add(
      Beam(
        beams.length + 1,
        name,
        turnStock ? origin + across * width : origin,
        turnStock
            ? Vector3(length, thick, width)
            : Vector3(length, width, thick),
        along,
        turnStock ? normal : across,
        finish: finish,
      ),
    );
  }

  void flat(
    String name,
    double x,
    double y,
    double z,
    double width,
    double depth,
    double thick,
  ) => add(name, x, y, z, width, depth, thick, 0, 1);
  void side(
    String name,
    double x,
    double y,
    double z,
    double thick,
    double depth,
    double height,
  ) => add(name, x, y, z, height, depth, thick, 2, 1);
  void front(
    String name,
    double x,
    double y,
    double z,
    double width,
    double thick,
    double height,
  ) {
    if (height > width && template.material != FinishPreset.wood) {
      add(name, x, y, z, height, width, thick, 2, 0);
    } else {
      add(name, x, y, z, width, height, thick, 0, 2);
    }
  }

  void signatureCabinet() {
    final s = editorStrings, t = thickness;
    final foot = measure(48, 2),
        frame = measure(42, 1.625),
        low = measure(432, 17);
    final split = measure(498, 19.75), depth = d - 2 * t;
    final rightWidth = w - split;
    const body = (texture: PartTexture.mdf, rgb: 0xc3dcf1);
    finish = (texture: PartTexture.mdf, rgb: 0x82a6c9);
    // Each recessed foot is built from two offcuts of the same MDF.
    for (final x in [frame / 2, w - frame / 2 - 2 * t]) {
      for (final y in [frame, d - frame * 2]) {
        for (var i = 0; i < 2; i++) {
          side(s.uprightPost, x + i * t, y, 0, t, frame, foot);
        }
      }
    }
    finish = body;
    flat(s.bottomPanel, 0, t, foot, w, depth, t);
    side(s.sidePanel, 0, t, foot + t, t, depth, h - foot - 2 * t);
    side(s.dividerPanel, split - t, t, foot + t, t, depth, h - foot - 2 * t);
    side(s.sidePanel, w - t, t, foot + t, t, depth, low - foot - 2 * t);
    flat(s.topPanel, 0, t, h - t, split, depth, t);
    flat(s.shelfPart, t, t, low - t, split - 2 * t, depth, t);
    flat(s.topPanel, split, t, low - t, rightWidth, depth, t);
    // Wide face rails reproduce the stepped silhouette of the app mark.
    front(s.frameRail, 0, 0, foot, frame, t, h - foot);
    front(s.frameRail, split - frame, 0, foot, frame, t, h - foot);
    front(s.frameRail, w - frame, 0, foot, frame, t, low - foot);
    for (final z in [foot, low - frame, h - frame]) {
      front(s.frameRail, frame, 0, z, split - 2 * frame, t, frame);
    }
    for (final z in [foot, low - frame]) {
      front(s.frameRail, split, 0, z, rightWidth - frame, t, frame);
    }
    finish = (texture: PartTexture.mdf, rgb: 0x42577a);
    front(s.backPanel, 0, d - t, foot, split, t, h - foot);
    front(s.backPanel, split, d - t, foot, rightWidth, t, low - foot);
    final gap = measure(2, 1 / 16), diameter = measure(32, 1.25);
    final width = rightWidth - frame - 2 * gap,
        height = low - foot - 2 * frame - 2 * gap;
    finish = (texture: PartTexture.mdf, rgb: 0xe4f187);
    front(
      s.signatureDoor('${unit.format(diameter)} ${unit.symbol}'),
      split + gap,
      gap,
      foot + frame + gap,
      width,
      t,
      height,
    );
    // Face coordinates are in the panel's grain/width basis.
    beams.last = beams.last.copy(bore: (u: .84, v: .77, diameter: diameter));
  }

  void cabinet({
    int rows = 1,
    int columns = 1,
    double inset = 0,
    bool back = true,
  }) {
    final s = editorStrings, t = thickness;
    final depth = d - inset - (back ? t : 0);
    for (final x in [0.0, w - t]) {
      side(s.sidePanel, x, inset, 0, t, depth, h);
    }
    final openingHeight = (h - (rows + 1) * t) / rows;
    final openingWidth = (w - (columns + 1) * t) / columns;
    for (var row = 0; row <= rows; row++) {
      final z = row * (openingHeight + t);
      flat(
        row == 0
            ? s.bottomPanel
            : row == rows
            ? s.topPanel
            : s.shelfPart,
        t,
        inset,
        z,
        w - 2 * t,
        depth,
        t,
      );
      if (row < rows) {
        for (var col = 1; col < columns; col++) {
          side(
            s.dividerPanel,
            col * (openingWidth + t),
            inset,
            z + t,
            t,
            depth,
            openingHeight,
          );
        }
      }
    }
  }

  void woodFrame({required int slats, bool seat = false}) {
    final s = editorStrings;
    final board = measure(90, 3.5),
        thick = measure(20, .75),
        post = measure(40, 1.5);
    final inset = measure(16, .625), top = h - thick;
    final gap = (d - slats * board) / (slats - 1);
    for (var i = 0; i < slats; i++) {
      flat(
        seat ? s.seatSlat(i + 1) : s.tabletop,
        0,
        i * (board + gap),
        top,
        w,
        board,
        thick,
      );
    }
    var leg = 0;
    for (final x in [inset, w - inset - post]) {
      for (final y in [inset, d - inset - post]) {
        add(s.leg(++leg), x, y, 0, top, post, post, 2, 0);
      }
    }
    for (final (i, y) in [inset, d - inset - thick].indexed) {
      front(
        s.sideRail(i + 1),
        inset + post,
        y,
        top - board,
        w - 2 * (inset + post),
        thick,
        board,
      );
    }
    if (w >= measure(900, 36)) {
      add(
        s.crossRail(3),
        (w - thick) / 2,
        inset + thick,
        top - board,
        d - 2 * (inset + thick),
        board,
        thick,
        1,
        2,
      );
    }
    final clearDepth = d - 2 * (inset + post);
    for (final (i, x) in [inset, w - inset - thick].indexed) {
      add(
        s.crossRail(i + 1),
        x,
        inset + post,
        top - board,
        clearDepth,
        board,
        thick,
        1,
        2,
      );
    }
  }
}
