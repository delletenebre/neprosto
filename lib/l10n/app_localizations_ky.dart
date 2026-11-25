// ignore_for_file: deprecated_member_use

// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Kirghiz Kyrgyz (`ky`).
class AppLocalizationsKy extends AppLocalizations {
  AppLocalizationsKy([String locale = 'ky']) : super(locale);

  @override
  String get partFinish => 'Материал';

  @override
  String get mixedValues => 'Ар түрдүү';

  @override
  String get finishPresets => 'Даяр үлгүлөр';

  @override
  String get chooseFinishPreset => 'Үлгү тандоо';

  @override
  String get pineColor => 'Карагай';

  @override
  String get oakColor => 'Эмен';

  @override
  String get whiteColor => 'Ак';

  @override
  String get grayColor => 'Боз';

  @override
  String get graphiteColor => 'Графит';

  @override
  String get beigeColor => 'Ачык күрөң';

  @override
  String get blackColor => 'Кара';

  @override
  String get greenColor => 'Жашыл';

  @override
  String get blueColor => 'Көк';

  @override
  String get brickColor => 'Кыш кызыл';

  @override
  String get finishTexture => 'Текстура';

  @override
  String get finishColor => 'Түс';

  @override
  String get metal => 'Металл';

  @override
  String get solidColor => 'Бир түстүү';

  @override
  String get naturalWood => 'Жыгач';

  @override
  String get whiteBoard => 'Ак ЛДСП';

  @override
  String get oakBoard => 'Эмен өңдүү ЛДСП';

  @override
  String get aluminumProfile => 'Алюминий профили';

  @override
  String get steelProfile => 'Болот профили · графит';

  @override
  String get invalidPartFinish => 'Тетиктин материалы жараксыз';

  @override
  String get invalidHexColor => 'Түстү #RRGGBB форматында киргизиңиз';

  @override
  String get positiveThickness => '+К';

  @override
  String get positiveWidth => '+Т';

  @override
  String get xWidth => 'X · туурасы';

  @override
  String get horizontalPlane => 'Туурасынан';

  @override
  String get workPlanePurpose =>
      'Деталдарды кайсы тегиздикте чийип, жылдырасыз?';

  @override
  String get horizontalPlaneExample => 'Текче же үстөлдүн үстү сыяктуу';

  @override
  String get frontPlaneExample => 'Шкафтын эшиги сыяктуу';

  @override
  String get sidePlaneExample => 'Шкафтын каптал дубалы сыяктуу';

  @override
  String get partFacePlane => 'Деталдын бети боюнча';

  @override
  String get workPlaneNeedsPart => 'Чиймеде көрүнгөн деталь болушу керек';

  @override
  String get yDepth => 'Y · тереңдиги';

  @override
  String get zHeight => 'Z · бийиктиги';

  @override
  String edgeCaption(Object side) {
    return '$side\nкыр';
  }

  @override
  String scrollGesture(Object modifier) {
    return '$modifier + чычкандын дөңгөлөгү';
  }

  @override
  String sketchEndHint(
    Object part,
    Object width,
    Object thickness,
    Object unit,
  ) {
    return '$part · $width × $thickness $unit · аяккы чекитти белгилеңиз';
  }

  @override
  String liftHint(Object instruction, Object modifier) {
    return '$instruction · $modifier менен көтөрүңүз · Z огу боюнча жылдыруу үчүн Shift басыңыз';
  }

  @override
  String endAngleValue(Object end, Object angle) {
    return '$end · тик кесимден $angle° четтөө';
  }

  @override
  String unsavedTab(Object name) {
    return '$name · Сакталбаган өзгөртүүлөр';
  }

  @override
  String depthDirection(Object axis) {
    return '$axis · тереңдик боюнча';
  }

  @override
  String heightGesture(Object mode) {
    return '$mode · бийиктикти коюу үчүн көрсөткүчтү өйдө жылдырыңыз';
  }

  @override
  String placeEndHint(Object mode) {
    return '$mode · тетиктин учун белгилөө үчүн чыкылдатыңыз';
  }

  @override
  String resizeLockHint(Object action, Object dimension) {
    return '$dimension · өлчөмүн өзгөртүүнү $action';
  }

  @override
  String pieceCount(Object count) {
    return '$count даана';
  }

  @override
  String partsFilename(Object name) {
    return '$name — тетиктердин тизмеси';
  }

  @override
  String get automatic => 'Авто';

  @override
  String get autosave => 'Автосактоо';

  @override
  String get axonometric => 'Аксонометрия';

  @override
  String get untitled => 'Аталышы жок';

  @override
  String numberedUntitled(Object number) {
    return 'Аталышы жок $number';
  }

  @override
  String get lock => 'кулпулоо';

  @override
  String get partLocks => 'Тетик кулпулары';

  @override
  String get side => 'Каптал';

  @override
  String get inTheThicknessPlane => 'Калыңдык тегиздигинде';

  @override
  String get inTheWidthPlane => 'Туурасы боюнча тегиздикте';

  @override
  String get thisProjectHasNoPartsYet => 'Долбоордо азырынча тетик жок';

  @override
  String get noStopInThisDirection => 'Бул багытта таяныч жок';

  @override
  String get invalidInsideAngle =>
      'Ички бурчту 0° менен 180° ортосунда киргизиңиз';

  @override
  String get positiveIntegerHint => 'Бир же андан чоң бүтүн сан киргизиңиз.';

  @override
  String get up => 'Өйдө';

  @override
  String get vertical => 'Тик';

  @override
  String get cubeTop => 'Үстү';

  @override
  String get upper => 'Үстүңкү';

  @override
  String get fixedDimensionsFillSpan =>
      'Бүт аралыкты бекитилген өлчөмдөр ээлейт';

  @override
  String get view => 'Көрүнүш';

  @override
  String get views => 'Көрүнүштөр';

  @override
  String get gridVisibility => 'Тордун көрүнүшү';

  @override
  String get left => 'Солго';

  @override
  String get down => 'Ылдый';

  @override
  String get insideAngle => 'Ички бурч';

  @override
  String get fitToWindow => 'Терезеге батыруу';

  @override
  String fitShortcut(Object shortcut) {
    return 'Терезеге батыруу · $shortcut';
  }

  @override
  String get right => 'Оңго';

  @override
  String get alwaysVisible => 'Дайыма көрүнөт';

  @override
  String get shortcutKeyHint =>
      'Тамганы, санды, жебени же функция баскычын тандаңыз';

  @override
  String get selectTheSecondShelf => 'Экинчи текчени тандаңыз';

  @override
  String get selectWorkPlaneFace => 'Чиймедеги деталдын керектүү бетин басыңыз';

  @override
  String get chooseParallelShelf =>
      'Проекциясы кесилишкен жана бети параллелдүү башка текчени тандаңыз';

  @override
  String get chooseAlignmentHint =>
      'Эки тетиктен бирден чекит тандаңыз же панелден тегиздөөнү жөндөңүз';

  @override
  String get chooseMovingAnchor =>
      '2 / 2. Жылдырыла турган тетиктен чекит тандаңыз.';

  @override
  String get selectAnAnchorOnThePart => 'Тетиктеги таяныч чекитин тандаңыз';

  @override
  String get chooseAReference => 'Таянычты тандоо…';

  @override
  String get selectTheFirstShelf => 'Биринчи текчени тандаңыз';

  @override
  String get selectParts => 'Тетиктерди тандоо';

  @override
  String selectedParts(Object count) {
    return 'Тандалган тетиктер · $count';
  }

  @override
  String selectShortcut(Object shortcut) {
    return 'Тандоо · $shortcut';
  }

  @override
  String get selectAllParts => 'Бардык тетиктерди тандоо';

  @override
  String get chooseReferenceFromList => 'Тизмеден таяныч тетикти тандаңыз';

  @override
  String get alignment => 'Тегиздөө';

  @override
  String get alignToReference => 'Таянычка тегиздөө…';

  @override
  String overallSizeMustExceed(Object size, Object unit) {
    return 'Жалпы өлчөм $size $unit чоң болушу керек';
  }

  @override
  String get projectBounds => 'Долбоордун чектери';

  @override
  String get assemblyDimensions => 'Чогултманын өлчөмдөрү';

