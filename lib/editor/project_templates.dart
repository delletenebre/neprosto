import 'dart:math' as math;

import '../l10n/strings.dart';
import 'model.dart';
import 'part_finish.dart';

part 'outdoor_templates.dart';
part 'framing_templates.dart';
part 'catalog_joinery.dart';
part 'catalog_furniture.dart';
part 'catalog_home.dart';

const _sqrt3 = 1.7320508075688772;

enum TemplateCategory {
  shelving,
  seating,
  tables,
  cabinets,
  workshop,
  garden,
  construction,
  household;

  String get label => switch (this) {
    shelving => editorStrings.categoryShelving,
    seating => editorStrings.categorySeating,
    tables => editorStrings.categoryTables,
    cabinets => editorStrings.categoryCabinets,
    workshop => editorStrings.categoryWorkshop,
    garden => editorStrings.categoryGarden,
    household => editorStrings.categoryHousehold,
    construction => editorStrings.categoryConstruction,
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
  signatureCabinet(
    TemplateCategory.cabinets,
    FinishPreset.mdf,
    (960, 320, 740),
    (38, 12.5, 29),
  ),
  bookcase.plan(
    TemplateCategory.shelving,
    FinishPreset.wood,
    (940, 378, 1800),
    PlanDifficulty.easy,
    'https://pochertezhu.ru/project/byudzhetnyy-derevyannyy-stellazh-na-chetyre-polki/',
  ),
  cubeShelf(
    TemplateCategory.shelving,
    FinishPreset.whiteBoard,
    (1020, 330, 1020),
    (40, 13, 40),
  ),
  wallShelf.plan(
    TemplateCategory.shelving,
    FinishPreset.plywood,
    (1200, 300, 102),
    PlanDifficulty.medium,
    'https://pochertezhu.ru/project/polka-so-skrytym-karkasom/',
  ),
  bench(TemplateCategory.seating, FinishPreset.wood, (1200, 360, 450)),
  stool.plan(
    TemplateCategory.seating,
    FinishPreset.plywood,
    (568, 300, 518),
    PlanDifficulty.easy,
    'https://pochertezhu.ru/project/taburet-s-podstavkoy-dlya-gitary-i-polkoy/',
  ),
  stepStool(
    TemplateCategory.seating,
    FinishPreset.plywood,
    (400, 400, 360),
    (16, 16, 14),
  ),
  gardenBench.plan(
    TemplateCategory.garden,
    FinishPreset.wood,
    (1680, 700, 940),
    PlanDifficulty.advanced,
    'https://pochertezhu.ru/project/sadovaya-skamya-so-spinkoy-i-podlokotnikami/',
  ),
  diningTable.plan(
    TemplateCategory.tables,
    FinishPreset.wood,
    (1828.8, 718.82, 749.3),
    PlanDifficulty.medium,
    'https://pochertezhu.ru/project/ulichnyy-stol-iz-dosok-na-derevyannyh-oporah/',
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
  bedroomWardrobe(
    TemplateCategory.cabinets,
    FinishPreset.oakBoard,
    (1800, 600, 2200),
    (72, 24, 86),
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
  workbench.plan(
    TemplateCategory.workshop,
    FinishPreset.wood,
    (1524, 609.6, 863.6),
    PlanDifficulty.advanced,
    'https://pochertezhu.ru/project/verstak-rubo-s-razdelnoy-stoleshnitsey/',
  ),
  toolTote.plan(
    TemplateCategory.workshop,
    FinishPreset.wood,
    (546, 178, 267),
    PlanDifficulty.medium,
    'https://pochertezhu.ru/project/derevyannyy-yashchik-dlya-instrumentov/',
  ),
  picnicTable.plan(
    TemplateCategory.garden,
    FinishPreset.wood,
    (800, 1040, 456),
    PlanDifficulty.medium,
    'https://pochertezhu.ru/project/detskiy-stol-dlya-piknika-so-skameykami/',
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
  standingPlanter.plan(
    TemplateCategory.garden,
    FinishPreset.wood,
    (380, 380, 380),
    PlanDifficulty.easy,
    'https://pochertezhu.ru/project/derevyannoe-kashpo-na-nozhkakh/',
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
    (2240, 2200, 2860),
    (88, 86, 112.5),
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
  ),
  laptopTray.plan(
    TemplateCategory.tables,
    FinishPreset.wood,
    (566, 286, 255),
    PlanDifficulty.easy,
    'https://pochertezhu.ru/project/podnos-dlya-noutbuka/',
  ),
  bagShelf.plan(
    TemplateCategory.household,
    FinishPreset.wood,
    (457, 64, 159),
    PlanDifficulty.easy,
    'https://pochertezhu.ru/project/nastennaya-veshalka-dlya-sumok/',
  ),
  pantryShelf.plan(
    TemplateCategory.shelving,
    FinishPreset.wood,
    (686, 102, 1778),
    PlanDifficulty.easy,
    'https://pochertezhu.ru/project/uzkaya-polka-za-dveryu/',
  ),
  consoleTable.plan(
    TemplateCategory.tables,
    FinishPreset.wood,
    (1651, 304.8, 609.6),
    PlanDifficulty.easy,
    'https://pochertezhu.ru/project/konsolnyy-stol-s-polkami-za-divan/',
  ),
  bathTray.plan(
    TemplateCategory.household,
    FinishPreset.wood,
    (965.2, 234.95, 57.15),
    PlanDifficulty.easy,
    'https://pochertezhu.ru/project/derevyannyj-stolik-polka-dlya-vanny/',
  ),
  machineStand.plan(
    TemplateCategory.workshop,
    FinishPreset.wood,
    (800, 600, 900),
    PlanDifficulty.medium,
    'https://pochertezhu.ru/project/podstavka-dlya-torcovochnoj-pily-ili-rejsmusa/',
  ),
  trestleBench.plan(
    TemplateCategory.seating,
    FinishPreset.wood,
    (1295, 235, 528),
    PlanDifficulty.medium,
    'https://pochertezhu.ru/project/sadovaya-skamejka-iz-dereva/',
  ),
  windowBox.plan(
    TemplateCategory.garden,
    FinishPreset.wood,
    (1080, 220, 140),
    PlanDifficulty.medium,
    'https://pochertezhu.ru/project/podokonnyy-tsvetochnyy-yashchik-s-reechnoy-otdelkoy/',
  ),
  birdhouse.plan(
    TemplateCategory.garden,
    FinishPreset.wood,
    (240, 147, 120 * (1 + math.sqrt2)),
    PlanDifficulty.medium,
    'https://pochertezhu.ru/project/a-obraznyy-domik-dlya-ptits/',
  ),
  candleShelf.plan(
    TemplateCategory.household,
    FinishPreset.wood,
    (140, 150, 250 + 140 * _sqrt3),
    PlanDifficulty.advanced,
    'https://pochertezhu.ru/project/nastennaya-polka-podsvechnik-s-treugolnym-dekorom/',
  ),
  blanketLadder.plan(
    TemplateCategory.household,
    FinishPreset.wood,
    (530, 40, 1980),
    PlanDifficulty.easy,
    'https://pochertezhu.ru/project/blanket-ladder/',
  ),
  headphoneStand.plan(
    TemplateCategory.household,
    FinishPreset.wood,
    (140, 140, 293),
    PlanDifficulty.easy,
    'https://pochertezhu.ru/project/nastolnaya-podstavka-dlya-naushnikov/',
  ),
  plantPanel.plan(
    TemplateCategory.garden,
    FinishPreset.wood,
    (1080, 90, 1096),
    PlanDifficulty.medium,
    'https://pochertezhu.ru/project/nastennaya-panel-dlya-rasteniy/',
  ),
  toyChest.plan(
    TemplateCategory.cabinets,
    FinishPreset.wood,
    (880, 570, 620),
    PlanDifficulty.advanced,
    'https://pochertezhu.ru/project/ulichnyy-yashchik-dlya-khraneniya-igrushek/',
  ),
  shutters.plan(
    TemplateCategory.construction,
    FinishPreset.wood,
    (1356, 20, 1560),
    PlanDifficulty.advanced,
    'https://pochertezhu.ru/project/trehstvorchatye-skladnye-stavni-dlya-terrasy/',
  ),
  lantern.plan(
    TemplateCategory.garden,
    FinishPreset.wood,
    (480, 340, 990),
    PlanDifficulty.medium,
    'https://pochertezhu.ru/project/bolshoy-dekorativnyy-fonar-dlya-terrasy/',
  ),
  mirrorFrame.plan(
    TemplateCategory.construction,
    FinishPreset.wood,
    (486, 190, 1727),
    PlanDifficulty.medium,
    'https://pochertezhu.ru/project/napolnoe-zerkalo-v-derevyannoy-rame/',
  ),
  hexShelf.plan(
    TemplateCategory.shelving,
    FinishPreset.wood,
    (2 * (178 + 76 / _sqrt3), 184, 178 * _sqrt3 + 76),
    PlanDifficulty.medium,
    'https://pochertezhu.ru/project/shestiugolnye-nastennye-polki/',
  ),
  coffeeTable.plan(
    TemplateCategory.tables,
    FinishPreset.wood,
    (1000, 400, 400),
    PlanDifficulty.medium,
    'https://pochertezhu.ru/project/kompaktnyy-zhurnalnyy-stolik-s-nizhney-polkoy/',
  ),
  shoeBench.plan(
    TemplateCategory.seating,
    FinishPreset.plywood,
    (1000, 330, 465),
    PlanDifficulty.easy,
    'https://novamett.ru/polki/napolnaya-polka-svoimi-rukami-foto#:~:text=Полка%20скамейка%20для%20обуви',
  ),
  trivet.plan(
    TemplateCategory.household,
    FinishPreset.wood,
    (156, 156, 14),
    PlanDifficulty.easy,
    'https://saw-man.ru/patterns/download/477',
  );

  const FurnitureTemplate(
    this.category,
    this.material,
    this.metric, [
    this._imperial,
  ]) : source = null,
       difficulty = null;

  const FurnitureTemplate.plan(
    this.category,
    this.material,
    this.metric,
    this.difficulty,
    this.source,
  ) : _imperial = null;
  final String? source;
  final PlanDifficulty? difficulty;
  final TemplateCategory category;
  final FinishPreset material;
  final (double, double, double) metric;
  final (double, double, double)? _imperial;
  (double, double, double) get imperial =>
      _imperial ?? (metric.$1 / 25.4, metric.$2 / 25.4, metric.$3 / 25.4);

  String get title => switch (this) {
    laptopTray => editorStrings.templateLaptopTray,
    bagShelf => editorStrings.templateBagShelf,
    pantryShelf => editorStrings.templatePantryShelf,
    consoleTable => editorStrings.templateConsoleTable,
    bathTray => editorStrings.templateBathTray,
    machineStand => editorStrings.templateMachineStand,
    trestleBench => editorStrings.templateTrestleBench,
    windowBox => editorStrings.templateWindowBox,
    birdhouse => editorStrings.templateBirdhouse,
    candleShelf => editorStrings.templateCandleShelf,
    blanketLadder => editorStrings.templateBlanketLadder,
    headphoneStand => editorStrings.templateHeadphoneStand,
    plantPanel => editorStrings.templatePlantPanel,
    toyChest => editorStrings.templateToyChest,
    shutters => editorStrings.templateShutters,
    lantern => editorStrings.templateLantern,
    mirrorFrame => editorStrings.templateMirrorFrame,
    hexShelf => editorStrings.templateHexShelf,
    coffeeTable => editorStrings.templateCoffeeTable,
    shoeBench => editorStrings.templateShoeBench,
    trivet => editorStrings.templateTrivet,
    signatureCabinet => editorStrings.templateSignatureCabinet,
    bookcase => editorStrings.templateBookcase,
    cubeShelf => editorStrings.templateCubeShelf,
    wallShelf => editorStrings.templateWallShelf,
    bench => editorStrings.bench,
    stool => editorStrings.templateStool,
    stepStool => editorStrings.templateStepStool,
    gardenBench => editorStrings.templateGardenBench,
    diningTable => editorStrings.templateDiningTable,
    writingDesk => editorStrings.templateWritingDesk,
    bedsideCabinet => editorStrings.templateBedsideCabinet,
    bedroomWardrobe => editorStrings.templateBedroomWardrobe,
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
    bagShelf => editorStrings.planHardwareHooks,
    shutters => editorStrings.planShutterNote,
    blanketLadder => editorStrings.planLadderNote,
    mirrorFrame => editorStrings.planMirrorNote,
    toyChest => editorStrings.planChestNote,
    trivet => editorStrings.planTrivetNote,
    headphoneStand ||
    lantern ||
    toolTote ||
    shoeBench => editorStrings.planRoundedNote,
    gazebo => editorStrings.gazeboFrameNote,
    logStore => editorStrings.roofNote,
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
      case bench:
        return Project.bench().copy(unit: unit);
      case laptopTray:
        parts.laptopTrayPlan();
      case bagShelf:
        parts.bagShelfPlan();
      case pantryShelf:
        parts.pantryShelfPlan();
      case consoleTable:
        parts.consoleTablePlan();
      case bathTray:
        parts.bathTrayPlan();
      case machineStand:
        parts.machineStandPlan();
      case trestleBench:
        parts.trestleBenchPlan();
      case windowBox:
        parts.windowBoxPlan();
      case birdhouse:
        parts.birdhousePlan();
      case candleShelf:
        parts.candleShelfPlan();
      case blanketLadder:
        parts.blanketLadderPlan();
      case headphoneStand:
        parts.headphoneStandPlan();
      case plantPanel:
        parts.plantPanelPlan();
      case toyChest:
        parts.toyChestPlan();
      case shutters:
        parts.shuttersPlan();
      case lantern:
        parts.lanternPlan();
      case mirrorFrame:
        parts.mirrorFramePlan();
      case hexShelf:
        parts.hexShelfPlan();
      case coffeeTable:
        parts.coffeeTablePlan();
      case shoeBench:
        parts.shoeBenchPlan();
      case trivet:
        parts.trivetPlan();
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
      case stool:
        parts.stoolPlan();
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
        parts.gardenBenchPlan();
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
      case toolTote:
        parts.toolTotePlan();
      case picnicTable:
        parts.picnicTablePlan();
      case sawhorse:
        parts.sawhorse();
      case clampRack:
        parts.clampRack();
      case raisedBed:
        parts.raisedBed();
      case standingPlanter:
        parts.standingPlanterPlan();
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
