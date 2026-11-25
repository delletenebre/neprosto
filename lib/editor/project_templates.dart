import 'dart:math' as math;

import '../l10n/strings.dart';
import 'model.dart';
import 'part_finish.dart';

part 'outdoor_templates.dart';
part 'framing_templates.dart';
part 'catalog_joinery.dart';
part 'catalog_furniture.dart';
part 'catalog_home.dart';
part 'room_templates.dart';

enum TemplateCategory {
  kitchen,
  livingRoom,
  bedroom,
  nursery,
  entryway,
  bathroom,
  office,
  workshop,
  garden;

  String get label => switch (this) {
    kitchen => editorStrings.roomKitchen,
    livingRoom => editorStrings.roomLivingRoom,
    bedroom => editorStrings.roomBedroom,
    nursery => editorStrings.roomNursery,
    entryway => editorStrings.roomEntryway,
    bathroom => editorStrings.roomBathroom,
    office => editorStrings.roomOffice,
    workshop => editorStrings.categoryWorkshop,
    garden => editorStrings.categoryGarden,
  };
}

enum PlanDifficulty {
  easy,
  medium,
  advanced;

  String get label => switch (this) {
    easy => editorStrings.planEasy,
    medium => editorStrings.planMedium,
    advanced => editorStrings.planAdvanced,
  };
}