  @override
  String get keyboardShortcuts => 'Ыкчам баскычтар';

  @override
  String get done => 'Даяр';

  @override
  String get resizeProducts => 'Буюмдардын өлчөмдөрүн өзгөртүү';

  @override
  String get face => 'Бет';

  @override
  String get shelfFace => 'Текченин бети';

  @override
  String numberedGroup(Object number) {
    return 'Топ $number';
  }

  @override
  String get lengthInitial => 'У';

  @override
  String get twoPoints => 'Эки чекит';

  @override
  String get moveAndResizeInIncrements =>
      'Кадам менен жылдыруу жана өлчөмүн өзгөртүү';

  @override
  String get partsTree => 'Тетиктер дарагы';

  @override
  String partCount(Object count) {
    return 'Тетиктер · $count';
  }

  @override
  String get partsLabel => 'Тетиктер';

  @override
  String partsTabCount(Object count) {
    return 'Тетиктер  $count';
  }

  @override
  String get assemblyParts => 'Буюмдун тетиктери';

  @override
  String get noMatchingParts => 'Тетиктер табылган жок';

  @override
  String get part => 'Тетик';

  @override
  String numberedPart(Object id) {
    return 'Тетик $id';
  }

  @override
  String get thePartIntersectsItsReference => 'Тетик таянычты кесип өтөт';

  @override
  String get alreadyTouchesReferences => 'Тетик эки таянычка тең тийип турат';

  @override
  String get length => 'Узундугу';

  @override
  String get stockLength => 'Даярдаманын узундугу';

  @override
  String stockLengthInUnits(Object unit) {
    return 'Даярдаманын узундугу, $unit';
  }

  @override
  String get lengthTooShortForCuts => 'Узундук кесимдердин айырмасынан аз';

  @override
  String shortAndLongEdgeLengths(Object unit) {
    return 'Кыска жана узун кырлардын узундугу, $unit';
  }

  @override
  String get matchingSectionsRequired =>
      'Симметриялуу бириктирүү үчүн бирдей кесилиштерди тандаңыз';

  @override
  String bothStops(Object first, Object second) {
    return 'Таянычтарга чейин · $first жана $second';
  }

  @override
  String get upToNextStop => 'Өйдө таянычка чейин';

  @override
  String get leftToNextStop => 'Солго таянычка чейин';

  @override
  String get downToNextStop => 'Ылдый таянычка чейин';

  @override
  String get rightToNextStop => 'Оңго таянычка чейин';

  @override
  String get addASecondPartToAlignThem =>
      'Тегиздөө үчүн экинчи тетикти кошуңуз';

  @override
  String get duplicate => 'Көчүрмөсүн түзүү';

  @override
  String get inches => 'Дюйм';

  @override
  String discardChangesWarning(Object name) {
    return '«$name» долбоорун жапсаңыз, акыркы өзгөртүүлөр жоголот.';
  }

  @override
  String get stockPiece => 'Даярдама';

  @override
  String get stockTooShort => 'Даярдама бул кесим үчүн өтө кыска';

  @override
  String get stock => 'Даярдамалар';

  @override
  String get cubeBack => 'Арты';

  @override
  String get rear => 'Арткы';

  @override
  String get backEdge => 'Арткы кыр';

  @override
  String gap(Object distance, Object unit) {
    return 'Аралык $distance $unit';
  }

  @override
  String get closeTab => 'Өтмөктү жабуу';

  @override
  String closeProjectTab(String name) {
    return '«$name» өтмөгүн жабуу';
  }

  @override
  String get closeGridSettings => 'Тор жөндөөлөрүн жабуу';

  @override
  String get closePartDimensions => 'Тетиктин өлчөмдөрүн жабуу';

  @override
  String miterEndAngle(Object angle) {
    return 'Ар бир учун тик кесимден $angle° кыйшайтып кесүү';
  }

  @override
  String get autosaveFilesHint =>
      'Өзгөртүүлөр ачык долбоорлордун файлдарына жазылат. Жаңы долбоорлор жергиликтүү каралама катары сакталат.';

  @override
  String measureShortcut(Object shortcut) {
    return 'Өлчөө · $shortcut';
  }

  @override
  String get measureDistance => 'Аралыкты өлчөө';

  @override
  String get tools => 'Куралдар';

  @override
  String get intervalMin => 'Аралыгы, мүн';

  @override
  String get excelWorkbook => 'Excel китеби';

  @override
  String get qty => 'Саны';

  @override
  String get quantityPcs => 'Саны, даана';

  @override
  String get endPoint => 'Аягы';

  @override
  String get endCut => 'Аяккы кесим';

  @override
  String edges(Object lengths, Object unit) {
    return 'Кырлар · $lengths $unit';
  }

  @override
  String get cubeLeft => 'Солу';

  @override
  String get leftHand => 'Сол';

  @override
  String get ruler => 'Сызгыч';

  @override
  String get zoom => 'Масштаб';

  @override
  String get actionsMenu => 'Аракеттер менюсу';

  @override
  String get precision => 'Тактык';

  @override
  String get anglePrecision => 'Бурчтардын тактыгы';

  @override
  String get editingIncrement => 'Түзөтүү кадамы';

  @override
  String get measurementUnits => 'Өлчөө бирдиктери';

  @override
  String get millimeters => 'Миллиметр';

  @override
  String get onDrawing => 'Чиймеден';

  @override
  String get pressKeys => 'Баскычтарды басыңыз…';

  @override
  String get recordShortcutHint =>
      'Айкалышты тандап, жаңы баскычтарды басыңыз. Esc киргизүүнү жокко чыгарат.';

  @override
  String get rotationInputHint =>
      '90° буруу үчүн жебени басыңыз же бурчту киргизиңиз';

  @override
  String get partName => 'Тетиктин аталышы';

  @override
  String get groupName => 'Топтун аталышы';

  @override
  String get nameAndDimensions => 'Аталышы жана өлчөмдөрү…';

  @override
  String get projectName => 'Долбоордун аталышы';

  @override
  String get assign => 'Дайындоо';

  @override
  String searchMatches(Object found, Object total) {
    return '$total ичинен $found табылды';
  }

  @override
  String get findAPart => 'Тетик издөө';

  @override
  String get tiltInAVerticalPlane => 'Тик тегиздикте жантайтуу';

  @override
  String get direction => 'Багыт';

  @override
  String get settings => 'Жөндөөлөр';

  @override
  String get projectSettings => 'Долбоордун жөндөөлөрү';

  @override
  String get projectSettingsMenu => 'Долбоордун жөндөөлөрү…';

  @override
  String get start => 'Башы';

  @override
  String get startCut => 'Баштапкы кесим';

  @override
  String get discardChanges => 'Сактабай жабуу';

  @override
  String get draftSaveError => 'Каралама сакталган жок';

  @override
  String get updateProjectError =>
      'Файл жаңыртылган жок. «Башкача сактоо…» буйругун колдонуңуз.';

  @override
  String get draftOpenError => 'Жергиликтүү каралама ачылган жок';

  @override
  String get openProjectError => 'Долбоордун файлы ачылган жок';

  @override
  String get gridSaveError => 'Тордун көрүнүшү сакталган жок';

  @override
  String get settingsSaveError => 'Жөндөөлөр сакталган жок';

  @override
  String get saveProjectError =>
      'Долбоор сакталган жок. «Башкача сактоо…» буйругун колдонуңуз.';

  @override
  String get snapSaveError => 'Жабыштыруу режими сакталган жок';

  @override
  String get workbookSaveError =>
      'Excel файлы сакталган жок. Кайра аракет кылыңыз.';

  @override
  String get unknownProjectFormat => 'Долбоордун форматы белгисиз';

  @override
  String get invalidPartGeometry => 'Тетиктин геометриясы жараксыз';

  @override
  String get invalidFace => 'Жараксыз бет';

  @override
  String get invalidVector => 'Жараксыз вектор';

  @override
  String get invalidWorkspaceDimensions => 'Иш аймагынын өлчөмдөрү жараксыз';

  @override
  String get invalidEndCut => 'Тетиктин учу жараксыз';

  @override
  String get invalidCorner => 'Жараксыз бурч';

  @override
  String get noOverlappingProjection => 'Проекциялар кесилишпейт';

