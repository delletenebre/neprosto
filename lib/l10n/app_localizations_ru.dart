// ignore_for_file: deprecated_member_use

// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get layFaceDown => 'Положить этой гранью вниз';

  @override
  String get stockTurnHint =>
      'Выберите плоскость и нажмите стрелку −90° или +90° на заготовке.';

  @override
  String linkToHole(int number) {
    return 'Привязать к центру № $number';
  }

  @override
  String get holeGroups => 'Группы отверстий';

  @override
  String get addLinkedShaft => 'Добавить торцевое к центру';

  @override
  String get addEdgeBore => 'Добавить торцевое…';

  @override
  String linkedFaceHole(int number) {
    return 'К отверстию № $number';
  }

  @override
  String anchoredFaceHole(int number) {
    return 'Привязка к отверстию № $number';
  }

  @override
  String get detachHoleAnchor => 'Снять привязку';

  @override
  String get pointAnchor => 'Привязка к точке';

  @override
  String get faceMagnet => 'Магнит при перемещении';

  @override
  String pickHoleAnchor(String modifier) {
    return '$modifier-клик по схеме — привязать отверстие к точке или центру другого отверстия';
  }

  @override
  String get drillMode => '3D';

  @override
  String get faceMarkA => 'А';

  @override
  String get faceMarkB => 'Б';

  @override
  String get spatialOverview => 'Общий вид';

  @override
  String get clearOrbitPivot => 'Сбросить опору вращения';

  @override
  String holeNavigationHint(String modifier) {
    return '$modifier⇧-клик — опора · ПКМ — вращение · $modifier + колесо — масштаб';
  }

  @override
  String get openingSensor => 'Датчик открывания';

  @override
  String get customDrill => 'Своё сверление';

  @override
  String get drillMagnet => 'Магнит';

  @override
  String get drillHint => 'Клик — сверлить · Shift-клик — задать ноль';

  @override
  String get edgeOrbitHint => 'Клик по торцу — выбрать';

  @override
  String get resetDatum => 'Сбросить базу';

  @override
  String get drillGridInvalid => 'Введите отступ от нуля и положительный шаг.';

  @override
  String get addConnection => 'Добавить соединение';

  @override
  String get confirmat => 'Конфирмат';

  @override
  String get dowel => 'Шкант';

  @override
  String get dowels => 'Шканты';

  @override
  String get connectionRuler => 'Шкала соединений';

  @override
  String get datumOffset => 'Первая отметка от базы';

  @override
  String get markPitch => 'Шаг шкалы';

  @override
  String get baseDistance => 'Расстояние от базы';

  @override
  String get panelFaces => 'Пласти';

  @override
  String get panelEdges => 'Торцы';

  @override
  String get beforeHardware => 'До крепежа';

  @override
  String get afterHardware => 'После крепежа';

  @override
  String get bothHardware => 'С двух сторон';

  @override
  String get chooseConnectionBase =>
      'Нажмите на торец ближе к тому углу, от которого вести отсчёт.';

  @override
  String get placeConnection =>
      'Переместите шаблон вдоль шкалы и нажмите, чтобы добавить отверстия.';

  @override
  String get placeOnDrawing => 'Разместить на схеме';

  @override
  String get connectionDoesNotFit => 'Присадка выходит за границы детали.';

  @override
  String get camThickness => 'Недостаточная толщина для этого эксцентрика';

  @override
  String get datum => 'База';

  @override
  String get emptyEdge => 'На этом торце нет отверстий';

  @override
  String get pocketShoulder => 'Глубина до уступа';

  @override
  String get edgeBanding => 'Кромка';

  @override
  String get bandWholePerimeter => 'Весь периметр';

  @override
  String get deselectAllEdges => 'Снять все';

  @override
  String get bandingEdges => 'Торцы';

  @override
  String get bandThickness => 'Толщина ленты';

  @override
  String get bandWidth => 'Ширина ленты';

  @override
  String get matchPanelThickness => 'По толщине детали';

  @override
  String get invalidEdgeBanding => 'Некорректные параметры кромки';

  @override
  String get positiveBandSize => 'Введите размер больше нуля.';

  @override
  String get woodBasedPanel => 'ДПМ';

  @override
  String get woodBasedPanelFullName => 'Древесный плитный материал';

  @override
  String get panelFaceColor => 'Цвет поверхности';

  @override
  String get edgeBandColor => 'Цвет кромки';

  @override
  String get partFinish => 'Материал';

  @override
  String get mixedValues => 'Разные';

  @override
  String get pineColor => 'Сосна';

  @override
  String get oakColor => 'Дуб';

  @override
  String get whiteColor => 'Белый';

  @override
  String get grayColor => 'Серый';

  @override
  String get graphiteColor => 'Графит';

  @override
  String get beigeColor => 'Бежевый';

  @override
  String get blackColor => 'Чёрный';

  @override
  String get greenColor => 'Зелёный';

  @override
  String get blueColor => 'Синий';

  @override
  String get brickColor => 'Кирпичный';

  @override
  String get finishTexture => 'Текстура';

  @override
  String get finishColor => 'Цвет';

  @override
  String get metal => 'Металл';

  @override
  String get solidColor => 'Однотонный';

  @override
  String get naturalWood => 'Дерево';

  @override
  String get whiteBoard => 'ЛДСП · белая';

  @override
  String get oakBoard => 'ЛДСП · дуб';

  @override
  String get aluminumProfile => 'Алюминиевый профиль';

  @override
  String get steelProfile => 'Стальной профиль · графит';

  @override
  String get invalidPartFinish => 'Некорректный материал детали';

  @override
  String get invalidHexColor => 'Введите цвет в формате #RRGGBB';

  @override
  String get positiveThickness => '+Т';

  @override
  String get positiveWidth => '+Ш';

  @override
  String get xWidth => 'X · ширина';

  @override
  String get horizontalPlane => 'Горизонтальная';

  @override
  String get workPlanePurpose => 'Где строить и перемещать детали?';

  @override
  String get horizontalPlaneExample => 'Как полка или столешница';

  @override
  String get frontPlaneExample => 'Как дверца шкафа';

  @override
  String get sidePlaneExample => 'Как боковина шкафа';

  @override
  String get partFacePlane => 'По грани детали';

  @override
  String get workPlaneNeedsPart => 'Нужна видимая деталь на чертеже';

  @override
  String get yDepth => 'Y · глубина';

  @override
  String get zHeight => 'Z · высота';

  @override
  String edgeCaption(Object side) {
    return '$side\nкрай';
  }

  @override
  String scrollGesture(Object modifier) {
    return '$modifier + скролл';
  }

  @override
  String sketchEndHint(
    Object part,
    Object width,
    Object thickness,
    Object unit,
  ) {
    return '$part · $width × $thickness $unit · укажите конец';
  }

  @override
  String liftHint(Object instruction, Object modifier) {
    return '$instruction · $modifier — вверх · с Shift — строго по Z';
  }

  @override
  String endAngleValue(Object end, Object angle) {
    return '$end · $angle° от прямого';
  }

  @override
  String unsavedTab(Object name) {
    return '$name · Есть изменения';
  }

  @override
  String depthDirection(Object axis) {
    return '$axis · в глубину';
  }

  @override
  String heightGesture(Object mode) {
    return '$mode · ведите курсор вверх, чтобы задать высоту';
  }

  @override
  String placeEndHint(Object mode) {
    return '$mode · щёлкните, чтобы поставить конец детали';
  }

  @override
  String resizeLockHint(Object action, Object dimension) {
    return '$action размер · $dimension';
  }

  @override
  String pieceCount(Object count) {
    return '$count шт.';
  }

  @override
  String partsFilename(Object name) {
    return '$name — список деталей';
  }

  @override
  String get automatic => 'Авто';

  @override
  String get autosave => 'Автосохранение';

  @override
  String get axonometric => 'Аксонометрия';

  @override
  String get untitled => 'Без названия';

  @override
  String numberedUntitled(Object number) {
    return 'Без названия $number';
  }

  @override
  String get lock => 'Блокировать';

  @override
  String get partLocks => 'Блокировки деталей';

  @override
  String get side => 'Боковая';

  @override
  String get inTheThicknessPlane => 'В плоскости толщины';

  @override
  String get inTheWidthPlane => 'В плоскости ширины';

  @override
  String get thisProjectHasNoPartsYet => 'В проекте пока нет деталей';

  @override
  String get noStopInThisDirection => 'В этом направлении нет упора';

  @override
  String get invalidInsideAngle => 'Введите внутренний угол между 0° и 180°';

  @override
  String get positiveIntegerHint => 'Введите целое число от 1.';

  @override
  String get up => 'Вверх';

  @override
  String get vertical => 'Вертикаль';

  @override
  String get cubeTop => 'Верх';

  @override
  String get upper => 'Верхний';

  @override
  String get fixedDimensionsFillSpan =>
      'Весь габарит занят фиксированными размерами';

  @override
  String get view => 'Вид';

  @override
  String get views => 'Виды';

  @override
  String get gridVisibility => 'Видимость сетки';

  @override
  String get left => 'Влево';

  @override
  String get down => 'Вниз';

  @override
  String get insideAngle => 'Внутренний угол';

  @override
  String get fitToWindow => 'Вписать в окно';

  @override
  String fitShortcut(Object shortcut) {
    return 'Вписать в окно · $shortcut';
  }

  @override
  String get right => 'Вправо';

  @override
  String get alwaysVisible => 'Всегда видны';

  @override
  String get shortcutKeyHint =>
      'Выберите букву, цифру, стрелку или функциональную клавишу';

  @override
  String get selectTheSecondShelf => 'Выберите вторую полку';

  @override
  String get selectWorkPlaneFace =>
      'Щёлкните по нужной поверхности детали на чертеже';

  @override
  String get chooseParallelShelf =>
      'Выберите другую полку с общей проекцией и параллельной гранью';

  @override
  String get chooseAlignmentHint =>
      'Укажите точки на двух деталях или задайте выравнивание в панели';

  @override
  String get chooseMovingAnchor =>
      '2 из 2. Укажите точку на перемещаемой детали.';

  @override
  String get selectAnAnchorOnThePart => 'Выберите опору на детали';

  @override
  String get chooseAReference => 'Выберите опору…';

  @override
  String get selectTheFirstShelf => 'Выберите первую полку';

  @override
  String get selectParts => 'Выбор деталей';

  @override
  String selectedParts(Object count) {
    return 'Выбрано деталей · $count';
  }

  @override
  String selectShortcut(Object shortcut) {
    return 'Выбрать · $shortcut';
  }

  @override
  String get selectAllParts => 'Выбрать все детали';

  @override
  String get chooseReferenceFromList => 'Выбрать опорную деталь из списка';

  @override
  String get alignment => 'Выравнивание';

  @override
  String get alignToReference => 'Выровнять по опоре…';

  @override
  String overallSizeMustExceed(Object size, Object unit) {
    return 'Габарит должен быть больше $size $unit';
  }

  @override
  String get projectBounds => 'Габариты проекта';

  @override
  String get assemblyDimensions => 'Габариты сборки';

  @override
  String get keyboardShortcuts => 'Горячие клавиши';

  @override
  String get done => 'Готово';

  @override
  String get resizeProducts => 'Изменить размеры изделий';

  @override
  String get face => 'Грань';

  @override
  String get shelfFace => 'Грань полки';

  @override
  String numberedGroup(Object number) {
    return 'Группа $number';
  }

  @override
  String get lengthInitial => 'Д';

  @override
  String get twoPoints => 'Две точки';

  @override
  String get moveAndResizeInIncrements => 'Двигать и растягивать с шагом';

  @override
  String get partsTree => 'Дерево деталей';

  @override
  String partCount(Object count) {
    return 'Деталей · $count';
  }

  @override
  String get partsLabel => 'Детали';

  @override
  String partsTabCount(Object count) {
    return 'Детали  $count';
  }

  @override
  String get assemblyParts => 'Детали изделия';

  @override
  String get noMatchingParts => 'Детали не найдены';

  @override
  String get part => 'Деталь';

  @override
  String numberedPart(Object id) {
    return 'Деталь $id';
  }

  @override
  String get thePartIntersectsItsReference => 'Деталь пересекает опору';

  @override
  String get alreadyTouchesReferences => 'Деталь уже касается обеих опор';

  @override
  String get length => 'Длина';

  @override
  String get stockLength => 'Длина заготовки';

  @override
  String stockLengthInUnits(Object unit) {
    return 'Длина заготовки, $unit';
  }

  @override
  String get lengthTooShortForCuts => 'Длина меньше перепада запилов';

  @override
  String shortAndLongEdgeLengths(Object unit) {
    return 'Длины короткой и длинной кромок, $unit';
  }

  @override
  String get matchingSectionsRequired =>
      'Для симметричного стыка выберите одинаковые сечения';

  @override
  String bothStops(Object first, Object second) {
    return 'До упора · $first и $second';
  }

  @override
  String get upToNextStop => 'До упора вверх';

  @override
  String get leftToNextStop => 'До упора влево';

  @override
  String get downToNextStop => 'До упора вниз';

  @override
  String get rightToNextStop => 'До упора вправо';

  @override
  String get addASecondPartToAlignThem =>
      'Добавьте вторую деталь для выравнивания';

  @override
  String get duplicate => 'Дублировать';

  @override
  String get inches => 'Дюймы';

  @override
  String discardChangesWarning(Object name) {
    return 'Если закрыть проект «$name», последние правки будут потеряны.';
  }

  @override
  String get stockPiece => 'Заготовка';

  @override
  String get stockTooShort => 'Заготовка слишком короткая для этого запила';

  @override
  String get stock => 'Заготовки';

  @override
  String get cubeBack => 'Зад';

  @override
  String get rear => 'Задний';

  @override
  String get backEdge => 'Задний край';

  @override
  String gap(Object distance, Object unit) {
    return 'Зазор $distance $unit';
  }

  @override
  String get closeTab => 'Закрыть вкладку';

  @override
  String closeProjectTab(String name) {
    return 'Закрыть вкладку «$name»';
  }

  @override
  String get closeGridSettings => 'Закрыть настройки сетки';

  @override
  String get closePartDimensions => 'Закрыть размеры детали';

  @override
  String miterEndAngle(Object angle) {
    return 'Запил каждого торца · $angle° от прямого';
  }

  @override
  String get autosaveFilesHint =>
      'Изменения записываются в файлы открытых проектов. Новые проекты хранятся как локальные черновики.';

  @override
  String measureShortcut(Object shortcut) {
    return 'Измерить · $shortcut';
  }

  @override
  String get measureDistance => 'Измерить расстояние';

  @override
  String get tools => 'Инструменты';

  @override
  String get intervalMin => 'Интервал, мин';

  @override
  String get excelWorkbook => 'Книга Excel';

  @override
  String get qty => 'Кол-во';

  @override
  String get quantityPcs => 'Количество, шт.';

  @override
  String get endPoint => 'Конец';

  @override
  String get endCut => 'Конечный торец';

  @override
  String edges(Object lengths, Object unit) {
    return 'Кромки · $lengths $unit';
  }

  @override
  String get cubeLeft => 'Лево';

  @override
  String get leftHand => 'Левый';

  @override
  String get ruler => 'Линейка';

  @override
  String get zoom => 'Масштаб';

  @override
  String get actionsMenu => 'Меню действий';

  @override
  String get precision => 'Точность';

  @override
  String get anglePrecision => 'Точность углов';

  @override
  String get editingIncrement => 'Шаг редактирования';

  @override
  String get measurementUnits => 'Единицы измерения';

  @override
  String get millimeters => 'Миллиметры';

  @override
  String get onDrawing => 'На чертеже';

  @override
  String get pressKeys => 'Нажмите клавиши…';

  @override
  String get recordShortcutHint =>
      'Нажмите на сочетание и введите новое. Esc отменяет ввод.';

  @override
  String get rotationInputHint =>
      'Нажмите стрелку для поворота на 90° или введите угол';

  @override
  String get partName => 'Название детали';

  @override
  String get groupName => 'Название группы';

  @override
  String get nameAndDimensions => 'Название и размеры…';

  @override
  String get projectName => 'Название проекта';

  @override
  String get assign => 'Назначить';

  @override
  String searchMatches(Object found, Object total) {
    return 'Найдено $found из $total';
  }

  @override
  String get findAPart => 'Найти деталь';

  @override
  String get tiltInAVerticalPlane => 'Наклон в вертикальной плоскости';

  @override
  String get direction => 'Направление';

  @override
  String get settings => 'Настройки';

  @override
  String get projectSettings => 'Настройки проекта';

  @override
  String get projectSettingsMenu => 'Настройки проекта…';

  @override
  String get start => 'Начало';

  @override
  String get startCut => 'Начальный торец';

  @override
  String get discardChanges => 'Не сохранять';

  @override
  String get draftSaveError => 'Не удалось записать черновик';

  @override
  String get updateProjectError =>
      'Не удалось обновить файл. Используйте «Сохранить как…».';

  @override
  String get draftOpenError => 'Не удалось открыть локальный черновик';

  @override
  String get openProjectError => 'Не удалось открыть файл проекта';

  @override
  String get gridSaveError => 'Не удалось сохранить видимость сетки';

  @override
  String get settingsSaveError => 'Не удалось сохранить настройки';

  @override
  String get saveProjectError =>
      'Не удалось сохранить проект. Используйте «Сохранить как…».';

  @override
  String get snapSaveError => 'Не удалось сохранить режим привязки';

  @override
  String get workbookSaveError =>
      'Не удалось сохранить файл Excel. Попробуйте ещё раз.';

  @override
  String get unknownProjectFormat => 'Неизвестный формат проекта';

  @override
  String get invalidPartGeometry => 'Некорректная геометрия детали';

  @override
  String get invalidFace => 'Некорректная грань';

  @override
  String get invalidVector => 'Некорректный вектор';

  @override
  String get invalidWorkspaceDimensions =>
      'Некорректный размер рабочего пространства';

  @override
  String get invalidEndCut => 'Некорректный торец';

  @override
  String get invalidCorner => 'Некорректный угол';

  @override
  String get noOverlappingProjection => 'Нет общей проекции';

  @override
  String get noOpenProjects => 'Нет открытых проектов';

  @override
  String get lower => 'Нижний';

  @override
  String get cubeBottom => 'Низ';

  @override
  String get newPart => 'Новая деталь';

  @override
  String get newDimension => 'Новый размер';

  @override
  String get centerCamera => 'Центрировать';

  @override
  String get renameDimension => 'Переименовать размер';

  @override
  String selectDimensionHint(String shortcut) {
    return 'Выберите размер на чертеже или нажмите $shortcut, чтобы добавить новый';
  }

  @override
  String get newPartWithDimensions => 'Новая деталь по размерам';

  @override
  String get choosePartPosition => 'Выбрать место';

  @override
  String get placePartHint =>
      'Щёлкните, чтобы поставить деталь. Esc — отменить.';

  @override
  String get hiddenParts => 'Скрытые детали';

  @override
  String get hideCompletely => 'Полностью скрывать';

  @override
  String get showOutlines => 'Показать контуры';

  @override
  String get hidePart => 'Скрыть деталь';

  @override
  String get hideGroupParts => 'Скрыть все детали группы';

  @override
  String get showGroupParts => 'Показать все детали группы';

  @override
  String get hideSelectedParts => 'Скрыть выбранные детали';

  @override
  String get showPart => 'Показать деталь';

  @override
  String get showAllParts => 'Показать все скрытые детали';

  @override
  String newPartShortcut(Object shortcut) {
    return 'Новая деталь · $shortcut';
  }

  @override
  String get newPartHere => 'Новая деталь здесь';

  @override
  String get newProject => 'Новый проект';

  @override
  String leg(Object number) {
    return 'Ножка $number';
  }

  @override
  String get referencesAreNeededOnBothSides => 'Нужны опоры с обеих сторон';

  @override
  String get reverseDirection => 'Обратить направление';

  @override
  String get anchor => 'Опора';

  @override
  String anchorLabel(Object mode) {
    return 'Опора · $mode';
  }

  @override
  String get referencePart => 'Опорная деталь';

  @override
  String get partAxes => 'Оси детали';

  @override
  String get projectAxes => 'Оси проекта';

  @override
  String axis(Object axis) {
    return 'Ось $axis';
  }

  @override
  String get zoomOut => 'Отдалить';

  @override
  String get open => 'Открыть';

  @override
  String get newTab => 'Новая вкладка';

  @override
  String get recentProjects => 'Недавние проекты';

  @override
  String get noRecentProjects => 'Пока нет недавних проектов';

  @override
  String get openProject => 'Открыть проект';

  @override
  String get openProjectMenu => 'Открыть проект…';

  @override
  String get cancel => 'Отмена';

  @override
  String get undo => 'Отменить';

  @override
  String get undoAction => 'Отменить действие';

  @override
  String get offset => 'Отступ';

  @override
  String referenceEdgeOffset(Object edge) {
    return 'Отступ от $edge опоры';
  }

  @override
  String get clearSearch => 'Очистить поиск';

  @override
  String get rightClick => 'ПКМ';

  @override
  String get moveResizeHint =>
      'Перетащите деталь, чтобы переместить её. Shift + перетаскивание края меняет размер.';

  @override
  String get cubeFront => 'Перед';

  @override
  String get frontFacing => 'Передний';

  @override
  String get frontEdge => 'Передний край';

  @override
  String get renamePart => 'Переименовать деталь';

  @override
  String get renameGroup => 'Переименовать группу';

  @override
  String get rename => 'Переименовать…';

  @override
  String moveShortcut(Object shortcut) {
    return 'Переместить · $shortcut';
  }

  @override
  String anchorShortcut(Object shortcut) {
    return 'Поставить по опоре · $shortcut';
  }

  @override
  String get movementAndRuler => 'Перемещение и линейка';

  @override
  String get movementAndResizing => 'Перемещение и растягивание';

  @override
  String get intersection => 'Пересечение';

  @override
  String get intersections => 'Пересечения';

  @override
  String intersectionsLabel(Object count) {
    return 'Пересечения · $count';
  }

  @override
  String get perspective => 'Перспектива';

  @override
  String seatSlat(Object number) {
    return 'Планка сиденья $number';
  }

  @override
  String get plane => 'Плоскость';

  @override
  String get buildInThisPlane => 'Строить в этой плоскости';

  @override
  String get edgeAligned => 'По краю';

  @override
  String get byAxes => 'По осям';

  @override
  String get alongThickness => 'По толщине';

  @override
  String get alongWidth => 'По ширине';

  @override
  String get rotate => 'Повернуть';

  @override
  String get orbitView => 'Повернуть вид';

  @override
  String get rotatePart => 'Повернуть деталь';

  @override
  String get rotateMenu => 'Повернуть…';

  @override
  String get rotation => 'Поворот';

  @override
  String rotateShortcut(Object shortcut) {
    return 'Поворот · $shortcut';
  }

  @override
  String get brokenPartReferences => 'Повреждённые ссылки на детали';

  @override
  String get redo => 'Повторить';

  @override
  String get redoAction => 'Повторить действие';

  @override
  String get showHideDimensions => 'Показать / скрыть размеры';

  @override
  String get showDimensions => 'Показать размеры';

  @override
  String get floor => 'Пол';

  @override
  String get partOffsets => 'Отступы';

  @override
  String get xFromLeft => 'X · слева';

  @override
  String get yFromBack => 'Y · от стенки';

  @override
  String get zFromFloor => 'Z · от пола';

  @override
  String crossRail(Object number) {
    return 'Поперечная царга $number';
  }

  @override
  String get placeAgainstReference => 'Поставить по опоре';

  @override
  String get cubeRight => 'Право';

  @override
  String get rightHand => 'Правый';

  @override
  String get multiSelectionMenuHint =>
      'Правый щелчок по выделению — действия со всеми выбранными деталями';

  @override
  String get continuousDragHint =>
      'При перетаскивании положение и длина меняются плавно.';

  @override
  String get zoomIn => 'Приблизить';

  @override
  String rulerSnapModifier(Object modifier) {
    return 'Привязка линейки без $modifier';
  }

  @override
  String get snapLabel => 'Привязка';

  @override
  String get snapToAnchors => 'Привязка по опорам';

  @override
  String get apply => 'Применить';

  @override
  String get spaceLeftClick => 'Пробел + ЛКМ';

  @override
  String get checkTheExpression => 'Проверьте выражение';

  @override
  String sideRail(Object number) {
    return 'Продольная царга $number';
  }

  @override
  String get project => 'Проект';

  @override
  String get neprostoProject => 'Проект NeProSto';

  @override
  String get projectSaved => 'Проект сохранён';

  @override
  String get clearance => 'Просвет';

  @override
  String clearanceLabel(Object distance, Object unit) {
    return 'Просвет · $distance $unit';
  }

  @override
  String get square => 'Прямые';

  @override
  String get drawingControls => 'Работа с чертежом';

  @override
  String get workPlane => 'Рабочая плоскость';

  @override
  String workPlaneLabel(Object plane) {
    return 'Рабочая плоскость · $plane';
  }

  @override
  String equalGapValue(Object distance, Object unit) {
    return 'Равные зазоры · $distance $unit';
  }

  @override
  String get unlock => 'Разблокировать';

  @override
  String get ungroup => 'Разгруппировать';

  @override
  String get dimension => 'Размер';

  @override
  String get dimensionLocked => 'Размер заблокирован';

  @override
  String dimensionTabCount(Object count) {
    return 'Размеры  $count';
  }

  @override
  String get partDimensions => 'Размеры детали';

  @override
  String get dimensionsOnDrawing => 'Размеры на чертеже';

  @override
  String get endMarkings => 'Разметка торцов';

  @override
  String get stretchToHeight => 'Растянуть по высоте';

  @override
  String get stretchToWidth => 'Растянуть по ширине';

  @override
  String get editing => 'Редактирование';

  @override
  String get modeWithoutModifierKeys => 'Режим без нажатых клавиш';

  @override
  String get snapping => 'С привязкой';

  @override
  String get centimeters => 'Сантиметры';

  @override
  String get resetShortcuts => 'Сбросить сочетания';

  @override
  String get viewTop => 'Сверху';

  @override
  String get free => 'Свободно';

  @override
  String get freeView => 'Свободный вид';

  @override
  String get properties => 'Свойства';

  @override
  String get groupLabel => 'Сгруппировать';

  @override
  String get nudge => 'Сдвиг';

  @override
  String nudgeDistance(Object distance, Object unit) {
    return 'Сдвиг · $distance $unit';
  }

  @override
  String get panView => 'Сдвинуть вид';

  @override
  String get center => 'Середина';

  @override
  String get edgeMidpoint => 'Середина ребра';

  @override
  String get rulerEdge => 'Ребро';

  @override
  String get rulerUpperEdge => 'Верхнее ребро';

  @override
  String get rulerLowerEdge => 'Нижнее ребро';

  @override
  String get rulerCenterline => 'Средняя линия грани';

  @override
  String get viewBack => 'Сзади';

  @override
  String get bench => 'Скамья';

  @override
  String get downloadStarted => 'Скачивание началось';

  @override
  String get hideDimensions => 'Скрыть размеры';

  @override
  String get viewLeft => 'Слева';

  @override
  String get partDimensionIsTooSmall => 'Слишком маленький размер детали';

  @override
  String changeShortcutFor(Object command) {
    return 'Сменить сочетание для «$command»';
  }

  @override
  String get viewBottom => 'Снизу';

  @override
  String get join => 'Соединить';

  @override
  String get saving => 'Сохранение';

  @override
  String get save => 'Сохранить';

  @override
  String get saveChanges => 'Сохранить изменения?';

  @override
  String get saveAs => 'Сохранить как…';

  @override
  String get saveProject => 'Сохранить проект';

  @override
  String get saveProjectsAutomatically => 'Сохранять проекты автоматически';

  @override
  String get viewFront => 'Спереди';

  @override
  String get partsList => 'Список деталей';

  @override
  String get viewRight => 'Справа';

  @override
  String stepExample(
    Object step,
    Object unit,
    Object examples,
    Object exampleUnit,
  ) {
    return 'Стрелка сдвигает деталь на $step $unit. При растягивании длина меняется шагами, например $examples $exampleUnit.';
  }

  @override
  String get straightUpAlongZ => 'Строго вверх по Z';

  @override
  String get thicknessInitial => 'Т';

  @override
  String get thickness => 'Толщина';

  @override
  String thicknessLabel(Object unit) {
    return 'Толщина, $unit';
  }

  @override
  String onlyWith(Object modifier) {
    return 'Только с $modifier';
  }

  @override
  String get ends => 'Торцы';

  @override
  String get dragWithRightButton => 'Тянуть ПКМ';

  @override
  String get removeBounds => 'Убрать границы';

  @override
  String get miterJoint => 'Угловой стык';

  @override
  String get miterJointMenu => 'Угловой стык…';

  @override
  String get corner => 'Угол';

  @override
  String get delete => 'Удалить';

  @override
  String get deleteDimension => 'Удалить размер';

  @override
  String holdToSnap(Object modifier) {
    return 'Удерживайте $modifier для привязки.';
  }

  @override
  String freeMovementHint(Object modifier) {
    return 'Удерживайте $modifier, чтобы временно отключить привязку.';
  }

  @override
  String holdDimensionModifier(Object modifier, Object action) {
    return 'Удерживайте $modifier, чтобы $action размеры.';
  }

  @override
  String hold(Object modifier) {
    return 'Удерживать $modifier';
  }

  @override
  String alreadyAssignedTo(Object command) {
    return 'Уже назначено для «$command»';
  }

  @override
  String get setTheSecondDimensionPoint => 'Укажите вторую точку размера';

  @override
  String get setTheSourceAnchorOnThePart =>
      '1 из 2. Щёлкните по исходной точке на перемещаемой детали.';

  @override
  String get setTheEndOfThePart => 'Укажите конец детали';

  @override
  String get setTheStartOfThePart => 'Укажите начальную точку детали';

  @override
  String get setTheDestinationAnchor =>
      '2 из 2. Щёлкните там, куда нужно переместить эту точку.';

  @override
  String get setTheFirstDimensionPoint => 'Укажите первую точку размера';

  @override
  String get pickReferenceOnDrawing => 'Указать опору на чертеже';

  @override
  String stop(Object part) {
    return 'Упор · $part';
  }

  @override
  String get excelFileSaved => 'Файл Excel сохранён';

  @override
  String get frontPlane => 'Фронтальная';

  @override
  String get rearPlane => 'Задняя';

  @override
  String get centerPoint => 'Центр';

  @override
  String get faceCenter => 'Центр грани';

  @override
  String get partCenter => 'Центр детали';

  @override
  String get brusDrafts => 'Черновики Брус';

  @override
  String get browserDraftsHint =>
      'Черновики открытых вкладок сохраняются в этом браузере.';

  @override
  String get drawing => 'Чертёж';

  @override
  String addPartHint(Object shortcut) {
    return 'Нажмите $shortcut, чтобы добавить деталь';
  }

  @override
  String get widthInitial => 'Ш';

  @override
  String step(Object increment) {
    return 'Шаг $increment';
  }

  @override
  String get width => 'Ширина';

  @override
  String widthLabel(Object unit) {
    return 'Ширина, $unit';
  }

  @override
  String get clickAReferenceInTheDrawingOr =>
      'Щёлкните по опоре на чертеже или выберите её из списка.';

  @override
  String get clickTheReferencePart => 'Щёлкните по опорной детали';

  @override
  String get exportToExcel => 'Экспорт в Excel';

  @override
  String get reservedShortcut => 'Это системное сочетание. Выберите другое.';

  @override
  String get fileAlreadyOpen => 'Этот файл открыт в другой вкладке';

  @override
  String get off => 'выкл.';

  @override
  String get leftReferenceEdge => 'левого края';

  @override
  String get mm => 'мм';

  @override
  String get bottomReferenceEdge => 'нижнего края';

  @override
  String get frontReferenceEdge => 'переднего края';

  @override
  String get show => 'показать';

  @override
  String get hide => 'скрыть';

  @override
  String get cm => 'см';

  @override
  String get negativeThickness => '−Т';

  @override
  String get negativeWidth => '−Ш';

  @override
  String get close => 'Закрыть';

  @override
  String get appearance => 'Оформление';

  @override
  String get theme => 'Тема';

  @override
  String get light => 'Светлая';

  @override
  String get dark => 'Тёмная';

  @override
  String get language => 'Язык';

  @override
  String get aboutNeprosto => 'О NeProSto';

  @override
  String get fileMenu => 'Файл';

  @override
  String get settingsMenu => 'Настройки…';

  @override
  String get services => 'Службы';

  @override
  String get hideNeprosto => 'Скрыть NeProSto';

  @override
  String get hideOthers => 'Скрыть остальные';

  @override
  String get showAll => 'Показать все';

  @override
  String get quitNeprosto => 'Завершить NeProSto';

  @override
  String get edit => 'Правка';

  @override
  String get cut => 'Вырезать';

  @override
  String get copy => 'Копировать';

  @override
  String get paste => 'Вставить';

  @override
  String get pasteAndMatchStyle => 'Вставить в текущем стиле';

  @override
  String get selectAll => 'Выбрать все';

  @override
  String get find => 'Найти';

  @override
  String get findMenu => 'Найти…';

  @override
  String get findAndReplace => 'Найти и заменить…';

  @override
  String get findNext => 'Найти далее';

  @override
  String get findPrevious => 'Найти предыдущее';

  @override
  String get useSelectionForFind => 'Искать выделенное';

  @override
  String get jumpToSelection => 'Перейти к выделению';

  @override
  String get spellingAndGrammar => 'Орфография и грамматика';

  @override
  String get showSpellingAndGrammar => 'Показать орфографию и грамматику';

  @override
  String get checkDocumentNow => 'Проверить документ';

  @override
  String get checkSpellingWhileTyping => 'Проверять при вводе';

  @override
  String get checkGrammarWithSpelling => 'Проверять грамматику';

  @override
  String get correctSpellingAutomatically => 'Исправлять автоматически';

  @override
  String get substitutions => 'Замены';

  @override
  String get showSubstitutions => 'Показать замены';

  @override
  String get smartCopyPaste => 'Смарт-копирование и вставка';

  @override
  String get smartQuotes => 'Смарт-кавычки';

  @override
  String get smartDashes => 'Смарт-тире';

  @override
  String get smartLinks => 'Смарт-ссылки';

  @override
  String get dataDetectors => 'Распознавать данные';

  @override
  String get textReplacement => 'Замена текста';

  @override
  String get transformations => 'Преобразования';

  @override
  String get makeUpperCase => 'Прописные буквы';

  @override
  String get makeLowerCase => 'Строчные буквы';

  @override
  String get capitalize => 'С заглавных букв';

  @override
  String get speech => 'Речь';

  @override
  String get startSpeaking => 'Начать чтение';

  @override
  String get stopSpeaking => 'Остановить чтение';

  @override
  String get enterFullScreen => 'На весь экран';

  @override
  String get window => 'Окно';

  @override
  String get minimize => 'Свернуть';

  @override
  String get zoomLabel => 'Увеличить';

  @override
  String get bringAllToFront => 'Все окна на передний план';

  @override
  String get help => 'Справка';

  @override
  String get blankProject => 'Пустой проект';

  @override
  String get createProject => 'Создать проект';

  @override
  String get plywood => 'Фанера';

  @override
  String get mdf => 'МДФ';

  @override
  String get stockShopping => 'Материалы для покупки';

  @override
  String stockOffcut(String size) {
    return 'Подойдёт остаток от $size';
  }

  @override
  String stockKerf(String size) {
    return 'Пропил $size · размеры заготовок фактические';
  }

  @override
  String get stockBoard => 'Доска';

  @override
  String get stockBar => 'Брусок';

  @override
  String get stockSheet => 'Лист';

  @override
  String get shelfPart => 'Полка';

  @override
  String get sidePanel => 'Боковина';

  @override
  String get topPanel => 'Верхняя панель';

  @override
  String get bottomPanel => 'Дно';

  @override
  String get dividerPanel => 'Перегородка';

  @override
  String get backPanel => 'Задняя стенка';

  @override
  String get frontPanel => 'Передняя стенка';

  @override
  String get doorPanel => 'Дверца';

  @override
  String get tabletop => 'Столешница';

  @override
  String get seatPanel => 'Сиденье';

  @override
  String get tread => 'Ступень';

  @override
  String get carryHandle => 'Рукоятка';

  @override
  String get categoryShelving => 'Полки и стеллажи';

  @override
  String get categorySeating => 'Табуреты и скамьи';

  @override
  String get categoryTables => 'Столы';

  @override
  String get categoryCabinets => 'Тумбы и шкафы';

  @override
  String get categoryWorkshop => 'Мастерская и офис';

  @override
  String get templateBookcase => 'Дощатый стеллаж на четыре полки';

  @override
  String get templateCubeShelf => 'Ступенчатый стеллаж-перегородка';

  @override
  String get templateWallShelf => 'Парящая полка со скрытым каркасом';

  @override
  String get templateStool => 'Табурет с подставкой для гитары';

  @override
  String get templateStepStool => 'Двухступенчатый табурет';

  @override
  String get templateGardenBench => 'Садовая скамья с подлокотниками';

  @override
  String get templateDiningTable => 'Обеденный стол на двух опорах';

  @override
  String get templateWritingDesk => 'Письменный стол с боковыми полками';

  @override
  String get templateBedsideCabinet => 'Тумба с дверцей и нишей';

  @override
  String get templateBedroomWardrobe => 'Трёхстворчатый шкаф для спальни';

  @override
  String get openDoor => 'Открыть дверцу';

  @override
  String get closeDoor => 'Закрыть дверцу';

  @override
  String get panelHoles => 'Отверстия';

  @override
  String holeSelection(int number, int count) {
    return 'Отверстие $number из $count';
  }

  @override
  String get holeReferenceCorner => 'Отступы от угла';

  @override
  String get drillingType => 'Тип отверстия';

  @override
  String get drillingFace => 'Сторона сверления';

  @override
  String get noPanelHoles => 'На детали пока нет отверстий';

  @override
  String get addHole => 'Добавить отверстие';

  @override
  String get holeName => 'Название отверстия';

  @override
  String get showHoleNumbers => 'Показать номера на схеме';

  @override
  String holeDepthRange(String limit) {
    return 'Глубина должна быть больше нуля и меньше толщины детали ($limit).';
  }

  @override
  String holeDiameterRange(String limit) {
    return 'Диаметр должен быть больше нуля и не больше $limit.';
  }

  @override
  String holeOffsetRange(String minimum, String maximum) {
    return 'Отступ от края должен быть от $minimum до $maximum.';
  }

  @override
  String get holeDiameter => 'Диаметр';

  @override
  String get throughHole => 'Сквозное';

  @override
  String get blindHole => 'Глухое';

  @override
  String get faceA => 'Сторона А';

  @override
  String get faceB => 'Сторона Б';

  @override
  String get edgeBoringCommand => 'Присадка по кромке…';

  @override
  String get chooseBoringEdge => 'Нажмите на кромку детали';

  @override
  String get edgeBoringTitle => 'Присадка по кромке';

  @override
  String get boltBoreOption => 'Торцевое отверстие';

  @override
  String get boltFaceOffset => 'От пласти до оси';

  @override
  String get boltBoreDepth => 'Глубина с торца';

  @override
  String get boltBoreInvalid =>
      'Укажите диаметр и положение оси так, чтобы сверло помещалось в торце, а ось попадала в основное отверстие.';

  @override
  String get drillingParameters => 'Параметры сверления';

  @override
  String get boringReferenceEdge => 'Кромка отсчёта';

  @override
  String get boltReferenceFace => 'Базовая пласть';

  @override
  String get boreCenterDistance => 'До центра';

  @override
  String get boreRimDistance => 'До края отверстия';

  @override
  String boreCenterPitch(String length) {
    return 'Шаг между центрами — $length';
  }

  @override
  String get boreCount => 'Количество отверстий';

  @override
  String get boreOutsidePanel =>
      'Задайте отступ так, чтобы отверстие помещалось на детали.';

  @override
  String get enterBoreCount => 'Введите целое количество отверстий от 1.';

  @override
  String get boreEndOffsets => 'Отступы до центров отверстий';

  @override
  String get boreEndMarginsInvalid =>
      'Укажите отступы от торцов так, чтобы отверстия помещались на детали.';

  @override
  String get boreSpacingInvalid =>
      'Для такого количества и отступов отверстия расположены слишком близко.';

  @override
  String get boreCollision =>
      'Новое отверстие пересекает существующее. Измените отступы или количество.';

  @override
  String get addBoreRow => 'Добавить отверстия';

  @override
  String get fromLeft => 'От левого края';

  @override
  String get fromRight => 'От правого края';

  @override
  String get fromBottom => 'От нижнего края';

  @override
  String get fromTop => 'От верхнего края';

  @override
  String get invalidHole =>
      'Проверьте диаметр и отступы от краёв. Глубина глухого отверстия должна быть меньше толщины детали.';

  @override
  String get ordinaryPart => 'Элемент';

  @override
  String get chestLid => 'Крышка';

  @override
  String get groupType => 'Тип группы';

  @override
  String get groupProperties => 'Свойства группы';

  @override
  String get partProperties => 'Свойства детали';

  @override
  String get bazisExport => 'Для БАЗИС-Раскрой';

  @override
  String get partType => 'Тип детали';

  @override
  String get forwardDirection => 'Вперёд';

  @override
  String get towardViewer => 'К вам';

  @override
  String get awayFromViewer => 'От вас';

  @override
  String get liftUpDoor => 'Дверца вверх · петли сверху';

  @override
  String get dropDownDoor => 'Дверца вниз · петли снизу';

  @override
  String get hingesLeft => 'Петли слева';

  @override
  String get hingesRight => 'Петли справа';

  @override
  String get hingesTop => 'Петли сверху';

  @override
  String get hingesBottom => 'Петли снизу';

  @override
  String get chooseHingeEdge => 'Нажмите на край дверцы';

  @override
  String get doorAngle => 'Угол открывания';

  @override
  String get leftHingedDoor => 'Распашная дверца с петлями слева';

  @override
  String get rightHingedDoor => 'Распашная дверца с петлями справа';

  @override
  String get clothesRail => 'Штанга для одежды';

  @override
  String get templateTvStand => 'ТВ-тумба с отсеком для техники';

  @override
  String get templateWorkbench => 'Верстак Рубо с раздельной столешницей';

  @override
  String get templateToolTote => 'Ящик для инструмента с диагональной ручкой';

  @override
  String get cuttingLayout => 'Схема раскроя';

  @override
  String get categoryGarden => 'Сад и дача';

  @override
  String get templateDrawerChest => 'Комод с четырьмя ящиками';

  @override
  String get drawerFront => 'Фасад ящика';

  @override
  String get planterWall => 'Доска борта';

  @override
  String get uprightPost => 'Стойка';

  @override
  String get deckBoard => 'Доска настила';

  @override
  String get frameRail => 'Обвязка';

  @override
  String get trellisSlat => 'Рейка шпалеры';

  @override
  String get benchBack => 'Планка спинки';

  @override
  String get landingRail => 'Поручень';

  @override
  String get roofBoard => 'Доска крыши';

  @override
  String get rackFinger => 'Держатель струбцины';

  @override
  String get templatePicnicTable => 'Детский стол для пикника с лавками';

  @override
  String get templateSawhorse => 'Столярные козлы';

  @override
  String get templateClampRack => 'Гребёнка для струбцин';

  @override
  String get templateRaisedBed => 'Высокая грядка с обвязкой';

  @override
  String get templateStandingPlanter => 'Деревянное кашпо на ножках';

  @override
  String get templateTrellisPlanter => 'Кашпо со шпалерой';

  @override
  String get templatePorch => 'Входное крыльцо с площадкой и перилами';

  @override
  String get templateChaise => 'Реечный шезлонг';

  @override
  String get templatePottingBench => 'Посадочный стол с нишей для лотка';

  @override
  String get templateLogStore => 'Дровница с односкатной крышей';

  @override
  String get categoryConstruction => 'Столярка и каркасы';

  @override
  String get floorJoist => 'Лага пола';

  @override
  String get bridging => 'Диагональная распорка';

  @override
  String get headerBeam => 'Перемычка проёма';

  @override
  String get windowSill => 'Подоконная доска каркаса';

  @override
  String get roofRafter => 'Стропило';

  @override
  String get ridgeBeam => 'Коньковая балка';

  @override
  String get doorStile => 'Стойка дверного полотна';

  @override
  String get doorPanelInfill => 'Доска филёнки';

  @override
  String get gatePicket => 'Штакетина';

  @override
  String get framingNote =>
      'Показаны лаги и распорки до укладки настила. Опоры, пролёт, сорт древесины, настил и крепёж рассчитывают по местным нагрузкам.';

  @override
  String get roofNote =>
      'Эскиз для привязки к участку. Фундамент, анкеры, кровлю и соединения подбирают по грунту, снегу, ветру и сейсмике региона.';

  @override
  String get porchNote =>
      'Привяжите отметку площадки к порогу и ходу двери. Для строительства проверьте фундамент, ступени, ограждения и крепления по местным нормам.';

  @override
  String get doorNote =>
      'Показано дверное полотно. Монтажные зазоры, коробку и петли подбирают по проёму и массе полотна.';

  @override
  String get gateNote =>
      'Петли слева при взгляде со стороны подкоса. Подкос опирается на нижнюю перекладину у петель и поддерживает верхний свободный угол.';

  @override
  String get templateShedFloor => 'Каркас пола бытовки с распорками «ёлочкой»';

  @override
  String get templateWindowWall => 'Каркасная стена с оконным проёмом';

  @override
  String get templateCornerWalls => 'Угол двух каркасных стен';

  @override
  String get templatePanelDoor => 'Межкомнатная рамочная дверь';

  @override
  String get templateGardenGate => 'Штакетная калитка с подкосом';

  @override
  String get wallFrameNote =>
      'Показан каркас до обшивки. По местным нагрузкам рассчитывают стойки, перемычки, обшивку или укосины для жёсткости и анкеровку стен.';

  @override
  String get templateSignatureCabinet => 'Фирменная тумба NeProSto';

  @override
  String get signatureDoor => 'Фасад с отверстием для пальца';

  @override
  String get endCutsTitle => 'Торцевые срезы';

  @override
  String get faceMarkAngle => 'Разметка по ширине';

  @override
  String get edgeMarkAngle => 'Разметка по толщине';

  @override
  String cutOffsetReadout(String distance) {
    return 'Смещение $distance';
  }

  @override
  String get mitreSaw => 'Торцовочная пила';

  @override
  String get handheldSaw => 'Ручная циркулярная';

  @override
  String get tableSaw => 'Пильный стол';

  @override
  String get sawCutLine => 'Линия пропила';

  @override
  String get sawFeed => 'Подача';

  @override
  String get sawCrosscutFence => 'Поперечный упор';

  @override
  String get sawTableSight => 'В разрезе';

  @override
  String get sawFeedView => 'Со стороны подачи';

  @override
  String sawFenceNear(String angle) {
    return '$angle° · правый край к себе';
  }

  @override
  String sawFenceFar(String angle) {
    return '$angle° · правый край от себя';
  }

  @override
  String get sawStockPosition => 'Деталь плашмя, начало слева';

  @override
  String get sawTableRotation => 'Поворот стола';

  @override
  String get sawBladeTilt => 'Наклон диска';

  @override
  String sawAngleLeft(String angle) {
    return '$angle° влево';
  }

  @override
  String sawAngleRight(String angle) {
    return '$angle° вправо';
  }

  @override
  String get resetEndCut => 'Сбросить углы';

  @override
  String get cutsIntersect =>
      'Срезы пересекаются или оставляют слишком короткую кромку. Уменьшите угол одного из торцов.';

  @override
  String angleToLongEdge(String angle) {
    return 'К продольной кромке $angle°';
  }

  @override
  String get rabbetTitle => 'Выборка фальца';

  @override
  String get rabbetTopLeft => 'Верхнее левое';

  @override
  String get rabbetTopRight => 'Верхнее правое';

  @override
  String get rabbetBottomLeft => 'Нижнее левое';

  @override
  String get rabbetBottomRight => 'Нижнее правое';

  @override
  String get rabbetDepth => 'Глубина';

  @override
  String get rabbetView => 'Вид с конечного торца. Выберите продольное ребро.';

  @override
  String get rabbetRemove => 'Убрать фальц';

  @override
  String get invalidRabbet =>
      'Задайте положительные ширину и глубину. Между фальцами и до противоположной грани должен оставаться материал.';

  @override
  String get templateLaptopTray => 'Поднос для ноутбука';

  @override
  String get templateBagShelf => 'Вешалка с полкой для сумок';

  @override
  String get templatePantryShelf => 'Узкая полка за дверью';

  @override
  String get templateConsoleTable => 'Консоль за диван с тремя секциями';

  @override
  String get templateMachineStand => 'Подставка для торцовочной пилы';

  @override
  String get templateTrestleBench => 'Лавка на наклонных ножках';

  @override
  String get templateWindowBox => 'Оконный ящик для цветов';

  @override
  String get templateBirdhouse => 'Треугольный домик для птиц';

  @override
  String get templateCandleShelf => 'Полка-подсвечник с треугольниками';

  @override
  String get templateBlanketLadder => 'Лестница для полотенец';

  @override
  String get templateHeadphoneStand => 'Настольная подставка для наушников';

  @override
  String get templatePlantPanel => 'Настенная панель для растений';

  @override
  String get templateToyChest => 'Реечный ящик для игрушек';

  @override
  String get templateShutters => 'Трёхстворчатые складные ставни';

  @override
  String get templateLantern => 'Декоративный фонарь для террасы';

  @override
  String get templateMirrorFrame => 'Напольная рама для зеркала';

  @override
  String get templateHexShelf => 'Шестиугольная полка-сота';

  @override
  String get templateCoffeeTable => 'Журнальный столик с нижней полкой';

  @override
  String get templateShoeBench => 'Скамья для обуви с тремя нишами';

  @override
  String get templateTrivet => 'Решётчатая подставка под горячее';

  @override
  String get categoryHousehold => 'Для дома';

  @override
  String get planEasy => 'Легко';

  @override
  String get planMedium => 'Средняя сложность';

  @override
  String get planAdvanced => 'Сложно';

  @override
  String get planSource => 'Фото и чертёж оригинала';

  @override
  String get planDrawing => 'Чертёж оригинала (ZIP)';

  @override
  String get planAdaptation =>
      'Модель адаптирована для редактора. В раскрой входят деревянные детали.';

  @override
  String get planHardwareHooks =>
      'Предусмотрите три крючка и подвесы для стены.';

  @override
  String get planShutterNote =>
      'Между створками оставлено по 3 мм под петли. Уточните зазоры по выбранной фурнитуре.';

  @override
  String get planLadderNote =>
      'Декоративная вешалка для пледов. Предусмотрите фиксацию к стене.';

  @override
  String get planChestNote =>
      'Для крышки нужны петли и опора, удерживающая её открытой.';

  @override
  String get planMirrorNote =>
      'Отдельно нужны зеркало 407 × 1525 мм, крепление полотна и фиксация рамы к стене.';

  @override
  String get planRoundedNote =>
      'Показаны прямоугольные заготовки. Скруглите контактные кромки при отделке.';

  @override
  String get planTrivetNote =>
      'Вариант по рисунку Craftsmanspace: два слоя реек 12 × 7 мм склеиваются крест-накрест.';

  @override
  String get roomKitchen => 'Кухня';

  @override
  String get roomLivingRoom => 'Гостиная';

  @override
  String get roomBedroom => 'Спальня';

  @override
  String get roomNursery => 'Детская';

  @override
  String get roomEntryway => 'Прихожая';

  @override
  String get roomBathroom => 'Ванная';

  @override
  String get roomOffice => 'Кабинет';

  @override
  String get templateAssembly => 'Как собрать';

  @override
  String get templateHoodCabinet => 'Навесной шкаф под вытяжку';

  @override
  String get templateSinkBase => 'Корпус тумбы под мойку';

  @override
  String get templatePlatformBed => 'Кровать с реечным основанием';

  @override
  String get templateBasinShelf => 'Подвесная тумба с вырезом под сифон';

  @override
  String get templateFileTrays => 'Трёхъярусный лоток для бумаги';

  @override
  String get ductOpening => 'Проход воздуховода';

  @override
  String get chaseSide => 'Боковина короба';

  @override
  String get chaseCover => 'Съёмная стенка короба';

  @override
  String get hangingRail => 'Монтажная планка';

  @override
  String get hingeCup => 'Чашка петли';

  @override
  String get plinth => 'Цоколь';

  @override
  String get slatLedger => 'Опорная рейка';

  @override
  String get centerRail => 'Центральная балка';

  @override
  String get bedSlat => 'Рейка основания';

  @override
  String get shelfWing => 'Боковая часть полки';

  @override
  String get paperTray => 'Полка для бумаги';

  @override
  String get bedRim => 'Борт грядки с запилами';

  @override
  String get assembleHoodCabinet =>
      'Дно и крышку стяните с боковинами конфирматами. Полки закрепите между боковинами и щеками короба, лицевую стенку короба прикрутите съёмно. Труба проходит через два соосных отверстия. Положение и диаметр прохода, точки крепления снизу и высоту установки сверьте с монтажным шаблоном вашей вытяжки. Дверцы навесьте на чашечные петли, шкаф закрепите через монтажные планки.';

  @override
  String get assembleSinkBase =>
      'Дно и верхние стяжки соедините с боковинами конфирматами, цоколь прикрутите с внутренней стороны. Стяжки связывают открытый верх под столешницей. Задняя перемычка оставляет доступ к водопроводу и сливу.';

  @override
  String get assemblePantryShelf =>
      'Полки закрепите между боковинами винтами через боковые стенки. Передние ограничители прикрутите к торцам боковин. Высокий узкий стеллаж закрепите к стене.';

  @override
  String get assembleDiningTable =>
      'Сначала соберите две рамные опоры, стянув поперечины с ножками болтами. Прикрепите каждую доску столешницы к обеим рамам снизу, оставив между досками зазоры.';

  @override
  String get assembleSignatureCabinet =>
      'Соберите ступенчатый корпус на шкантах и клею, затем приклейте лицевые планки. Задние стенки удерживают корпус прямоугольным. Навесьте фасад на петли, круглое сквозное отверстие служит ручкой.';

  @override
  String get assembleBookcase =>
      'Соберите две боковые рамы, прикрутив поперечины к стойкам. Закрепите опорные бруски и привинтите доски каждой полки к обеим опорам. Верх стеллажа закрепите к стене.';

  @override
  String get assembleCoffeeTable =>
      'Соедините царги с ножками на шкантах с клеем. Нижнюю полку уложите на планки между царгами. Фанерную столешницу закрепите снизу через угловые крепления.';

  @override
  String get assembleTvStand =>
      'Соедините панели корпуса и перегородки конфирматами. Закрепите спинку по периметру и к перегородкам. Крайние секции закрываются накладными фасадами, средняя остаётся открытой.';

  @override
  String get assembleBedroomWardrobe =>
      'Стяните дно, крышку и перегородки конфирматами. Поставьте штанги на держатели, закрепите полки и задние панели. Петли навесьте со стороны, указанной у каждой двери. Высокий корпус закрепите к стене.';

  @override
  String get assemblePlatformBed =>
      'Царги соедините разборными кроватными стяжками. Изнутри прикрутите опорные рейки. Центральную балку поставьте на отдельные ножки и закрепите к торцевым царгам. Ламели опираются на три линии и фиксируются от сдвига.';

  @override
  String get assembleDrawerChest =>
      'Корпус соберите на конфирматах. Дно и заднюю стенку каждого ящика соедините с боковинами, затем закрепите фасад изнутри. Парные направляющие ставьте на одной высоте с учётом бокового зазора выбранного комплекта. Корпус закрепите к стене.';

  @override
  String get assembleToyChest =>
      'Склейте парные стойки. Торцы досок стенок и нижней обвязки притяните к стойкам косыми шурупами через карманы с внутренней стороны. Доски дна прикрутите сверху к обвязке, планки крышки — снизу к поперечинам. Рояльную петлю поставьте вдоль верхней задней доски. Подберите упор под вес крышки, чтобы он удерживал её в любом положении. Оставьте вентиляционные щели открытыми.';

  @override
  String get assembleCubeShelf =>
      'Начните с общей нижней панели. Ступени собирайте снизу вверх на шкантах и мебельных стяжках, пока доступны торцы полок. Собранный стеллаж закрепите к стене.';

  @override
  String get assembleStepStool =>
      'Склейте фанерные боковины с подступенками на шкантах. Проступи положите сверху на опоры и закрепите потайными шурупами. Проверьте, что обе боковины стоят на полу всей нижней кромкой.';

  @override
  String get assembleShoeBench =>
      'Соберите цоколь, поставьте на него дно. Стенки и перегородки стяните с сиденьем и дном на шкантах с клеем. Заднюю панель закрепите по краям, чтобы скамья сохраняла форму.';

  @override
  String get assembleConsoleTable =>
      'Стяните боковины с верхней и нижней панелями. Полки соедините с перегородками шкантами при сборке каждой секции. Для узкой консоли предусмотрите крепление к стене.';

  @override
  String get assembleMirrorFrame =>
      'Поперечины соедините со стойками на шкантах. Соберите проставки, запилите их задние торцы по модели и закрепите раму к стене. Зеркало установите на отдельные держатели для стекла.';

  @override
  String get assembleBasinShelf =>
      'У каждой полки передняя часть и два крыла образуют открытый назад вырез под сифон. Соедините их на шкантах с влагостойким клеем, затем закрепите между боковинами. Монтажные планки за крыльями притяните к стене, торцы фанеры защитите от влаги.';

  @override
  String get assembleBlanketLadder =>
      'Перекладины соедините со стойками на двух шкантах с каждой стороны, зафиксировав их от проворачивания. Верх закрепите к стене. Лестница предназначена для полотенец.';

  @override
  String get assembleWritingDesk =>
      'Столешница опирается на боковину и тумбу с полками. Соедините панели конфирматами, затем закрепите задние перемычки между опорами. Перемычки удерживают стол от бокового раскачивания.';

  @override
  String get assembleWallShelf =>
      'Прикрутите поперечные бруски к задней рейке. Закрепите рейку на несущем основании стены, наденьте фанерный кожух и прикрутите его к каркасу снизу.';

  @override
  String get assembleFileTrays =>
      'Приклейте опорные рейки попарно на одной высоте. Вложите в каждый ярус фанерную полку и закрепите заднюю стенку, чтобы боковины не расходились.';

  @override
  String get assembleWorkbench =>
      'Склейте ножки и обе половины наборной столешницы по отдельности. Царги стяните с ножками болтами. Половины столешницы закрепите к подстолью снизу, сохранив продольный просвет и возможность сезонного движения древесины.';

  @override
  String get assembleSawhorse =>
      'Запилите торцы наклонных ножек по модели, чтобы они опирались на пол и под верхнюю доску всей плоскостью. Стяните боковые фартуки с ножками болтами и закрепите нижние распорки.';

  @override
  String get assembleMachineStand =>
      'Соберите две торцевые рамы, стяните их продольными царгами. Закрепите фанерные настилы сверху к обвязке. Нижняя полка состоит из трёх частей и обходит ножки.';

  @override
  String get assembleRaisedBed =>
      'Доски стенок прикрутите снаружи к угловым и средним стойкам уличными шурупами. Средние стойки соедините поперечной стяжкой. Все четыре верхних борта запилите с обоих концов под 45° и закрепите сверху к стойкам.';

  @override
  String get assembleBench =>
      'Соедините продольные и поперечные царги с ножками шкантами на клею или косыми шурупами изнутри. Выставьте одинаковые зазоры между планками сиденья и прикрутите их сверху к царгам.';

  @override
  String get assemblePicnicTable =>
      'Сначала соберите две А-образные опоры. Скошенные ножки соедините с поперечинами сквозными болтами и шайбами. Положите доски стола и сидений на опоры, закрепите их сверху, затем установите продольную стяжку.';

  @override
  String get assembleChaise =>
      'Соберите боковые рамы. Спинку закрепите в заданном наклоне на болтах, выдерживая запилы опор. Прикрутите рейки сиденья и спинки к обеим боковинам, оставив зазоры для стока воды.';

  @override
  String get assemblePottingBench =>
      'Соберите каркас из стоек и царг на уличных шурупах. Настил столешницы закрепите на поперечинах, оставив проём для съёмного лотка. Задние стойки несут отдельную верхнюю полку.';

  @override
  String get assembleLogStore =>
      'Стяните стойки продольной обвязкой, положите доски пола на поперечины. Верхние торцы стоек запилите по уклону крыши. Рейки стен закрепите с зазорами для проветривания дров.';

  @override
  String get assembleGardenGate =>
      'Прикрутите штакетины к двум поперечинам. Запилите подкос так, чтобы он упирался торцами в обе перекладины и передавал нагрузку от верхнего свободного угла к нижней петле. Петли крепите в поперечины.';

  @override
  String get assembleBirdhouse =>
      'Сведите запиленные кромки скатов в коньке. Торцевые панели и дно прикрутите к скатам через предварительно просверленные отверстия. Один торец закрепите съёмно для очистки.';

  @override
  String get assemblePorch =>
      'Соберите рамы ступеней и площадки, закрепите настил к поперечинам. Стойки ограждения стяните с рамой болтами. Поручень подрежьте под уклон и закрепите на стойках. Крепление к основанию выбирают по месту установки.';
}