enum FurnitureTemplate {
  hoodCabinet(
    TemplateCategory.kitchen,
    FinishPreset.whiteBoard,
    (800, 360, 720),
    (30, 14, 28),
    PlanDifficulty.advanced,
  ),
  sinkBase(
    TemplateCategory.kitchen,
    FinishPreset.oakBoard,
    (800, 560, 820),
    (32, 22, 32),
    PlanDifficulty.medium,
  ),
  pantryShelf(
    TemplateCategory.kitchen,
    FinishPreset.wood,
    (686, 102, 1778),
    (27, 4, 70),
    PlanDifficulty.easy,
    'https://pochertezhu.ru/project/uzkaya-polka-za-dveryu/',
  ),
  diningTable(
    TemplateCategory.kitchen,
    FinishPreset.wood,
    (1800, 720, 750),
    (72, 29, 30),
    PlanDifficulty.medium,
    'https://pochertezhu.ru/project/ulichnyy-stol-iz-dosok-na-derevyannyh-oporah/',
  ),
  signatureCabinet(
    TemplateCategory.livingRoom,
    FinishPreset.mdf,
    (960, 320, 740),
    (38, 13, 29),
    PlanDifficulty.advanced,
  ),
  bookcase(
    TemplateCategory.livingRoom,
    FinishPreset.wood,
    (940, 378, 1800),
    (36, 14, 68),
    PlanDifficulty.easy,
    'https://pochertezhu.ru/project/byudzhetnyy-derevyannyy-stellazh-na-chetyre-polki/',
  ),
  coffeeTable(
    TemplateCategory.livingRoom,
    FinishPreset.wood,
    (1000, 400, 400),
    (38, 15, 15),
    PlanDifficulty.medium,
    'https://pochertezhu.ru/project/kompaktnyy-zhurnalnyy-stolik-s-nizhney-polkoy/',
  ),
  tvStand(
    TemplateCategory.livingRoom,
    FinishPreset.oakBoard,
    (1400, 380, 420),
    (54, 15, 17),
    PlanDifficulty.medium,
  ),
  bedroomWardrobe(
    TemplateCategory.bedroom,
    FinishPreset.oakBoard,
    (1800, 600, 2200),
    (72, 24, 86),
    PlanDifficulty.advanced,
  ),
  platformBed(
    TemplateCategory.bedroom,
    FinishPreset.wood,
    (1660, 2060, 340),
    (64, 84, 14),
    PlanDifficulty.medium,
  ),
  drawerChest(
    TemplateCategory.bedroom,
    FinishPreset.mdf,
    (800, 430, 860),
    (32, 17, 34),
    PlanDifficulty.advanced,
  ),
  toyChest(
    TemplateCategory.nursery,
    FinishPreset.wood,
    (880, 570, 620),
    (33, 22, 24),
    PlanDifficulty.advanced,
    'https://pochertezhu.ru/project/ulichnyy-yashchik-dlya-khraneniya-igrushek/',
  ),
  cubeShelf(
    TemplateCategory.nursery,
    FinishPreset.whiteBoard,
    (1000, 330, 1020),
    (39, 13, 39),
    PlanDifficulty.medium,
  ),
  stepStool(
    TemplateCategory.nursery,
    FinishPreset.plywood,
    (400, 400, 360),
    (16, 16, 14),
    PlanDifficulty.easy,
  ),
  shoeBench(
    TemplateCategory.entryway,
    FinishPreset.plywood,
    (1000, 330, 465),
    (38, 13, 18),
    PlanDifficulty.easy,
    'https://novamett.ru/polki/napolnaya-polka-svoimi-rukami-foto#:~:text=Полка%20скамейка%20для%20обуви',
  ),
  consoleTable(
    TemplateCategory.entryway,
    FinishPreset.wood,
    (1650, 300, 600),
    (66, 12, 24),
    PlanDifficulty.easy,
    'https://pochertezhu.ru/project/konsolnyy-stol-s-polkami-za-divan/',
  ),
  mirrorFrame(
    TemplateCategory.entryway,
    FinishPreset.wood,
    (486, 190, 1727),
    (20, 8, 68),
    PlanDifficulty.medium,
    'https://pochertezhu.ru/project/napolnoe-zerkalo-v-derevyannoy-rame/',
  ),
  basinShelf(
    TemplateCategory.bathroom,
    FinishPreset.plywood,
    (700, 450, 320),
    (28, 18, 13),
    PlanDifficulty.medium,
  ),
  blanketLadder(
    TemplateCategory.bathroom,
    FinishPreset.wood,
    (530, 40, 1980),
    (20, 2, 74),
    PlanDifficulty.easy,
    'https://pochertezhu.ru/project/blanket-ladder/',
  ),
  writingDesk(
    TemplateCategory.office,
    FinishPreset.oakBoard,
    (1200, 600, 740),
    (48, 24, 29),
    PlanDifficulty.medium,
  ),
  wallShelf(
    TemplateCategory.office,
    FinishPreset.plywood,
    (1200, 300, 102),
    (45, 12, 4),
    PlanDifficulty.medium,
    'https://pochertezhu.ru/project/polka-so-skrytym-karkasom/',
  ),
  fileTrays(
    TemplateCategory.office,
    FinishPreset.plywood,
    (320, 350, 240),
    (13, 14, 10),
    PlanDifficulty.easy,
  ),
  workbench(
    TemplateCategory.workshop,
    FinishPreset.wood,
    (1500, 600, 850),
    (60, 24, 34),
    PlanDifficulty.advanced,
    'https://pochertezhu.ru/project/verstak-rubo-s-razdelnoy-stoleshnitsey/',
  ),
  sawhorse(
    TemplateCategory.workshop,
    FinishPreset.wood,
    (900, 480, 740),
    (36, 19, 29),
    PlanDifficulty.medium,
  ),
  machineStand(
    TemplateCategory.workshop,
    FinishPreset.wood,
    (800, 600, 900),
    (30, 23, 34),
    PlanDifficulty.medium,
    'https://pochertezhu.ru/project/podstavka-dlya-torcovochnoj-pily-ili-rejsmusa/',
  ),
  raisedBed(
    TemplateCategory.garden,
    FinishPreset.wood,
    (1490, 740, 560),
    (59, 29, 22),
    PlanDifficulty.easy,
  ),
  bench(
    TemplateCategory.garden,
    FinishPreset.wood,
    (1200, 360, 450),
    (48, 14, 18),
    PlanDifficulty.easy,
  ),
  picnicTable(
    TemplateCategory.garden,
    FinishPreset.wood,
    (800, 1040, 456),
    (30, 39, 17),
    PlanDifficulty.medium,
    'https://pochertezhu.ru/project/detskiy-stol-dlya-piknika-so-skameykami/',
  ),
  chaise(
    TemplateCategory.garden,
    FinishPreset.wood,
    (640, 1840, 820),
    (25, 72, 32),
    PlanDifficulty.advanced,
  ),
  pottingBench(
    TemplateCategory.garden,
    FinishPreset.wood,
    (1200, 540, 1400),
    (48, 21, 55),
    PlanDifficulty.medium,
  ),
  logStore(
    TemplateCategory.garden,
    FinishPreset.wood,
    (1400, 650, 1420),
    (55, 26, 56),
    PlanDifficulty.medium,
  ),
  gardenGate(
    TemplateCategory.garden,
    FinishPreset.wood,
    (900, 60, 1300),
    (36, 2, 52),
    PlanDifficulty.medium,
  ),
  birdhouse(
    TemplateCategory.garden,
    FinishPreset.wood,
    (240, 147, 290),
    (9, 6, 11),
    PlanDifficulty.medium,
    'https://pochertezhu.ru/project/a-obraznyy-domik-dlya-ptits/',
  ),
  porch(
    TemplateCategory.garden,
    FinishPreset.wood,
    (1210, 1600, 1500),
    (50, 63, 61),
    PlanDifficulty.advanced,
  );

  const FurnitureTemplate(
    this.category,
    this.material,
    this.metric,
    this.imperial,
    this.difficulty, [
    this.source,
  ]);
  final TemplateCategory category;
  final FinishPreset material;
  final (double, double, double) metric, imperial;
  final PlanDifficulty difficulty;
  final String? source;