  @override
  String get noOpenProjects => 'Ачык долбоор жок';

  @override
  String get lower => 'Астыңкы';

  @override
  String get cubeBottom => 'Асты';

  @override
  String get newPart => 'Жаңы тетик';

  @override
  String get newDimension => 'Жаңы өлчөм';

  @override
  String get centerCamera => 'Ортого келтирүү';

  @override
  String get renameDimension => 'Өлчөмдүн атын өзгөртүү';

  @override
  String selectDimensionHint(String shortcut) {
    return 'Чиймеден өлчөмдү тандаңыз же жаңы өлчөм кошуу үчүн $shortcut басыңыз';
  }

  @override
  String get newPartWithDimensions => 'Өлчөмдөрү боюнча жаңы тетик';

  @override
  String get choosePartPosition => 'Ордун тандоо';

  @override
  String get placePartHint =>
      'Тетикти коюу үчүн керектүү жерди басыңыз. Жокко чыгаруу үчүн Esc басыңыз.';

  @override
  String get hiddenParts => 'Жашырылган тетиктер';

  @override
  String get hideCompletely => 'Толугу менен жашыруу';

  @override
  String get showOutlines => 'Контурларын көрсөтүү';

  @override
  String get hidePart => 'Тетикти жашыруу';

  @override
  String get hideGroupParts => 'Топтогу бардык тетиктерди жашыруу';

  @override
  String get showGroupParts => 'Топтогу бардык тетиктерди көрсөтүү';

  @override
  String get hideSelectedParts => 'Тандалган тетиктерди жашыруу';

  @override
  String get showPart => 'Тетикти көрсөтүү';

  @override
  String get showAllParts => 'Бардык жашырылган тетиктерди көрсөтүү';

  @override
  String newPartShortcut(Object shortcut) {
    return 'Жаңы тетик · $shortcut';
  }

  @override
  String get newPartHere => 'Бул жерге жаңы тетик';

  @override
  String get newProject => 'Жаңы долбоор';

  @override
  String leg(Object number) {
    return 'Бут $number';
  }

  @override
  String get referencesAreNeededOnBothSides => 'Эки тараптан тең таяныч керек';

  @override
  String get reverseDirection => 'Багытты тескерилөө';

  @override
  String get anchor => 'Таяныч';

  @override
  String anchorLabel(Object mode) {
    return 'Таяныч · $mode';
  }

  @override
  String get referencePart => 'Таяныч тетик';

  @override
  String get partAxes => 'Тетиктин октору';

  @override
  String get projectAxes => 'Долбоордун октору';

  @override
  String axis(Object axis) {
    return '$axis огу';
  }

  @override
  String get zoomOut => 'Кичирейтүү';

  @override
  String get open => 'Ачуу';

  @override
  String get newTab => 'Жаңы өтмөк';

  @override
  String get recentProjects => 'Акыркы долбоорлор';

  @override
  String get noRecentProjects => 'Азырынча акыркы долбоорлор жок';

  @override
  String get openProject => 'Долбоорду ачуу';

  @override
  String get openProjectMenu => 'Долбоорду ачуу…';

  @override
  String get cancel => 'Жокко чыгаруу';

  @override
  String get undo => 'Артка кайтаруу';

  @override
  String get undoAction => 'Аракетти артка кайтаруу';

  @override
  String get offset => 'Чегинүү';

  @override
  String referenceEdgeOffset(Object edge) {
    return 'Таянычтын $edge чегинүү';
  }

  @override
  String get clearSearch => 'Издөөнү тазалоо';

  @override
  String get rightClick => 'Оң баскыч';

  @override
  String get moveResizeHint =>
      'Тетикти жылдыруу үчүн сүйрөңүз. Өлчөмүн өзгөртүү үчүн Shift басып, кырын сүйрөңүз.';

  @override
  String get cubeFront => 'Алды';

  @override
  String get frontFacing => 'Алдыңкы';

  @override
  String get frontEdge => 'Алдыңкы кыр';

  @override
  String get renamePart => 'Тетиктин атын өзгөртүү';

  @override
  String get renameGroup => 'Топтун атын өзгөртүү';

  @override
  String get rename => 'Атын өзгөртүү…';

  @override
  String moveShortcut(Object shortcut) {
    return 'Жылдыруу · $shortcut';
  }

  @override
  String anchorShortcut(Object shortcut) {
    return 'Таянычка жайгаштыруу · $shortcut';
  }

  @override
  String get movementAndRuler => 'Жылдыруу жана сызгыч';

  @override
  String get movementAndResizing => 'Жылдыруу жана өлчөмүн өзгөртүү';

  @override
  String get intersection => 'Кесилиш';

  @override
  String get intersections => 'Кесилиштер';

  @override
  String intersectionsLabel(Object count) {
    return 'Кесилиштер · $count';
  }

  @override
  String get perspective => 'Перспектива';

  @override
  String seatSlat(Object number) {
    return 'Отургучтун тактайчасы $number';
  }

  @override
  String get plane => 'Тегиздик';

  @override
  String get buildInThisPlane => 'Ушул тегиздикте куруу';

  @override
  String get edgeAligned => 'Кырга тегизделди';

  @override
  String get byAxes => 'Октор боюнча';

  @override
  String get alongThickness => 'Калыңдыгы боюнча';

  @override
  String get alongWidth => 'Туурасы боюнча';

  @override
  String get rotate => 'Буруу';

  @override
  String get orbitView => 'Көрүнүштү буруу';

  @override
  String get rotatePart => 'Тетикти буруу';

  @override
  String get rotateMenu => 'Буруу…';

  @override
  String get rotation => 'Бурулуш';

  @override
  String rotateShortcut(Object shortcut) {
    return 'Буруу · $shortcut';
  }

  @override
  String get brokenPartReferences => 'Тетиктерге шилтемелер бузулган';

  @override
  String get redo => 'Кайра аткаруу';

  @override
  String get redoAction => 'Аракетти кайталоо';

  @override
  String get showHideDimensions => 'Өлчөмдөрдү көрсөтүү / жашыруу';

  @override
  String get showDimensions => 'Өлчөмдөрдү көрсөтүү';

  @override
  String get floor => 'Пол';

  @override
  String get partOffsets => 'Чегинүүлөр';

  @override
  String get xFromLeft => 'X · сол жактан';

  @override
  String get yFromBack => 'Y · дубалдан';

  @override
  String get zFromFloor => 'Z · полдон';

  @override
  String crossRail(Object number) {
    return 'Туурасынан кеткен керме $number';
  }

  @override
  String get placeAgainstReference => 'Таянычка жайгаштыруу';

  @override
  String get cubeRight => 'Оңу';

  @override
  String get rightHand => 'Оң';

  @override
  String get multiSelectionMenuHint =>
      'Тандалган тетиктердин баарына аракет кылуу үчүн оң баскычты басыңыз';

  @override
  String get continuousDragHint =>
      'Сүйрөгөндө тетиктин орду жана өлчөмү бир калыпта өзгөрөт.';

  @override
  String get zoomIn => 'Чоңойтуу';

  @override
  String rulerSnapModifier(Object modifier) {
    return '$modifier баспай эле сызгычты жабыштыруу';
  }

  @override
  String get snapLabel => 'Жабыштыруу';

  @override
  String get snapToAnchors => 'Таянычтарга жабыштыруу';

  @override
  String get apply => 'Колдонуу';

  @override
  String get spaceLeftClick => 'Боштук + сол баскыч';

  @override
  String get checkTheExpression => 'Туюнтманы текшериңиз';

  @override
  String sideRail(Object number) {
    return 'Узунунан кеткен керме $number';
  }

  @override
  String get project => 'Долбоор';

  @override
  String get neprostoProject => 'NeProSto долбоору';

  @override
  String get projectSaved => 'Долбоор сакталды';

  @override
  String get clearance => 'Таза аралык';

  @override
  String clearanceLabel(Object distance, Object unit) {
    return 'Таза аралык · $distance $unit';
  }

  @override
  String get square => 'Тик';

  @override
  String get drawingControls => 'Чиймени башкаруу';

  @override
  String get workPlane => 'Иш тегиздиги';

  @override
  String workPlaneLabel(Object plane) {
    return 'Иш тегиздиги · $plane';
  }

  @override
  String equalGapValue(Object distance, Object unit) {
    return 'Бирдей аралыктар · $distance $unit';
  }

  @override
  String get unlock => 'кулпудан чыгаруу';

  @override
  String get ungroup => 'Топтон чыгаруу';

  @override
  String get dimension => 'Өлчөм';

  @override
  String get dimensionLocked => 'Өлчөм кулпуланган';

  @override
  String dimensionTabCount(Object count) {
    return 'Өлчөмдөр  $count';
  }

  @override
  String get partDimensions => 'Тетиктин өлчөмдөрү';

  @override
  String get dimensionsOnDrawing => 'Чиймедеги өлчөмдөр';

  @override
  String get endMarkings => 'Учтарды белгилөө';

  @override
  String get stretchToHeight => 'Бийиктиги боюнча созуу';

  @override
  String get stretchToWidth => 'Туурасы боюнча созуу';

  @override
  String get editing => 'Түзөтүү';

  @override
  String get modeWithoutModifierKeys => 'Кошумча баскычтарсыз режим';

  @override
  String get snapping => 'Жабыштыруу';

  @override
  String get centimeters => 'Сантиметр';

  @override
  String get resetShortcuts => 'Айкалыштарды баштапкы абалына кайтаруу';

  @override
  String get viewTop => 'Үстүнөн';

  @override
  String get free => 'Эркин';

  @override
  String get freeView => 'Эркин көрүнүш';

  @override
  String get properties => 'Касиеттер';

  @override
  String get groupLabel => 'Топтоо';

  @override
  String get nudge => 'Жылдырыш';

  @override
  String nudgeDistance(Object distance, Object unit) {
    return 'Жылдырыш · $distance $unit';
  }

  @override
  String get panView => 'Көрүнүштү жылдыруу';

  @override
  String get center => 'Ортосу';

  @override
  String get edgeMidpoint => 'Кырдын ортосу';

  @override
  String get rulerEdge => 'Кыр';

  @override
  String get rulerUpperEdge => 'Үстүңкү кыр';

  @override
  String get rulerLowerEdge => 'Астыңкы кыр';

  @override
  String get rulerCenterline => 'Беттин орто сызыгы';

  @override
  String get viewBack => 'Артынан';

  @override
  String get bench => 'Отургуч';

  @override
  String get downloadStarted => 'Жүктөө башталды';

  @override
  String get hideDimensions => 'Өлчөмдөрдү жашыруу';

  @override
  String get viewLeft => 'Солдон';

  @override
  String get partDimensionIsTooSmall => 'Тетиктин өлчөмү өтө кичине';

  @override
  String changeShortcutFor(Object command) {
    return '«$command» үчүн айкалышты өзгөртүү';
  }

  @override
  String get viewBottom => 'Астынан';

  @override
  String get join => 'Бириктирүү';

  @override
  String get saving => 'Сактоо';

  @override
  String get save => 'Сактоо';

  @override
  String get saveChanges => 'Өзгөртүүлөр сакталсынбы?';

  @override
  String get saveAs => 'Башкача сактоо…';

  @override
  String get saveProject => 'Долбоорду сактоо';

  @override
  String get saveProjectsAutomatically =>
      'Долбоорлорду автоматтык түрдө сактоо';

  @override
  String get viewFront => 'Алдынан';

  @override
  String get partsList => 'Тетиктердин тизмеси';

  @override
  String get viewRight => 'Оңдон';

  @override
  String stepExample(
    Object step,
    Object unit,
    Object examples,
    Object exampleUnit,
  ) {
    return 'Жебе тетикти $step $unit жылдырат. Өлчөмү кадам менен өзгөрөт, мисалы $examples $exampleUnit.';
  }

  @override
  String get straightUpAlongZ => 'Z огу боюнча тик өйдө';

  @override
  String get thicknessInitial => 'К';

  @override
  String get thickness => 'Калыңдыгы';

  @override
  String thicknessLabel(Object unit) {
    return 'Калыңдыгы, $unit';
  }

  @override
  String onlyWith(Object modifier) {
    return '$modifier менен гана';
  }

  @override
  String get ends => 'Учтары';

  @override
  String get dragWithRightButton => 'Оң баскыч менен сүйрөө';

  @override
  String get removeBounds => 'Чектерди алып салуу';

  @override
  String get miterJoint => 'Кыйгач бирикме';

  @override
  String get miterJointMenu => 'Кыйгач бирикме…';

  @override
  String get corner => 'Бурч';

  @override
  String get delete => 'Өчүрүү';

  @override
  String get deleteDimension => 'Өлчөмдү өчүрүү';

  @override
  String holdToSnap(Object modifier) {
    return 'Жабыштыруу үчүн $modifier басып туруңуз.';
  }

  @override
  String freeMovementHint(Object modifier) {
    return 'Байлоону убактылуу өчүрүү үчүн $modifier басып туруңуз.';
  }

  @override
  String holdDimensionModifier(Object modifier, Object action) {
    return 'Өлчөмдөрдү $action үчүн $modifier басып туруңуз.';
  }

  @override
  String hold(Object modifier) {
    return '$modifier басып туруу';
  }

  @override
  String alreadyAssignedTo(Object command) {
    return '«$command» үчүн мурунтан дайындалган';
  }

  @override
  String get setTheSecondDimensionPoint => 'Өлчөмдүн экинчи чекитин белгилеңиз';

  @override
  String get setTheSourceAnchorOnThePart =>
      '1/2. Жылдыра турган тетиктеги баштапкы чекитти басыңыз.';

  @override
  String get setTheEndOfThePart => 'Тетиктин учун белгилеңиз';

  @override
  String get setTheStartOfThePart => 'Тетиктин башын белгилеңиз';

  @override
  String get setTheDestinationAnchor =>
      '2/2. Ошол чекитти жайгаштыра турган жерди басыңыз.';

  @override
  String get setTheFirstDimensionPoint => 'Өлчөмдүн биринчи чекитин белгилеңиз';

  @override
  String get pickReferenceOnDrawing => 'Таянычты чиймеден тандоо';

  @override
  String stop(Object part) {
    return 'Таяныч · $part';
  }

  @override
  String get excelFileSaved => 'Excel файлы сакталды';

  @override
  String get frontPlane => 'Маңдайкы';

  @override
  String get rearPlane => 'Арткы';

  @override
  String get centerPoint => 'Борбор';

  @override
  String get faceCenter => 'Беттин борбору';

  @override
  String get partCenter => 'Тетиктин борбору';

  @override
  String get brusDrafts => 'Брус караламалары';

  @override
  String get browserDraftsHint =>
      'Ачык өтмөктөрдүн караламалары ушул браузерде сакталат.';

  @override
  String get drawing => 'Чийме';

  @override
  String addPartHint(Object shortcut) {
    return 'Тетик кошуу үчүн $shortcut басыңыз';
  }

  @override
  String get widthInitial => 'Т';

  @override
  String step(Object increment) {
    return 'Кадам $increment';
  }

  @override
  String get width => 'Туурасы';

  @override
  String widthLabel(Object unit) {
    return 'Туурасы, $unit';
  }

  @override
  String get clickAReferenceInTheDrawingOr =>
      'Чиймедеги таянычты басыңыз же аны тизмеден тандаңыз.';

  @override
  String get clickTheReferencePart => 'Таяныч тетикти басыңыз';

  @override
  String get exportToExcel => 'Excel форматына чыгаруу';

  @override
  String get reservedShortcut =>
      'Бул айкалыш тутумга таандык. Башкасын тандаңыз.';

  @override
  String get fileAlreadyOpen => 'Бул файл башка өтмөктө ачык';

  @override
  String get off => 'өчүк';

  @override
  String get leftReferenceEdge => 'сол кырынан';

  @override
  String get mm => 'мм';

  @override
  String get bottomReferenceEdge => 'астыңкы кырынан';

  @override
  String get frontReferenceEdge => 'алдыңкы кырынан';

  @override
  String get show => 'көрсөтүү';

  @override
  String get hide => 'жашыруу';

  @override
  String get cm => 'см';

  @override
  String get negativeThickness => '−К';

  @override
  String get negativeWidth => '−Т';

  @override
  String get close => 'Жабуу';

  @override
  String get appearance => 'Көркөмдөлүшү';