  String get title => switch (this) {
    hoodCabinet => editorStrings.templateHoodCabinet,
    sinkBase => editorStrings.templateSinkBase,
    pantryShelf => editorStrings.templatePantryShelf,
    diningTable => editorStrings.templateDiningTable,
    signatureCabinet => editorStrings.templateSignatureCabinet,
    bookcase => editorStrings.templateBookcase,
    coffeeTable => editorStrings.templateCoffeeTable,
    tvStand => editorStrings.templateTvStand,
    bedroomWardrobe => editorStrings.templateBedroomWardrobe,
    platformBed => editorStrings.templatePlatformBed,
    drawerChest => editorStrings.templateDrawerChest,
    toyChest => editorStrings.templateToyChest,
    cubeShelf => editorStrings.templateCubeShelf,
    stepStool => editorStrings.templateStepStool,
    shoeBench => editorStrings.templateShoeBench,
    consoleTable => editorStrings.templateConsoleTable,
    mirrorFrame => editorStrings.templateMirrorFrame,
    basinShelf => editorStrings.templateBasinShelf,
    blanketLadder => editorStrings.templateBlanketLadder,
    writingDesk => editorStrings.templateWritingDesk,
    wallShelf => editorStrings.templateWallShelf,
    fileTrays => editorStrings.templateFileTrays,
    workbench => editorStrings.templateWorkbench,
    sawhorse => editorStrings.templateSawhorse,
    machineStand => editorStrings.templateMachineStand,
    raisedBed => editorStrings.templateRaisedBed,
    bench => editorStrings.bench,
    picnicTable => editorStrings.templatePicnicTable,
    chaise => editorStrings.templateChaise,
    pottingBench => editorStrings.templatePottingBench,
    logStore => editorStrings.templateLogStore,
    gardenGate => editorStrings.templateGardenGate,
    birdhouse => editorStrings.templateBirdhouse,
    porch => editorStrings.templatePorch,
  };

  String get assemblyNote => switch (this) {
    hoodCabinet => editorStrings.assembleHoodCabinet,
    sinkBase => editorStrings.assembleSinkBase,
    pantryShelf => editorStrings.assemblePantryShelf,
    diningTable => editorStrings.assembleDiningTable,
    signatureCabinet => editorStrings.assembleSignatureCabinet,
    bookcase => editorStrings.assembleBookcase,
    coffeeTable => editorStrings.assembleCoffeeTable,
    tvStand => editorStrings.assembleTvStand,
    bedroomWardrobe => editorStrings.assembleBedroomWardrobe,
    platformBed => editorStrings.assemblePlatformBed,
    drawerChest => editorStrings.assembleDrawerChest,
    toyChest => editorStrings.assembleToyChest,
    cubeShelf => editorStrings.assembleCubeShelf,
    stepStool => editorStrings.assembleStepStool,
    shoeBench => editorStrings.assembleShoeBench,
    consoleTable => editorStrings.assembleConsoleTable,
    mirrorFrame => editorStrings.assembleMirrorFrame,
    basinShelf => editorStrings.assembleBasinShelf,
    blanketLadder => editorStrings.assembleBlanketLadder,
    writingDesk => editorStrings.assembleWritingDesk,
    wallShelf => editorStrings.assembleWallShelf,
    fileTrays => editorStrings.assembleFileTrays,
    workbench => editorStrings.assembleWorkbench,
    sawhorse => editorStrings.assembleSawhorse,
    machineStand => editorStrings.assembleMachineStand,
    raisedBed => editorStrings.assembleRaisedBed,
    bench => editorStrings.assembleBench,
    picnicTable => editorStrings.assemblePicnicTable,
    chaise => editorStrings.assembleChaise,
    pottingBench => editorStrings.assemblePottingBench,
    logStore => editorStrings.assembleLogStore,
    gardenGate => editorStrings.assembleGardenGate,
    birdhouse => editorStrings.assembleBirdhouse,
    porch => editorStrings.assemblePorch,
  };