  @override
  String get theme => 'Тема';

  @override
  String get light => 'Жарык';

  @override
  String get dark => 'Караңгы';

  @override
  String get language => 'Тил';

  @override
  String get aboutNeprosto => 'NeProSto жөнүндө';

  @override
  String get fileMenu => 'Файл';

  @override
  String get settingsMenu => 'Жөндөөлөр…';

  @override
  String get services => 'Кызматтар';

  @override
  String get hideNeprosto => 'NeProSto колдонмосун жашыруу';

  @override
  String get hideOthers => 'Башкаларын жашыруу';

  @override
  String get showAll => 'Баарын көрсөтүү';

  @override
  String get quitNeprosto => 'NeProSto колдонмосунан чыгуу';

  @override
  String get edit => 'Түзөтүү';

  @override
  String get cut => 'Кесүү';

  @override
  String get copy => 'Көчүрүү';

  @override
  String get paste => 'Коюу';

  @override
  String get pasteAndMatchStyle => 'Учурдагы стилде коюу';

  @override
  String get selectAll => 'Баарын тандоо';

  @override
  String get find => 'Издөө';

  @override
  String get findMenu => 'Издөө…';

  @override
  String get findAndReplace => 'Табуу жана алмаштыруу…';

  @override
  String get findNext => 'Кийинкисин табуу';

  @override
  String get findPrevious => 'Мурункусун табуу';

  @override
  String get useSelectionForFind => 'Тандалган текстти издөө';

  @override
  String get jumpToSelection => 'Тандалган жерге өтүү';

  @override
  String get spellingAndGrammar => 'Орфография жана грамматика';

  @override
  String get showSpellingAndGrammar => 'Орфография менен грамматиканы көрсөтүү';

  @override
  String get checkDocumentNow => 'Документти текшерүү';

  @override
  String get checkSpellingWhileTyping => 'Терүүдө орфографияны текшерүү';

  @override
  String get checkGrammarWithSpelling => 'Грамматиканы да текшерүү';

  @override
  String get correctSpellingAutomatically => 'Орфографияны автоматтык оңдоо';

  @override
  String get substitutions => 'Алмаштыруулар';

  @override
  String get showSubstitutions => 'Алмаштырууларды көрсөтүү';

  @override
  String get smartCopyPaste => 'Акылдуу көчүрүү жана коюу';

  @override
  String get smartQuotes => 'Акылдуу тырмакчалар';

  @override
  String get smartDashes => 'Акылдуу сызыкчалар';

  @override
  String get smartLinks => 'Акылдуу шилтемелер';

  @override
  String get dataDetectors => 'Маалыматтарды аныктоо';

  @override
  String get textReplacement => 'Текстти алмаштыруу';

  @override
  String get transformations => 'Өзгөртүүлөр';

  @override
  String get makeUpperCase => 'Баш тамгаларга өткөрүү';

  @override
  String get makeLowerCase => 'Кичине тамгаларга өткөрүү';

  @override
  String get capitalize => 'Сөздөрдү баш тамга менен баштоо';

  @override
  String get speech => 'Кеп';

  @override
  String get startSpeaking => 'Окуп баштоо';

  @override
  String get stopSpeaking => 'Окууну токтотуу';

  @override
  String get enterFullScreen => 'Толук экранга өтүү';

  @override
  String get window => 'Терезе';

  @override
  String get minimize => 'Жыйруу';

  @override
  String get zoomLabel => 'Чоңойтуу';

  @override
  String get bringAllToFront => 'Бардык терезелерди алдыга чыгаруу';

  @override
  String get help => 'Жардам';

  @override
  String get blankProject => 'Бош долбоор';

  @override
  String get createProject => 'Долбоор түзүү';

  @override
  String get plywood => 'Фанера';

  @override
  String get mdf => 'МДФ';

  @override
  String get stockShopping => 'Сатып алынуучу материалдар';

  @override
  String stockOffcut(String size) {
    return 'Кеминде $size калдык жарайт';
  }

  @override
  String stockKerf(String size) {
    return 'Араа кесиги $size · даярдалманын чыныгы өлчөмү';
  }

  @override
  String get stockBoard => 'Тактай';

  @override
  String get stockBar => 'Брус';

  @override
  String get stockSheet => 'Барак';

  @override
  String get shelfPart => 'Текче';

  @override
  String get sidePanel => 'Каптал такта';

  @override
  String get topPanel => 'Үстүңкү такта';

  @override
  String get bottomPanel => 'Түбү';

  @override
  String get dividerPanel => 'Бөлгүч';

  @override
  String get backPanel => 'Арткы такта';

  @override
  String get frontPanel => 'Алдыңкы такта';

  @override
  String get doorPanel => 'Эшик';

  @override
  String get tabletop => 'Үстөл бети';

  @override
  String get seatPanel => 'Отургучтун бети';

  @override
  String get tread => 'Баскыч';

  @override
  String get carryHandle => 'Тутка';

  @override
  String get categoryShelving => 'Текчелер';

  @override
  String get categorySeating => 'Табуреткалар жана отургучтар';

  @override
  String get categoryTables => 'Үстөлдөр';

  @override
  String get categoryCabinets => 'Тумбалар жана шкафтар';

  @override
  String get categoryWorkshop => 'Устакана жана кеңсе';

  @override
  String get templateBookcase => 'Төрт кабаттуу жыгач текче';

  @override
  String get templateCubeShelf => 'Баскычтуу бөлмө бөлгүч текче';

  @override
  String get templateWallShelf => 'Каркасы катылган текче';

  @override
  String get templateStool => 'Гитара үчүн таянычы бар отургуч';

  @override
  String get templateStepStool => 'Эки баскычтуу табуретка';

  @override
  String get templateGardenBench => 'Кол таянгычтуу бакча отургучу';

  @override
  String get templateDiningTable => 'Эки таянычтуу тамактануучу үстөл';

  @override
  String get templateWritingDesk => 'Каптал текчелүү жазуу үстөлү';

  @override
  String get templateBedsideCabinet => 'Эшиктүү жана ачык уячалуу тумба';

  @override
  String get templateBedroomWardrobe => 'Уктоочу бөлмө үчүн үч эшиктүү шкаф';

  @override
  String get openDoor => 'Эшикти ачуу';

  @override
  String get closeDoor => 'Эшикти жабуу';

  @override
  String get panelHoles => 'Тешиктер';

  @override
  String holeSelection(int number, int count) {
    return 'Тешик $number / $count';
  }

  @override
  String get holeReferenceCorner => 'Бурчтан аралык';

  @override
  String get drillingType => 'Тешиктин түрү';

  @override
  String get drillingFace => 'Бургулоо тарабы';

  @override
  String get noPanelHoles => 'Тетикте азырынча тешик жок';

  @override
  String get addHole => 'Тешик кошуу';

  @override
  String get holeName => 'Тешиктин аталышы';

  @override
  String get showHoleNumbers => 'Схемада номерлерди көрсөтүү';

  @override
  String holeDepthRange(String limit) {
    return 'Тереңдик нөлдөн чоң жана тетиктин калыңдыгынан ($limit) кичине болушу керек.';
  }

  @override
  String holeDiameterRange(String limit) {
    return 'Диаметр нөлдөн чоң жана $limit өлчөмүнөн ашпашы керек.';
  }

  @override
  String holeOffsetRange(String minimum, String maximum) {
    return 'Четтен аралык $minimum менен $maximum ортосунда болушу керек.';
  }

  @override
  String get holeDiameter => 'Диаметр';

  @override
  String get throughHole => 'Өтмө';

  @override
  String get blindHole => 'Туюк';

  @override
  String get faceA => 'А жагы';

  @override
  String get faceB => 'Б жагы';

  @override
  String get cupHole => 'Илмек үчүн Ø35 мм';

  @override
  String get fromLeft => 'Сол четинен';

  @override
  String get fromRight => 'Оң четинен';

  @override
  String get fromBottom => 'Төмөнкү четинен';

  @override
  String get fromTop => 'Жогорку четинен';

  @override
  String get holeDiagramHelp =>
      'Тешиктин борборун жайгаштыруу үчүн схеманы басыңыз.';

  @override
  String get invalidHole =>
      'Диаметрди жана четтерге чейинки аралыкты текшериңиз. Туюк тешиктин тереңдиги тетиктин калыңдыгынан аз болушу керек.';

  @override
  String get ordinaryPart => 'Элемент';

  @override
  String get chestLid => 'Капкак';

  @override
  String get groupType => 'Топтун түрү';

  @override
  String get groupProperties => 'Топтун касиеттери';

  @override
  String get partProperties => 'Тетиктин касиеттери';

  @override
  String get bazisExport => 'БАЗИС-Раскрой үчүн';

  @override
  String get partType => 'Тетиктин түрү';

  @override
  String get forwardDirection => 'Алдыга';

  @override
  String get towardViewer => 'Сизге карай';

  @override
  String get awayFromViewer => 'Сизден ары';

  @override
  String get liftUpDoor => 'Өйдө ачылат · илмеги үстүндө';

  @override
  String get dropDownDoor => 'Ылдый ачылат · илмеги астында';

  @override
  String get hingesLeft => 'Илмектер сол жакта';

  @override
  String get hingesRight => 'Илмектер оң жакта';

  @override
  String get hingesTop => 'Илмектер үстүндө';

  @override
  String get hingesBottom => 'Илмектер астында';

  @override
  String get chooseHingeEdge => 'Эшиктин кырын тандаңыз';

  @override
  String get doorAngle => 'Ачылуу бурчу';

  @override
  String get leftHingedDoor => 'Илмеги сол жактагы эшик';

  @override
  String get rightHingedDoor => 'Илмеги оң жактагы эшик';

  @override
  String get clothesRail => 'Кийим илгич таяк';

  @override
  String get templateTvStand => 'Техника үчүн уячалуу сыналгы тумбасы';

  @override
  String get templateWorkbench => 'Эки бөлүктүү Рубо верстагы';

  @override
  String get templateToolTote => 'Кыйгач туткалуу аспап кутусу';

  @override
  String get cuttingLayout => 'Кесүү схемасы';

  @override
  String get categoryGarden => 'Бакча жана короо';

  @override
  String get templateDrawerChest => 'Төрт суурмалуу комод';

  @override
  String get drawerFront => 'Суурманын алды';

  @override
  String get planterWall => 'Каптал тактай';

  @override
  String get uprightPost => 'Мамы';

  @override
  String get deckBoard => 'Төшөмө тактай';

  @override
  String get frameRail => 'Алкак устуну';

  @override
  String get trellisSlat => 'Тордун рейкасы';

  @override
  String get benchBack => 'Жөлөнгүч тактай';

  @override
  String get landingRail => 'Кармагыч';

  @override
  String get roofBoard => 'Чатыр тактайы';

  @override
  String get rackFinger => 'Кыскычтын таянычы';

  @override
  String get templatePicnicTable => 'Балдар үчүн пикник үстөлү';

  @override
  String get templateSawhorse => 'Усталык теке таяныч';

  @override
  String get templateClampRack => 'Кыскычтар үчүн дубал кармагыч';

  @override
  String get templateRaisedBed => 'Үстү жээктелген бийик жөөк';

  @override
  String get templateStandingPlanter => 'Буттуу гүл кутусу';

  @override
  String get templateTrellisPlanter => 'Тор таянычы бар гүл кутусу';

  @override
  String get templatePorch => 'Аянтчасы жана тосмосу бар кире бериш';

  @override
  String get templateChaise => 'Тактайлуу шезлонг';

  @override
  String get templatePottingBench => 'Идишке оюгу бар көчөт отургузуу үстөлү';

  @override
  String get templateLogStore => 'Бир ылдый чатырлуу отун текчеси';

  @override
  String get categoryConstruction => 'Устачылык жана каркастар';

  @override
  String get floorJoist => 'Пол устуну';

  @override
  String get bridging => 'Кыйгач тирөөч';

  @override
  String get headerBeam => 'Терезе кашеги';

  @override
  String get windowSill => 'Терезенин төмөнкү устуну';

  @override
  String get roofRafter => 'Чатыр устуну';

  @override
  String get ridgeBeam => 'Чатыр кырынын устуну';

  @override
  String get doorStile => 'Эшиктин тик устуну';

  @override
  String get doorPanelInfill => 'Эшиктин ички тактайы';

  @override
  String get gatePicket => 'Тосмо тактайы';

  @override
  String get framingNote =>
      'Төшөмөгө чейинки устундар жана тирөөчтөр көрсөтүлгөн. Таянычтар, устун аралыгы, жыгачтын сорту, төшөмө жана бекиткичтер жергиликтүү жүккө жараша эсептелет.';

  @override
  String get roofNote =>
      'Топурак, кар, шамал жана сейсмикалык жүк боюнча пайдубалды, анкерлерди, чатыр жабууну жана бекиткичтерди эсептөө керек.';

  @override
  String get porchNote =>
      'Аянтчанын бийиктигин босогого жана эшиктин ачылышына ылайыктаңыз. Пайдубалды, баскычтарды, тосмолорду жана бекиткичтерди жергиликтүү нормалар боюнча текшериңиз.';

  @override
  String get doorNote =>
      'Эшиктин канаты көрсөтүлгөн. Кашек, жылчыктар жана илмектер оюктун өлчөмү менен эшиктин салмагына жараша тандалат.';

  @override
  String get gateNote =>
      'Кыйгач тирөөч тарабынан караганда илмектер солдо. Тирөөч жүктү жогорку бош бурчтан илмектин төмөнкү тарабына өткөрөт.';

  @override
  String get templateShedFloor => 'Кайчылаш тирөөчтүү пол каркасы';

  @override
  String get templateWindowWall => 'Терезе оюгу бар каркас дубал';

  @override
  String get templateCornerWalls => 'Эки каркас дубалдын бурчу';

  @override
  String get templatePanelDoor => 'Алкактуу ички эшик';

  @override
  String get templateGardenGate => 'Кыйгач тирөөчтүү бакча эшиги';

  @override
  String get wallFrameNote =>
      'Каптоого чейинки каркас көрсөтүлгөн. Тик устундар, кашек, катуулук үчүн каптоо же кыйгач тирөөчтөр жана анкерлер жергиликтүү жүккө жараша эсептелет.';

  @override
  String get templateSignatureCabinet => 'NeProSto фирмалык тумбасы';

  @override
  String get signatureDoor => 'Манжа үчүн тешиги бар эшик';

  @override
  String get endCutsTitle => 'Учтагы кесимдер';

  @override
  String get faceMarkAngle => 'Туурасы боюнча белгилөө';

  @override
  String get edgeMarkAngle => 'Калыңдыгы боюнча белгилөө';

  @override
  String cutOffsetReadout(String distance) {
    return 'Жылыш $distance';
  }

  @override
  String get mitreSaw => 'Торцовка араасы';

  @override
  String get handheldSaw => 'Кол дисктүү араа';

  @override
  String get tableSaw => 'Араа үстөлү';

  @override
  String get sawCutLine => 'Кесүү сызыгы';

  @override
  String get sawFeed => 'Берүү';

  @override
  String get sawCrosscutFence => 'Туурасынан кесүү таянычы';

  @override
  String get sawTableSight => 'Кесилиште';

  @override
  String get sawFeedView => 'Берүү жагынан';

  @override
  String sawFenceNear(String angle) {
    return '$angle° · оң учу өзүңүзгө карай';
  }

  @override
  String sawFenceFar(String angle) {
    return '$angle° · оң учу өзүңүздөн ары';
  }

  @override
  String get sawStockPosition => 'Тетик жалпак жатат, башы сол жакта';

  @override
  String get sawTableRotation => 'Үстөлдүн бурулушу';

  @override
  String get sawBladeTilt => 'Дисктин жантайышы';

  @override
  String sawAngleLeft(String angle) {
    return 'Солго $angle°';
  }

  @override
  String sawAngleRight(String angle) {
    return 'Оңго $angle°';
  }

  @override
  String get resetEndCut => 'Бурчтарды нөлдөө';

  @override
  String get cutsIntersect =>
      'Кесимдер кесилишет же кыр өтө кыска калат. Бир учтагы бурчту азайтыңыз.';

  @override
  String angleToLongEdge(String angle) {
    return 'Узун кырга карата $angle°';
  }