  Project build(LengthUnit unit) {
    final parts = _Parts(this, unit);
    final s = editorStrings;
    final w = parts.w, d = parts.d, h = parts.h, t = parts.thickness;
    final q = parts.measure;
    final flat = parts.flat, side = parts.side, front = parts.front;
    switch (this) {
      case bench:
        return Project.bench(unit);
      case pantryShelf:
        parts.pantryShelfPlan();
      case consoleTable:
        parts.consoleTablePlan();
      case machineStand:
        parts.machineStandPlan();
      case birdhouse:
        parts.birdhousePlan();
      case blanketLadder:
        parts.blanketLadderPlan();
      case toyChest:
        return parts.toyChestPlan();
      case mirrorFrame:
        parts.mirrorFramePlan();
      case coffeeTable:
        parts.coffeeTablePlan();
      case shoeBench:
        parts.shoeBenchPlan();
      case signatureCabinet:
        parts.signatureCabinet();
      case bookcase:
        parts.bookcasePlan();
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
        parts.wallShelfPlan();
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
      case diningTable:
        parts.diningTablePlan();
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
      case bedroomWardrobe:
        parts.bedroomWardrobe();
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
          parts.beams.last = parts.beams.last.withDoorHinge(
            x == 0 ? DoorHinge.left : DoorHinge.right,
            towardEye: -axis(1),
            screenUp: axis(2),
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
          final boxZ = z + q(2, 1 / 16); // Running clearance below each drawer.
          flat(s.bottomPanel, x, y, boxZ, width, depth, t);
          for (final edge in [x, w - x - t]) {
            side(s.sidePanel, edge, y, boxZ + t, t, depth, opening - 3 * t);
          }
          front(
            s.backPanel,
            x + t,
            y + depth - t,
            boxZ + t,
            width - 2 * t,
            t,
            opening - 3 * t,
          );
        }
      case workbench:
        parts.workbenchPlan();
      case picnicTable:
        parts.picnicTablePlan();
      case sawhorse:
        parts.sawhorse();
      case raisedBed:
        parts.raisedBed();
      case porch:
        parts.porch();
      case chaise:
        parts.chaise();
      case pottingBench:
        parts.pottingBench();
      case logStore:
        parts.logStore();
      case gardenGate:
        parts.gardenGate();
      case hoodCabinet:
        parts.hoodCabinet();
      case sinkBase:
        parts.sinkBase();
      case platformBed:
        parts.platformBed();
      case basinShelf:
        parts.basinShelf();
      case fileTrays:
        parts.fileTrays();
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
    FurnitureTemplate.bedroomWardrobe => measure(18, .75),
    FurnitureTemplate.tvStand => measure(20, .75),
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
    final turnStock = finish.texture == PartTexture.wood && width < thick;
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
    if (height > width && finish.texture != PartTexture.wood) {
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
      s.signatureDoor,
      split + gap,
      gap,
      foot + frame + gap,
      width,
      t,
      height,
    );
    beams.last = beams.last
        .withDoorHinge(DoorHinge.left, towardEye: -axis(1), screenUp: axis(2))
        .copy(
          holes: [
            PanelHole(
              measure(60, 2.5),
              measure(60, 2.5),
              diameter,
              fromEnd: true,
              fromFarEdge: true,
            ),
          ],
        );
  }

  void bedroomWardrobe() {
    final s = editorStrings, t = thickness;
    final gap = measure(3, 1 / 8), inset = t + gap;
    final back = measure(6, .25), depth = d - inset - back;
    const bays = 3;
    cabinet(columns: bays, inset: inset, backThickness: back);
    final opening = (w - (bays + 1) * t) / bays;
    final topShelf = h - measure(350, 14);
    final railWidth = measure(25, 1), railHeight = measure(32, 1.25);
    final pitch = w / bays, doorWidth = pitch - gap;
    final floorGap = measure(8, .3125), doorHeight = h - floorGap - gap;
    final pullInset = measure(50, 2);
    for (var bay = 0; bay < bays; bay++) {
      final x = t + bay * (opening + t);
      finish = template.material.finish;
      flat(s.shelfPart, x, inset, topShelf, opening, depth, t);
      if (bay == bays - 1) {
        for (var level = 1; level <= 4; level++) {
          flat(s.shelfPart, x, inset, level * topShelf / 5, opening, depth, t);
        }
      } else {
        finish = FinishPreset.wood.finish;
        front(
          s.clothesRail,
          x,
          inset + (depth - railWidth) / 2,
          topShelf - measure(100, 4),
          opening,
          railWidth,
          railHeight,
        );
      }

      finish = FinishPreset.plywood.finish;
      front(s.backPanel, bay * pitch, d - back, 0, pitch, back, h);
      finish = template.material.finish;
      final hingesOnLeft = bay == 0;
      front(
        hingesOnLeft ? s.leftHingedDoor : s.rightHingedDoor,
        bay * pitch + gap / 2,
        0,
        floorGap,
        doorWidth,
        t,
        doorHeight,
      );
      // The door's long stock axis is vertical. The pull faces the free edge.
      beams.last = beams.last.copy(
        hinge: hingesOnLeft ? DoorHinge.left : DoorHinge.right,
        holes: [
          PanelHole(
            measure(1050, 41) - floorGap,
            pullInset,
            measure(38, 1.5),
            fromFarEdge: hingesOnLeft,
          ),
        ],
      );
    }
  }

  void cabinet({
    int rows = 1,
    int columns = 1,
    double inset = 0,
    double? backThickness,
  }) {
    final s = editorStrings, t = thickness;
    final depth = d - inset - (backThickness ?? t);
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
}