  @override
  String get rabbetTitle => 'Фальц оюу';

  @override
  String get rabbetTopLeft => 'Жогорку сол';

  @override
  String get rabbetTopRight => 'Жогорку оң';

  @override
  String get rabbetBottomLeft => 'Төмөнкү сол';

  @override
  String get rabbetBottomRight => 'Төмөнкү оң';

  @override
  String get rabbetDepth => 'Тереңдиги';

  @override
  String get rabbetView =>
      'Деталдын акыркы учунан көрүнүшү. Узунунан кеткен кырды тандаңыз.';

  @override
  String get rabbetRemove => 'Фальцты алып салуу';

  @override
  String get invalidRabbet =>
      'Туурасы жана тереңдиги оң сан болушу керек. Оюктардын ортосунда жана карама-каршы бетке чейин материал калтырыңыз.';

  @override
  String get templateLaptopTray => 'Ноутбук үчүн үстөлчө';

  @override
  String get templateBagShelf => 'Сумка үчүн текчелүү илгич';

  @override
  String get templatePantryShelf => 'Эшик артындагы тар текче';

  @override
  String get templateConsoleTable => 'Диван артына үч бөлүктүү текче';

  @override
  String get templateMachineStand => 'Торцовка араасы үчүн таяныч';

  @override
  String get templateTrestleBench => 'Кыйгач буттуу отургуч';

  @override
  String get templateWindowBox => 'Терезе үчүн гүл кутусу';

  @override
  String get templateBirdhouse => 'Канаттууга үч бурчтуу үйчө';

  @override
  String get templateCandleShelf => 'Үч бурчтуу шам текчеси';

  @override
  String get templateBlanketLadder => 'Сүлгү үчүн шаты';

  @override
  String get templateHeadphoneStand => 'Кулакчын үчүн таяныч';

  @override
  String get templatePlantPanel => 'Өсүмдүк үчүн дубал панели';

  @override
  String get templateToyChest => 'Оюнчук үчүн рейкалуу сандык';

  @override
  String get templateShutters => 'Үч бөлүктүү бүктөмө терезе капкагы';

  @override
  String get templateLantern => 'Терраса үчүн кооз чырак';

  @override
  String get templateMirrorFrame => 'Күзгү үчүн полго коюлуучу алкак';

  @override
  String get templateHexShelf => 'Алты бурчтуу текче';

  @override
  String get templateCoffeeTable => 'Астында текчеси бар жапыз үстөл';

  @override
  String get templateShoeBench => 'Бут кийим үчүн үч уячалуу отургуч';

  @override
  String get templateTrivet => 'Ысык идиш үчүн тор таяныч';

  @override
  String get categoryHousehold => 'Үй буюмдары';

  @override
  String get planEasy => 'Оңой';

  @override
  String get planMedium => 'Орточо';

  @override
  String get planAdvanced => 'Татаал';

  @override
  String get planSource => 'Түп нускадагы сүрөт жана чийме';

  @override
  String get planDrawing => 'Түп нускадагы чийме (ZIP)';

  @override
  String get planAdaptation =>
      'Модель редакторго ылайыкташтырылган. Кесүү тизмесине жыгач тетиктер кирет.';

  @override
  String get planHardwareHooks => 'Үч илгич жана дубалга бекиткичтер керек.';

  @override
  String get planShutterNote =>
      'Бүктөмдөрдүн ортосунда топсо үчүн 3 мм боштук бар. Тандалган топсого жараша тактаңыз.';

  @override
  String get planLadderNote => 'Жууркан илүүгө арналган. Дубалга бекитиңиз.';

  @override
  String get planChestNote =>
      'Капкакка топсо жана ачык кармоочу таяныч орнотуңуз.';

  @override
  String get planMirrorNote =>
      '407 × 1525 мм күзгү, күзгү бекиткичтери жана дубал бекиткичи керек.';

  @override
  String get planRoundedNote =>
      'Тик бурчтуу даярдамалар көрсөтүлгөн. Тийишкен кырларын жумурулаңыз.';

  @override
  String get planTrivetNote =>
      'Craftsmanspace үлгүсү боюнча 12 × 7 мм рейкалар эки катмар болуп кайчылаш чапталат.';

  @override
  String get roomKitchen => 'Ашкана';

  @override
  String get roomLivingRoom => 'Конок бөлмө';

  @override
  String get roomBedroom => 'Уктоочу бөлмө';

  @override
  String get roomNursery => 'Балдар бөлмөсү';

  @override
  String get roomEntryway => 'Кире бериш';

  @override
  String get roomBathroom => 'Жуунучу бөлмө';

  @override
  String get roomOffice => 'Иш бөлмөсү';

  @override
  String get templateAssembly => 'Кантип чогултуу керек';

  @override
  String get templateHoodCabinet => 'Аба соргуч үчүн асма шкаф';

  @override
  String get templateSinkBase => 'Раковинанын алдындагы тумба';

  @override
  String get templatePlatformBed => 'Рейкалуу керебет';

  @override
  String get templateBasinShelf => 'Сифонго оюгу бар асма тумба';

  @override
  String get templateFileTrays => 'Кагаз үчүн үч кабаттуу текче';

  @override
  String get ductOpening => 'Аба түтүгүнүн тешиги';

  @override
  String get chaseSide => 'Түтүк кутусунун капталы';

  @override
  String get chaseCover => 'Кутунун алынма капкагы';

  @override
  String get hangingRail => 'Бекитүүчү планка';

  @override
  String get hingeCup => 'Илмек оюгу';

  @override
  String get plinth => 'Түп тактай';

  @override
  String get slatLedger => 'Таяныч рейка';

  @override
  String get centerRail => 'Ортодогу устун';

  @override
  String get bedSlat => 'Керебеттин рейкасы';

  @override
  String get shelfWing => 'Текченин каптал бөлүгү';

  @override
  String get paperTray => 'Кагаз текчеси';

  @override
  String get bedRim => 'Кыйгач кесилген үстүңкү жээк';

  @override
  String get assembleHoodCabinet =>
      'Үстү менен түбүн капталдарга конфирмат менен тартыңыз. Текчелерди капталдар менен түтүк кутусунун ортосуна бекитиңиз. Кутунун маңдайын чечилме бурамалар менен карматыңыз. Түтүк бир октогу эки тешиктен өтөт. Тешиктерди, бекитүү чекиттерин жана бийиктикти аба соргучтун монтаж чиймесинен тактаңыз. Эшиктерди чөйчөкчө илмекке, шкафты бекитүүчү планкаларга орнотуңуз.';

  @override
  String get assembleSinkBase =>
      'Түбүн жана үстүңкү планкаларды капталдарга конфирмат менен бекитиңиз. Түп тактайды ичинен бураңыз. Үстү ачык болгондуктан раковина батат, арткы туура жыгач түтүктөргө жол калтырат.';

  @override
  String get assemblePantryShelf =>
      'Текчелерди капталдар аркылуу бурама менен бекитиңиз. Алдыңкы тосмолорду капталдардын маңдай кырларына бураңыз. Бийик кууш текчени дубалга бекитиңиз.';

  @override
  String get assembleDiningTable =>
      'Адегенде туура жыгачтарды буттарга болт менен бекитип, эки алкак чогултуңуз. Үстүңкү тактайларды арасына жылчык калтырып, эки алкакка тең астынан бураңыз.';

  @override
  String get assembleSignatureCabinet =>
      'Тепкич сымал корпусту шкант жана желим менен бириктирип, маңдайкы планкаларды жабыңыз. Арткы дубалдар бурчтарды кармайт. Эшикти илмекке илиңиз, тегерек тешик тутка болот.';

  @override
  String get assembleBookcase =>
      'Туура жыгачтарды тик таянычтарга бурап, эки каптал алкак жасаңыз. Таянычтарды бекитип, текче тактайларын эки жагынан бураңыз. Үстүн дубалга бекитиңиз.';

  @override
  String get assembleCoffeeTable =>
      'Каптал жыгачтарды буттарга шкант жана желим менен бириктириңиз. Астыңкы текчени таянычтарга коюп, фанера үстүн астынан бурчтук менен бекитиңиз.';

  @override
  String get assembleTvStand =>
      'Корпустун панелдерин жана бөлгүчтөрдү конфирмат менен тартыңыз. Артын четинен жана бөлгүчтөргө бекитиңиз. Эки четки бөлүк эшиктүү, ортосу ачык.';

  @override
  String get assembleBedroomWardrobe =>
      'Үстүн, түбүн жана бөлгүчтөрдү конфирмат менен бекитиңиз. Кийим таякчаларын кармагычтарга коюп, текчелерди жана артын бекитиңиз. Эшиктерди белгиленген кырынан илип, шкафты дубалга бекитиңиз.';

  @override
  String get assemblePlatformBed =>
      'Алкактын жыгачтарын ажыратылма керебет бекиткичтери менен бириктириңиз. Ички рейкаларды бураңыз. Ортодогу устунду өз буттарына коюп, баш жана аяк жакка бекитиңиз. Рейкалар үч таянычка жатып, жылбай тургандай бекитилет.';

  @override
  String get assembleDrawerChest =>
      'Корпусту конфирмат менен чогултуңуз. Суурманын түбү менен артын капталдарына, маңдайын ичинен бекитиңиз. Багыттагычтарды бир деңгээлге коюп, керектүү каптал боштугун сактаңыз. Корпусту дубалга бекитиңиз.';

  @override
  String get assembleToyChest =>
      'Бурчтагы жуп таянычтарды желимдеңиз. Каптал тактайлар менен ылдыйкы алкактын учтарын ичинен кыйгач тешик аркылуу таянычка бураңыз. Түп тактайларын алкакка, капкак тактайларын туура рейкалар аркылуу астынан бекитиңиз. Арткы үстүңкү тактайга узун илмек орнотуңуз. Капкакты каалаган абалда кармачу, салмагына ылайык таяныч тандаңыз. Аба жылчыктарын ачык калтырыңыз.';

  @override
  String get assembleCubeShelf =>
      'Бирдиктүү түптөн баштаңыз. Текче учтары жеткиликтүү кезде тепкич бөлүктөрүн ылдыйдан өйдө шкант жана эмерек тарткычы менен чогултуңуз. Дубалга бекитиңиз.';

  @override
  String get assembleStepStool =>
      'Фанера капталдарды тик баскычтарга шкант жана желим менен бириктириңиз. Баскычтарды таянычтарга коюп, башы батырылган бурама менен бекитиңиз. Капталдардын төмөнкү кыры полго толук тийсин.';

  @override
  String get assembleShoeBench =>
      'Түп алкагын чогултуп, үстүнө түбүн коюңуз. Капталдар менен бөлгүчтөрдү отургучка жана түбүнө шкант, желим менен бириктириңиз. Формасын сактоо үчүн артын четинен бекитиңиз.';

  @override
  String get assembleConsoleTable =>
      'Капталдарды үстүнө жана түбүнө тартыңыз. Бөлүктөрдү чогултуп жатып текчелерди бөлгүчтөргө шкант менен бириктириңиз. Кууш консолду дубалга бекитиңиз.';

  @override
  String get assembleMirrorFrame =>
      'Туура жыгачтарды тик мамыларга шкант менен бириктириңиз. Аралык таянычтардын арткы учун моделдеги бурч менен кесип, алкакты дубалга бекитиңиз. Күзгүнү айнек кармагычтарга орнотуңуз.';

  @override
  String get assembleBasinShelf =>
      'Алдыңкы текчени эки каптал бөлүккө шкант жана нымга чыдамдуу желим менен бириктириңиз. Артта сифонго ачык оюк калат. Текчелерди капталдарга, артындагы планкаларды дубалга бекитиңиз. Фанера кырларын нымдан коргоңуз.';

  @override
  String get assembleBlanketLadder =>
      'Туура таякчалар айланып кетпесин үчүн ар бир учун эки шкант менен бекитиңиз. Үстүн дубалга карматыңыз. Бул шаты сүлгү илүүгө арналган.';

  @override
  String get assembleWritingDesk =>
      'Үстүңкү тактай капталга жана текчелүү тумбага таянат. Панелдерди конфирмат менен тартып, артындагы туура жыгачтарды бекитиңиз. Алар үстөлдү капталга кыйшаюудан кармайт.';

  @override
  String get assembleWallShelf =>
      'Туура брустарды арттагы рейкага бураңыз. Рейканы дубалдын көтөрүүчү бөлүгүнө бекитип, фанера кабыкты кийгизиңиз да астынан каркас менен бириктириңиз.';

  @override
  String get assembleFileTrays =>
      'Таяныч рейкаларды жуп-жубу менен бир деңгээлге желимдеңиз. Ар бирине фанера текче коюңуз. Капталдар ажырабашы үчүн артын бекитиңиз.';

  @override
  String get assembleWorkbench =>
      'Буттарды жана үстүңкү эки калканды өз-өзүнчө желимдеңиз. Алкак жыгачтарын буттарга болт менен тартыңыз. Ортодогу жылчыкты жана жыгачтын туурасынан кеңейишине орун калтырып, үстүн астынан бекитиңиз.';

  @override
  String get assembleSawhorse =>
      'Кыйгач буттар полго жана үстүңкү тактайга толук тийиши үчүн учтарын моделдеги бурч менен кесиңиз. Каптал жыгачтарды буттарга болт менен тартып, астыңкы кергичтерди бекитиңиз.';

  @override
  String get assembleMachineStand =>
      'Эки учтагы алкакты чогултуп, узун жыгачтар менен тартыңыз. Фанера тактайларды үстүнөн алкакка бураңыз. Үч бөлүктүү астыңкы текче буттарды айланып өтөт.';

  @override
  String get assembleRaisedBed =>
      'Каптал тактайларын бурчтагы жана ортодогу мамыларга сырттан бекитиңиз. Ортоңку мамыларды туура жыгач менен тартыңыз. Үстүңкү төрт жээктин эки учун тең 45° кесип, мамыларга үстүнөн бураңыз.';

  @override
  String get assembleBench =>
      'Узун жана кыска жыгачтарды буттарга желимдүү шкант же ичинен кыйгач бурама менен бириктириңиз. Отуруучу тактайлардын аралыгын теңдеп, үстүнөн бураңыз.';

  @override
  String get assemblePicnicTable =>
      'Адегенде эки А сымал таянычты чогултуңуз. Кыйгач буттар менен туура жыгачтарды өтмө болт жана шайба менен тартыңыз. Үстөл жана отургуч тактайларын үстүнөн бекитип, узунунан тарткычты орнотуңуз.';

  @override
  String get assembleChaise =>
      'Каптал алкактарды чогултуңуз. Жөлөнгүчтү кесилген таянычтарга таяндырып, моделдеги кыйшайыш менен болттоңуз. Рейкаларды эки капталга бурап, сууга жылчык калтырыңыз.';

  @override
  String get assemblePottingBench =>
      'Мамылар менен жыгачтарды сыртка ылайыктуу бурама менен бириктириңиз. Үстүңкү тактайларды бекитип, алынма лотокко орун калтырыңыз. Арткы мамылар үстүңкү текчени көтөрөт.';

  @override
  String get assembleLogStore =>
      'Мамыларды узун жыгач менен тартып, пол тактайларын туура жыгачтарга бекитиңиз. Мамы учтарын чатырдын эңишине ылайык кесиңиз. Отун желдесин үчүн дубал рейкаларынын арасын ачык калтырыңыз.';

  @override
  String get assembleGardenGate =>
      'Тик тактайларды эки туура жыгачка бураңыз. Кыйгач тирөөч жогорку бош бурчтан ылдыйкы илмекке чейин эки учунан такалсын. Илмектерди туура жыгачтарга бекитиңиз.';

  @override
  String get assembleBirdhouse =>
      'Чатыр тактайларынын кыйгач кырларын чокуда бириктириңиз. Алдын ала тешип, уч панелдер менен түбүн чатырга бураңыз. Тазалоо үчүн бир четин алынма кылыңыз.';

  @override
  String get assemblePorch =>
      'Баскычтар менен аянтчанын алкактарын чогултуп, тактайларды туура жыгачка бураңыз. Тосмо мамыларын алкакка болттоңуз. Кол кармагычты эңишке жараша кесип, мамыларга бекитиңиз. Негизге бекитүүнү жерине жараша тандаңыз.';
}
