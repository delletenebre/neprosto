// ignore_for_file: deprecated_member_use
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ky.dart';
import 'app_localizations_ru.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ky'),
    Locale('ru'),
  ];

  /// No description provided for @layFaceDown.
  ///
  /// In ru, this message translates to:
  /// **'Положить этой гранью вниз'**
  String get layFaceDown;

  /// No description provided for @stockTurnHint.
  ///
  /// In ru, this message translates to:
  /// **'Выберите плоскость и нажмите стрелку −90° или +90° на заготовке.'**
  String get stockTurnHint;

  /// No description provided for @linkToHole.
  ///
  /// In ru, this message translates to:
  /// **'Привязать к центру № {number}'**
  String linkToHole(int number);

  /// No description provided for @holeGroups.
  ///
  /// In ru, this message translates to:
  /// **'Группы отверстий'**
  String get holeGroups;

  /// No description provided for @addLinkedShaft.
  ///
  /// In ru, this message translates to:
  /// **'Добавить торцевое к центру'**
  String get addLinkedShaft;

  /// No description provided for @addEdgeBore.
  ///
  /// In ru, this message translates to:
  /// **'Добавить торцевое…'**
  String get addEdgeBore;

  /// No description provided for @linkedFaceHole.
  ///
  /// In ru, this message translates to:
  /// **'К отверстию № {number}'**
  String linkedFaceHole(int number);

  /// No description provided for @anchoredFaceHole.
  ///
  /// In ru, this message translates to:
  /// **'Привязка к отверстию № {number}'**
  String anchoredFaceHole(int number);

  /// No description provided for @detachHoleAnchor.
  ///
  /// In ru, this message translates to:
  /// **'Снять привязку'**
  String get detachHoleAnchor;

  /// No description provided for @pointAnchor.
  ///
  /// In ru, this message translates to:
  /// **'Привязка к точке'**
  String get pointAnchor;

  /// No description provided for @faceMagnet.
  ///
  /// In ru, this message translates to:
  /// **'Магнит при перемещении'**
  String get faceMagnet;

  /// No description provided for @pickHoleAnchor.
  ///
  /// In ru, this message translates to:
  /// **'{modifier}-клик по схеме — привязать отверстие к точке или центру другого отверстия'**
  String pickHoleAnchor(String modifier);

  /// No description provided for @drillMode.
  ///
  /// In ru, this message translates to:
  /// **'3D'**
  String get drillMode;

  /// No description provided for @faceMarkA.
  ///
  /// In ru, this message translates to:
  /// **'А'**
  String get faceMarkA;

  /// No description provided for @faceMarkB.
  ///
  /// In ru, this message translates to:
  /// **'Б'**
  String get faceMarkB;

  /// No description provided for @spatialOverview.
  ///
  /// In ru, this message translates to:
  /// **'Общий вид'**
  String get spatialOverview;

  /// No description provided for @clearOrbitPivot.
  ///
  /// In ru, this message translates to:
  /// **'Сбросить опору вращения'**
  String get clearOrbitPivot;

  /// No description provided for @holeNavigationHint.
  ///
  /// In ru, this message translates to:
  /// **'{modifier}⇧-клик — опора · ПКМ — вращение · {modifier} + колесо — масштаб'**
  String holeNavigationHint(String modifier);

  /// No description provided for @openingSensor.
  ///
  /// In ru, this message translates to:
  /// **'Датчик открывания'**
  String get openingSensor;

  /// No description provided for @customDrill.
  ///
  /// In ru, this message translates to:
  /// **'Своё сверление'**
  String get customDrill;

  /// No description provided for @drillMagnet.
  ///
  /// In ru, this message translates to:
  /// **'Магнит'**
  String get drillMagnet;

  /// No description provided for @drillHint.
  ///
  /// In ru, this message translates to:
  /// **'Клик — сверлить · Shift-клик — задать ноль'**
  String get drillHint;

  /// No description provided for @edgeOrbitHint.
  ///
  /// In ru, this message translates to:
  /// **'Клик по торцу — выбрать'**
  String get edgeOrbitHint;

  /// No description provided for @resetDatum.
  ///
  /// In ru, this message translates to:
  /// **'Сбросить базу'**
  String get resetDatum;

  /// No description provided for @drillGridInvalid.
  ///
  /// In ru, this message translates to:
  /// **'Введите отступ от нуля и положительный шаг.'**
  String get drillGridInvalid;

  /// No description provided for @addConnection.
  ///
  /// In ru, this message translates to:
  /// **'Добавить соединение'**
  String get addConnection;

  /// No description provided for @connectionWoodScrew.
  ///
  /// In ru, this message translates to:
  /// **'Саморез по дереву'**
  String get connectionWoodScrew;

  /// No description provided for @connectionTouchRequired.
  ///
  /// In ru, this message translates to:
  /// **'Выберите две детали, которые соприкасаются гранями'**
  String get connectionTouchRequired;

  /// No description provided for @connectionLayoutUnavailable.
  ///
  /// In ru, this message translates to:
  /// **'Для этих деталей не получается разместить выбранный крепёж. Проверьте положение деталей или параметры присадки.'**
  String get connectionLayoutUnavailable;

  /// No description provided for @confirmat.
  ///
  /// In ru, this message translates to:
  /// **'Конфирмат'**
  String get confirmat;

  /// No description provided for @dowel.
  ///
  /// In ru, this message translates to:
  /// **'Шкант'**
  String get dowel;

  /// No description provided for @dowels.
  ///
  /// In ru, this message translates to:
  /// **'Шканты'**
  String get dowels;

  /// No description provided for @connectionRuler.
  ///
  /// In ru, this message translates to:
  /// **'Шкала соединений'**
  String get connectionRuler;

  /// No description provided for @datumOffset.
  ///
  /// In ru, this message translates to:
  /// **'Первая отметка от базы'**
  String get datumOffset;

  /// No description provided for @markPitch.
  ///
  /// In ru, this message translates to:
  /// **'Шаг шкалы'**
  String get markPitch;

  /// No description provided for @baseDistance.
  ///
  /// In ru, this message translates to:
  /// **'Расстояние от базы'**
  String get baseDistance;

  /// No description provided for @panelFaces.
  ///
  /// In ru, this message translates to:
  /// **'Пласти'**
  String get panelFaces;

  /// No description provided for @panelEdges.
  ///
  /// In ru, this message translates to:
  /// **'Торцы'**
  String get panelEdges;

  /// No description provided for @beforeHardware.
  ///
  /// In ru, this message translates to:
  /// **'До крепежа'**
  String get beforeHardware;

  /// No description provided for @afterHardware.
  ///
  /// In ru, this message translates to:
  /// **'После крепежа'**
  String get afterHardware;

  /// No description provided for @bothHardware.
  ///
  /// In ru, this message translates to:
  /// **'С двух сторон'**
  String get bothHardware;

  /// No description provided for @chooseConnectionBase.
  ///
  /// In ru, this message translates to:
  /// **'Нажмите на торец ближе к тому углу, от которого вести отсчёт.'**
  String get chooseConnectionBase;

  /// No description provided for @placeConnection.
  ///
  /// In ru, this message translates to:
  /// **'Переместите шаблон вдоль шкалы и нажмите, чтобы добавить отверстия.'**
  String get placeConnection;

  /// No description provided for @placeOnDrawing.
  ///
  /// In ru, this message translates to:
  /// **'Разместить на схеме'**
  String get placeOnDrawing;

  /// No description provided for @connectionDoesNotFit.
  ///
  /// In ru, this message translates to:
  /// **'Присадка выходит за границы детали.'**
  String get connectionDoesNotFit;

  /// No description provided for @camThickness.
  ///
  /// In ru, this message translates to:
  /// **'Недостаточная толщина для этого эксцентрика'**
  String get camThickness;

  /// No description provided for @datum.
  ///
  /// In ru, this message translates to:
  /// **'База'**
  String get datum;

  /// No description provided for @emptyEdge.
  ///
  /// In ru, this message translates to:
  /// **'На этом торце нет отверстий'**
  String get emptyEdge;

  /// No description provided for @pocketShoulder.
  ///
  /// In ru, this message translates to:
  /// **'Глубина до уступа'**
  String get pocketShoulder;

  /// No description provided for @edgeBanding.
  ///
  /// In ru, this message translates to:
  /// **'Кромка'**
  String get edgeBanding;

  /// No description provided for @bandWholePerimeter.
  ///
  /// In ru, this message translates to:
  /// **'Весь периметр'**
  String get bandWholePerimeter;

  /// No description provided for @deselectAllEdges.
  ///
  /// In ru, this message translates to:
  /// **'Снять все'**
  String get deselectAllEdges;

  /// No description provided for @bandingEdges.
  ///
  /// In ru, this message translates to:
  /// **'Торцы'**
  String get bandingEdges;

  /// No description provided for @bandThickness.
  ///
  /// In ru, this message translates to:
  /// **'Толщина ленты'**
  String get bandThickness;

  /// No description provided for @bandWidth.
  ///
  /// In ru, this message translates to:
  /// **'Ширина ленты'**
  String get bandWidth;

  /// No description provided for @matchPanelThickness.
  ///
  /// In ru, this message translates to:
  /// **'По толщине детали'**
  String get matchPanelThickness;

  /// No description provided for @invalidEdgeBanding.
  ///
  /// In ru, this message translates to:
  /// **'Некорректные параметры кромки'**
  String get invalidEdgeBanding;

  /// No description provided for @positiveBandSize.
  ///
  /// In ru, this message translates to:
  /// **'Введите размер больше нуля.'**
  String get positiveBandSize;

  /// No description provided for @woodBasedPanel.
  ///
  /// In ru, this message translates to:
  /// **'ДПМ'**
  String get woodBasedPanel;

  /// No description provided for @woodBasedPanelFullName.
  ///
  /// In ru, this message translates to:
  /// **'Древесный плитный материал'**
  String get woodBasedPanelFullName;

  /// No description provided for @panelFaceColor.
  ///
  /// In ru, this message translates to:
  /// **'Цвет поверхности'**
  String get panelFaceColor;

  /// No description provided for @edgeBandColor.
  ///
  /// In ru, this message translates to:
  /// **'Цвет кромки'**
  String get edgeBandColor;

  /// No description provided for @partFinish.
  ///
  /// In ru, this message translates to:
  /// **'Материал'**
  String get partFinish;

  /// No description provided for @mixedValues.
  ///
  /// In ru, this message translates to:
  /// **'Разные'**
  String get mixedValues;

  /// No description provided for @pineColor.
  ///
  /// In ru, this message translates to:
  /// **'Сосна'**
  String get pineColor;

  /// No description provided for @oakColor.
  ///
  /// In ru, this message translates to:
  /// **'Дуб'**
  String get oakColor;

  /// No description provided for @whiteColor.
  ///
  /// In ru, this message translates to:
  /// **'Белый'**
  String get whiteColor;

  /// No description provided for @grayColor.
  ///
  /// In ru, this message translates to:
  /// **'Серый'**
  String get grayColor;

  /// No description provided for @graphiteColor.
  ///
  /// In ru, this message translates to:
  /// **'Графит'**
  String get graphiteColor;

  /// No description provided for @beigeColor.
  ///
  /// In ru, this message translates to:
  /// **'Бежевый'**
  String get beigeColor;

  /// No description provided for @blackColor.
  ///
  /// In ru, this message translates to:
  /// **'Чёрный'**
  String get blackColor;

  /// No description provided for @greenColor.
  ///
  /// In ru, this message translates to:
  /// **'Зелёный'**
  String get greenColor;

  /// No description provided for @blueColor.
  ///
  /// In ru, this message translates to:
  /// **'Синий'**
  String get blueColor;

  /// No description provided for @brickColor.
  ///
  /// In ru, this message translates to:
  /// **'Кирпичный'**
  String get brickColor;

  /// No description provided for @finishTexture.
  ///
  /// In ru, this message translates to:
  /// **'Текстура'**
  String get finishTexture;

  /// No description provided for @finishColor.
  ///
  /// In ru, this message translates to:
  /// **'Цвет'**
  String get finishColor;

  /// No description provided for @metal.
  ///
  /// In ru, this message translates to:
  /// **'Металл'**
  String get metal;

  /// No description provided for @solidColor.
  ///
  /// In ru, this message translates to:
  /// **'Однотонный'**
  String get solidColor;

  /// No description provided for @naturalWood.
  ///
  /// In ru, this message translates to:
  /// **'Дерево'**
  String get naturalWood;

  /// No description provided for @whiteBoard.
  ///
  /// In ru, this message translates to:
  /// **'ЛДСП · белая'**
  String get whiteBoard;

  /// No description provided for @oakBoard.
  ///
  /// In ru, this message translates to:
  /// **'ЛДСП · дуб'**
  String get oakBoard;

  /// No description provided for @aluminumProfile.
  ///
  /// In ru, this message translates to:
  /// **'Алюминиевый профиль'**
  String get aluminumProfile;

  /// No description provided for @steelProfile.
  ///
  /// In ru, this message translates to:
  /// **'Стальной профиль · графит'**
  String get steelProfile;

  /// No description provided for @invalidPartFinish.
  ///
  /// In ru, this message translates to:
  /// **'Некорректный материал детали'**
  String get invalidPartFinish;

  /// No description provided for @invalidHexColor.
  ///
  /// In ru, this message translates to:
  /// **'Введите цвет в формате #RRGGBB'**
  String get invalidHexColor;

  /// No description provided for @positiveThickness.
  ///
  /// In ru, this message translates to:
  /// **'+Т'**
  String get positiveThickness;

  /// No description provided for @positiveWidth.
  ///
  /// In ru, this message translates to:
  /// **'+Ш'**
  String get positiveWidth;

  /// No description provided for @xWidth.
  ///
  /// In ru, this message translates to:
  /// **'X · ширина'**
  String get xWidth;

  /// No description provided for @horizontalPlane.
  ///
  /// In ru, this message translates to:
  /// **'Горизонтальная'**
  String get horizontalPlane;

  /// No description provided for @workPlanePurpose.
  ///
  /// In ru, this message translates to:
  /// **'Где строить и перемещать детали?'**
  String get workPlanePurpose;

  /// No description provided for @horizontalPlaneExample.
  ///
  /// In ru, this message translates to:
  /// **'Как полка или столешница'**
  String get horizontalPlaneExample;

  /// No description provided for @frontPlaneExample.
  ///
  /// In ru, this message translates to:
  /// **'Как дверца шкафа'**
  String get frontPlaneExample;

  /// No description provided for @sidePlaneExample.
  ///
  /// In ru, this message translates to:
  /// **'Как боковина шкафа'**
  String get sidePlaneExample;

  /// No description provided for @partFacePlane.
  ///
  /// In ru, this message translates to:
  /// **'По грани детали'**
  String get partFacePlane;

  /// No description provided for @workPlaneNeedsPart.
  ///
  /// In ru, this message translates to:
  /// **'Нужна видимая деталь на чертеже'**
  String get workPlaneNeedsPart;

  /// No description provided for @yDepth.
  ///
  /// In ru, this message translates to:
  /// **'Y · глубина'**
  String get yDepth;

  /// No description provided for @zHeight.
  ///
  /// In ru, this message translates to:
  /// **'Z · высота'**
  String get zHeight;

  /// No description provided for @edgeCaption.
  ///
  /// In ru, this message translates to:
  /// **'{side}\nкрай'**
  String edgeCaption(Object side);

  /// No description provided for @scrollGesture.
  ///
  /// In ru, this message translates to:
  /// **'{modifier} + скролл'**
  String scrollGesture(Object modifier);

  /// No description provided for @sketchEndHint.
  ///
  /// In ru, this message translates to:
  /// **'{part} · {width} × {thickness} {unit} · укажите конец'**
  String sketchEndHint(
    Object part,
    Object width,
    Object thickness,
    Object unit,
  );

  /// No description provided for @liftHint.
  ///
  /// In ru, this message translates to:
  /// **'{instruction} · {modifier} — вверх · с Shift — строго по Z'**
  String liftHint(Object instruction, Object modifier);

  /// No description provided for @endAngleValue.
  ///
  /// In ru, this message translates to:
  /// **'{end} · {angle}° от прямого'**
  String endAngleValue(Object end, Object angle);

  /// No description provided for @unsavedTab.
  ///
  /// In ru, this message translates to:
  /// **'{name} · Есть изменения'**
  String unsavedTab(Object name);

  /// No description provided for @depthDirection.
  ///
  /// In ru, this message translates to:
  /// **'{axis} · в глубину'**
  String depthDirection(Object axis);

  /// No description provided for @heightGesture.
  ///
  /// In ru, this message translates to:
  /// **'{mode} · ведите курсор вверх, чтобы задать высоту'**
  String heightGesture(Object mode);

  /// No description provided for @placeEndHint.
  ///
  /// In ru, this message translates to:
  /// **'{mode} · щёлкните, чтобы поставить конец детали'**
  String placeEndHint(Object mode);

  /// No description provided for @resizeLockHint.
  ///
  /// In ru, this message translates to:
  /// **'{action} размер · {dimension}'**
  String resizeLockHint(Object action, Object dimension);

  /// No description provided for @pieceCount.
  ///
  /// In ru, this message translates to:
  /// **'{count} шт.'**
  String pieceCount(Object count);

  /// No description provided for @partsFilename.
  ///
  /// In ru, this message translates to:
  /// **'{name} — список деталей'**
  String partsFilename(Object name);

  /// No description provided for @automatic.
  ///
  /// In ru, this message translates to:
  /// **'Авто'**
  String get automatic;

  /// No description provided for @autosave.
  ///
  /// In ru, this message translates to:
  /// **'Автосохранение'**
  String get autosave;

  /// No description provided for @axonometric.
  ///
  /// In ru, this message translates to:
  /// **'Аксонометрия'**
  String get axonometric;

  /// No description provided for @untitled.
  ///
  /// In ru, this message translates to:
  /// **'Без названия'**
  String get untitled;

  /// No description provided for @numberedUntitled.
  ///
  /// In ru, this message translates to:
  /// **'Без названия {number}'**
  String numberedUntitled(Object number);

  /// No description provided for @lock.
  ///
  /// In ru, this message translates to:
  /// **'Блокировать'**
  String get lock;

  /// No description provided for @partLocks.
  ///
  /// In ru, this message translates to:
  /// **'Блокировки деталей'**
  String get partLocks;

  /// No description provided for @side.
  ///
  /// In ru, this message translates to:
  /// **'Боковая'**
  String get side;

  /// No description provided for @inTheThicknessPlane.
  ///
  /// In ru, this message translates to:
  /// **'В плоскости толщины'**
  String get inTheThicknessPlane;

  /// No description provided for @inTheWidthPlane.
  ///
  /// In ru, this message translates to:
  /// **'В плоскости ширины'**
  String get inTheWidthPlane;

  /// No description provided for @thisProjectHasNoPartsYet.
  ///
  /// In ru, this message translates to:
  /// **'В проекте пока нет деталей'**
  String get thisProjectHasNoPartsYet;

  /// No description provided for @noStopInThisDirection.
  ///
  /// In ru, this message translates to:
  /// **'В этом направлении нет упора'**
  String get noStopInThisDirection;

  /// No description provided for @invalidInsideAngle.
  ///
  /// In ru, this message translates to:
  /// **'Введите внутренний угол между 0° и 180°'**
  String get invalidInsideAngle;

  /// No description provided for @positiveIntegerHint.
  ///
  /// In ru, this message translates to:
  /// **'Введите целое число от 1.'**
  String get positiveIntegerHint;

  /// No description provided for @up.
  ///
  /// In ru, this message translates to:
  /// **'Вверх'**
  String get up;

  /// No description provided for @vertical.
  ///
  /// In ru, this message translates to:
  /// **'Вертикаль'**
  String get vertical;

  /// No description provided for @cubeTop.
  ///
  /// In ru, this message translates to:
  /// **'Верх'**
  String get cubeTop;

  /// No description provided for @upper.
  ///
  /// In ru, this message translates to:
  /// **'Верхний'**
  String get upper;

  /// No description provided for @fixedDimensionsFillSpan.
  ///
  /// In ru, this message translates to:
  /// **'Весь габарит занят фиксированными размерами'**
  String get fixedDimensionsFillSpan;

  /// No description provided for @view.
  ///
  /// In ru, this message translates to:
  /// **'Вид'**
  String get view;

  /// No description provided for @views.
  ///
  /// In ru, this message translates to:
  /// **'Виды'**
  String get views;

  /// No description provided for @gridVisibility.
  ///
  /// In ru, this message translates to:
  /// **'Видимость сетки'**
  String get gridVisibility;

  /// No description provided for @left.
  ///
  /// In ru, this message translates to:
  /// **'Влево'**
  String get left;

  /// No description provided for @down.
  ///
  /// In ru, this message translates to:
  /// **'Вниз'**
  String get down;

  /// No description provided for @insideAngle.
  ///
  /// In ru, this message translates to:
  /// **'Внутренний угол'**
  String get insideAngle;

  /// No description provided for @fitToWindow.
  ///
  /// In ru, this message translates to:
  /// **'Вписать в окно'**
  String get fitToWindow;

  /// No description provided for @fitShortcut.
  ///
  /// In ru, this message translates to:
  /// **'Вписать в окно · {shortcut}'**
  String fitShortcut(Object shortcut);

  /// No description provided for @right.
  ///
  /// In ru, this message translates to:
  /// **'Вправо'**
  String get right;

  /// No description provided for @alwaysVisible.
  ///
  /// In ru, this message translates to:
  /// **'Всегда видны'**
  String get alwaysVisible;

  /// No description provided for @shortcutKeyHint.
  ///
  /// In ru, this message translates to:
  /// **'Выберите букву, цифру, стрелку или функциональную клавишу'**
  String get shortcutKeyHint;

  /// No description provided for @selectTheSecondShelf.
  ///
  /// In ru, this message translates to:
  /// **'Выберите вторую полку'**
  String get selectTheSecondShelf;

  /// No description provided for @selectWorkPlaneFace.
  ///
  /// In ru, this message translates to:
  /// **'Щёлкните по нужной поверхности детали на чертеже'**
  String get selectWorkPlaneFace;

  /// No description provided for @chooseParallelShelf.
  ///
  /// In ru, this message translates to:
  /// **'Выберите другую полку с общей проекцией и параллельной гранью'**
  String get chooseParallelShelf;

  /// No description provided for @chooseAlignmentHint.
  ///
  /// In ru, this message translates to:
  /// **'Укажите точки на двух деталях или задайте выравнивание в панели'**
  String get chooseAlignmentHint;

  /// No description provided for @chooseMovingAnchor.
  ///
  /// In ru, this message translates to:
  /// **'2 из 2. Укажите точку на перемещаемой детали.'**
  String get chooseMovingAnchor;

  /// No description provided for @selectAnAnchorOnThePart.
  ///
  /// In ru, this message translates to:
  /// **'Выберите опору на детали'**
  String get selectAnAnchorOnThePart;

  /// No description provided for @chooseAReference.
  ///
  /// In ru, this message translates to:
  /// **'Выберите опору…'**
  String get chooseAReference;

  /// No description provided for @selectTheFirstShelf.
  ///
  /// In ru, this message translates to:
  /// **'Выберите первую полку'**
  String get selectTheFirstShelf;

  /// No description provided for @selectParts.
  ///
  /// In ru, this message translates to:
  /// **'Выбор деталей'**
  String get selectParts;

  /// No description provided for @selectedParts.
  ///
  /// In ru, this message translates to:
  /// **'Выбрано деталей · {count}'**
  String selectedParts(Object count);

  /// No description provided for @selectShortcut.
  ///
  /// In ru, this message translates to:
  /// **'Выбрать · {shortcut}'**
  String selectShortcut(Object shortcut);

  /// No description provided for @selectAllParts.
  ///
  /// In ru, this message translates to:
  /// **'Выбрать все детали'**
  String get selectAllParts;

  /// No description provided for @chooseReferenceFromList.
  ///
  /// In ru, this message translates to:
  /// **'Выбрать опорную деталь из списка'**
  String get chooseReferenceFromList;

  /// No description provided for @alignment.
  ///
  /// In ru, this message translates to:
  /// **'Выравнивание'**
  String get alignment;

  /// No description provided for @alignToReference.
  ///
  /// In ru, this message translates to:
  /// **'Выровнять по опоре…'**
  String get alignToReference;

  /// No description provided for @overallSizeMustExceed.
  ///
  /// In ru, this message translates to:
  /// **'Габарит должен быть больше {size} {unit}'**
  String overallSizeMustExceed(Object size, Object unit);

  /// No description provided for @projectBounds.
  ///
  /// In ru, this message translates to:
  /// **'Габариты проекта'**
  String get projectBounds;

  /// No description provided for @assemblyDimensions.
  ///
  /// In ru, this message translates to:
  /// **'Габариты сборки'**
  String get assemblyDimensions;

  /// No description provided for @keyboardShortcuts.
  ///
  /// In ru, this message translates to:
  /// **'Горячие клавиши'**
  String get keyboardShortcuts;

  /// No description provided for @done.
  ///
  /// In ru, this message translates to:
  /// **'Готово'**
  String get done;

  /// No description provided for @resizeProducts.
  ///
  /// In ru, this message translates to:
  /// **'Изменить размеры изделий'**
  String get resizeProducts;

  /// No description provided for @face.
  ///
  /// In ru, this message translates to:
  /// **'Грань'**
  String get face;

  /// No description provided for @shelfFace.
  ///
  /// In ru, this message translates to:
  /// **'Грань полки'**
  String get shelfFace;

  /// No description provided for @numberedGroup.
  ///
  /// In ru, this message translates to:
  /// **'Группа {number}'**
  String numberedGroup(Object number);

  /// No description provided for @lengthInitial.
  ///
  /// In ru, this message translates to:
  /// **'Д'**
  String get lengthInitial;

  /// No description provided for @twoPoints.
  ///
  /// In ru, this message translates to:
  /// **'Две точки'**
  String get twoPoints;

  /// No description provided for @moveAndResizeInIncrements.
  ///
  /// In ru, this message translates to:
  /// **'Двигать и растягивать с шагом'**
  String get moveAndResizeInIncrements;

  /// No description provided for @partsTree.
  ///
  /// In ru, this message translates to:
  /// **'Дерево деталей'**
  String get partsTree;

  /// No description provided for @partCount.
  ///
  /// In ru, this message translates to:
  /// **'Деталей · {count}'**
  String partCount(Object count);

  /// No description provided for @partsLabel.
  ///
  /// In ru, this message translates to:
  /// **'Детали'**
  String get partsLabel;

  /// No description provided for @partsTabCount.
  ///
  /// In ru, this message translates to:
  /// **'Детали  {count}'**
  String partsTabCount(Object count);

  /// No description provided for @assemblyParts.
  ///
  /// In ru, this message translates to:
  /// **'Детали изделия'**
  String get assemblyParts;

  /// No description provided for @noMatchingParts.
  ///
  /// In ru, this message translates to:
  /// **'Детали не найдены'**
  String get noMatchingParts;

  /// No description provided for @part.
  ///
  /// In ru, this message translates to:
  /// **'Деталь'**
  String get part;

  /// No description provided for @numberedPart.
  ///
  /// In ru, this message translates to:
  /// **'Деталь {id}'**
  String numberedPart(Object id);

  /// No description provided for @thePartIntersectsItsReference.
  ///
  /// In ru, this message translates to:
  /// **'Деталь пересекает опору'**
  String get thePartIntersectsItsReference;

  /// No description provided for @alreadyTouchesReferences.
  ///
  /// In ru, this message translates to:
  /// **'Деталь уже касается обеих опор'**
  String get alreadyTouchesReferences;

  /// No description provided for @length.
  ///
  /// In ru, this message translates to:
  /// **'Длина'**
  String get length;

  /// No description provided for @stockLength.
  ///
  /// In ru, this message translates to:
  /// **'Длина заготовки'**
  String get stockLength;

  /// No description provided for @stockLengthInUnits.
  ///
  /// In ru, this message translates to:
  /// **'Длина заготовки, {unit}'**
  String stockLengthInUnits(Object unit);

  /// No description provided for @lengthTooShortForCuts.
  ///
  /// In ru, this message translates to:
  /// **'Длина меньше перепада запилов'**
  String get lengthTooShortForCuts;

  /// No description provided for @shortAndLongEdgeLengths.
  ///
  /// In ru, this message translates to:
  /// **'Длины короткой и длинной кромок, {unit}'**
  String shortAndLongEdgeLengths(Object unit);

  /// No description provided for @matchingSectionsRequired.
  ///
  /// In ru, this message translates to:
  /// **'Для симметричного стыка выберите одинаковые сечения'**
  String get matchingSectionsRequired;

  /// No description provided for @bothStops.
  ///
  /// In ru, this message translates to:
  /// **'До упора · {first} и {second}'**
  String bothStops(Object first, Object second);

  /// No description provided for @upToNextStop.
  ///
  /// In ru, this message translates to:
  /// **'До упора вверх'**
  String get upToNextStop;

  /// No description provided for @leftToNextStop.
  ///
  /// In ru, this message translates to:
  /// **'До упора влево'**
  String get leftToNextStop;

  /// No description provided for @downToNextStop.
  ///
  /// In ru, this message translates to:
  /// **'До упора вниз'**
  String get downToNextStop;

  /// No description provided for @rightToNextStop.
  ///
  /// In ru, this message translates to:
  /// **'До упора вправо'**
  String get rightToNextStop;

  /// No description provided for @addASecondPartToAlignThem.
  ///
  /// In ru, this message translates to:
  /// **'Добавьте вторую деталь для выравнивания'**
  String get addASecondPartToAlignThem;

  /// No description provided for @duplicate.
  ///
  /// In ru, this message translates to:
  /// **'Дублировать'**
  String get duplicate;

  /// No description provided for @inches.
  ///
  /// In ru, this message translates to:
  /// **'Дюймы'**
  String get inches;

  /// No description provided for @discardChangesWarning.
  ///
  /// In ru, this message translates to:
  /// **'Если закрыть проект «{name}», последние правки будут потеряны.'**
  String discardChangesWarning(Object name);

  /// No description provided for @stockPiece.
  ///
  /// In ru, this message translates to:
  /// **'Заготовка'**
  String get stockPiece;

  /// No description provided for @stockTooShort.
  ///
  /// In ru, this message translates to:
  /// **'Заготовка слишком короткая для этого запила'**
  String get stockTooShort;

  /// No description provided for @stock.
  ///
  /// In ru, this message translates to:
  /// **'Заготовки'**
  String get stock;

  /// No description provided for @cubeBack.
  ///
  /// In ru, this message translates to:
  /// **'Зад'**
  String get cubeBack;

  /// No description provided for @rear.
  ///
  /// In ru, this message translates to:
  /// **'Задний'**
  String get rear;

  /// No description provided for @backEdge.
  ///
  /// In ru, this message translates to:
  /// **'Задний край'**
  String get backEdge;

  /// No description provided for @gap.
  ///
  /// In ru, this message translates to:
  /// **'Зазор {distance} {unit}'**
  String gap(Object distance, Object unit);

  /// No description provided for @closeTab.
  ///
  /// In ru, this message translates to:
  /// **'Закрыть вкладку'**
  String get closeTab;

  /// No description provided for @closeProjectTab.
  ///
  /// In ru, this message translates to:
  /// **'Закрыть вкладку «{name}»'**
  String closeProjectTab(String name);

  /// No description provided for @closeGridSettings.
  ///
  /// In ru, this message translates to:
  /// **'Закрыть настройки сетки'**
  String get closeGridSettings;

  /// No description provided for @closePartDimensions.
  ///
  /// In ru, this message translates to:
  /// **'Закрыть размеры детали'**
  String get closePartDimensions;

  /// No description provided for @miterEndAngle.
  ///
  /// In ru, this message translates to:
  /// **'Запил каждого торца · {angle}° от прямого'**
  String miterEndAngle(Object angle);

  /// No description provided for @autosaveFilesHint.
  ///
  /// In ru, this message translates to:
  /// **'Изменения записываются в файлы открытых проектов. Новые проекты хранятся как локальные черновики.'**
  String get autosaveFilesHint;

  /// No description provided for @measureShortcut.
  ///
  /// In ru, this message translates to:
  /// **'Измерить · {shortcut}'**
  String measureShortcut(Object shortcut);

  /// No description provided for @measureDistance.
  ///
  /// In ru, this message translates to:
  /// **'Измерить расстояние'**
  String get measureDistance;

  /// No description provided for @tools.
  ///
  /// In ru, this message translates to:
  /// **'Инструменты'**
  String get tools;

  /// No description provided for @intervalMin.
  ///
  /// In ru, this message translates to:
  /// **'Интервал, мин'**
  String get intervalMin;

  /// No description provided for @excelWorkbook.
  ///
  /// In ru, this message translates to:
  /// **'Книга Excel'**
  String get excelWorkbook;

  /// No description provided for @qty.
  ///
  /// In ru, this message translates to:
  /// **'Кол-во'**
  String get qty;

  /// No description provided for @quantityPcs.
  ///
  /// In ru, this message translates to:
  /// **'Количество, шт.'**
  String get quantityPcs;

  /// No description provided for @endPoint.
  ///
  /// In ru, this message translates to:
  /// **'Конец'**
  String get endPoint;

  /// No description provided for @endCut.
  ///
  /// In ru, this message translates to:
  /// **'Конечный торец'**
  String get endCut;

  /// No description provided for @edges.
  ///
  /// In ru, this message translates to:
  /// **'Кромки · {lengths} {unit}'**
  String edges(Object lengths, Object unit);

  /// No description provided for @cubeLeft.
  ///
  /// In ru, this message translates to:
  /// **'Лево'**
  String get cubeLeft;

  /// No description provided for @leftHand.
  ///
  /// In ru, this message translates to:
  /// **'Левый'**
  String get leftHand;

  /// No description provided for @ruler.
  ///
  /// In ru, this message translates to:
  /// **'Линейка'**
  String get ruler;

  /// No description provided for @zoom.
  ///
  /// In ru, this message translates to:
  /// **'Масштаб'**
  String get zoom;

  /// No description provided for @actionsMenu.
  ///
  /// In ru, this message translates to:
  /// **'Меню действий'**
  String get actionsMenu;

  /// No description provided for @precision.
  ///
  /// In ru, this message translates to:
  /// **'Точность'**
  String get precision;

  /// No description provided for @anglePrecision.
  ///
  /// In ru, this message translates to:
  /// **'Точность углов'**
  String get anglePrecision;

  /// No description provided for @editingIncrement.
  ///
  /// In ru, this message translates to:
  /// **'Шаг редактирования'**
  String get editingIncrement;

  /// No description provided for @measurementUnits.
  ///
  /// In ru, this message translates to:
  /// **'Единицы измерения'**
  String get measurementUnits;

  /// No description provided for @millimeters.
  ///
  /// In ru, this message translates to:
  /// **'Миллиметры'**
  String get millimeters;

  /// No description provided for @onDrawing.
  ///
  /// In ru, this message translates to:
  /// **'На чертеже'**
  String get onDrawing;

  /// No description provided for @pressKeys.
  ///
  /// In ru, this message translates to:
  /// **'Нажмите клавиши…'**
  String get pressKeys;

  /// No description provided for @recordShortcutHint.
  ///
  /// In ru, this message translates to:
  /// **'Нажмите на сочетание и введите новое. Esc отменяет ввод.'**
  String get recordShortcutHint;

  /// No description provided for @rotationInputHint.
  ///
  /// In ru, this message translates to:
  /// **'Нажмите стрелку для поворота на 90° или введите угол'**
  String get rotationInputHint;

  /// No description provided for @partName.
  ///
  /// In ru, this message translates to:
  /// **'Название детали'**
  String get partName;

  /// No description provided for @groupName.
  ///
  /// In ru, this message translates to:
  /// **'Название группы'**
  String get groupName;

  /// No description provided for @nameAndDimensions.
  ///
  /// In ru, this message translates to:
  /// **'Название и размеры…'**
  String get nameAndDimensions;

  /// No description provided for @projectName.
  ///
  /// In ru, this message translates to:
  /// **'Название проекта'**
  String get projectName;

  /// No description provided for @assign.
  ///
  /// In ru, this message translates to:
  /// **'Назначить'**
  String get assign;

  /// No description provided for @searchMatches.
  ///
  /// In ru, this message translates to:
  /// **'Найдено {found} из {total}'**
  String searchMatches(Object found, Object total);

  /// No description provided for @findAPart.
  ///
  /// In ru, this message translates to:
  /// **'Найти деталь'**
  String get findAPart;

  /// No description provided for @tiltInAVerticalPlane.
  ///
  /// In ru, this message translates to:
  /// **'Наклон в вертикальной плоскости'**
  String get tiltInAVerticalPlane;

  /// No description provided for @direction.
  ///
  /// In ru, this message translates to:
  /// **'Направление'**
  String get direction;

  /// No description provided for @settings.
  ///
  /// In ru, this message translates to:
  /// **'Настройки'**
  String get settings;

  /// No description provided for @projectSettings.
  ///
  /// In ru, this message translates to:
  /// **'Настройки проекта'**
  String get projectSettings;

  /// No description provided for @projectSettingsMenu.
  ///
  /// In ru, this message translates to:
  /// **'Настройки проекта…'**
  String get projectSettingsMenu;

  /// No description provided for @start.
  ///
  /// In ru, this message translates to:
  /// **'Начало'**
  String get start;

  /// No description provided for @startCut.
  ///
  /// In ru, this message translates to:
  /// **'Начальный торец'**
  String get startCut;

  /// No description provided for @discardChanges.
  ///
  /// In ru, this message translates to:
  /// **'Не сохранять'**
  String get discardChanges;

  /// No description provided for @draftSaveError.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось записать черновик'**
  String get draftSaveError;

  /// No description provided for @updateProjectError.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось обновить файл. Используйте «Сохранить как…».'**
  String get updateProjectError;

  /// No description provided for @draftOpenError.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось открыть локальный черновик'**
  String get draftOpenError;

  /// No description provided for @openProjectError.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось открыть файл проекта'**
  String get openProjectError;

  /// No description provided for @gridSaveError.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось сохранить видимость сетки'**
  String get gridSaveError;

  /// No description provided for @settingsSaveError.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось сохранить настройки'**
  String get settingsSaveError;

  /// No description provided for @saveProjectError.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось сохранить проект. Используйте «Сохранить как…».'**
  String get saveProjectError;

  /// No description provided for @snapSaveError.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось сохранить режим привязки'**
  String get snapSaveError;

  /// No description provided for @workbookSaveError.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось сохранить файл Excel. Попробуйте ещё раз.'**
  String get workbookSaveError;

  /// No description provided for @unknownProjectFormat.
  ///
  /// In ru, this message translates to:
  /// **'Неизвестный формат проекта'**
  String get unknownProjectFormat;

  /// No description provided for @invalidPartGeometry.
  ///
  /// In ru, this message translates to:
  /// **'Некорректная геометрия детали'**
  String get invalidPartGeometry;

  /// No description provided for @invalidFace.
  ///
  /// In ru, this message translates to:
  /// **'Некорректная грань'**
  String get invalidFace;

  /// No description provided for @invalidVector.
  ///
  /// In ru, this message translates to:
  /// **'Некорректный вектор'**
  String get invalidVector;

  /// No description provided for @invalidWorkspaceDimensions.
  ///
  /// In ru, this message translates to:
  /// **'Некорректный размер рабочего пространства'**
  String get invalidWorkspaceDimensions;

  /// No description provided for @invalidEndCut.
  ///
  /// In ru, this message translates to:
  /// **'Некорректный торец'**
  String get invalidEndCut;

  /// No description provided for @invalidCorner.
  ///
  /// In ru, this message translates to:
  /// **'Некорректный угол'**
  String get invalidCorner;

  /// No description provided for @noOverlappingProjection.
  ///
  /// In ru, this message translates to:
  /// **'Нет общей проекции'**
  String get noOverlappingProjection;

  /// No description provided for @noOpenProjects.
  ///
  /// In ru, this message translates to:
  /// **'Нет открытых проектов'**
  String get noOpenProjects;

  /// No description provided for @lower.
  ///
  /// In ru, this message translates to:
  /// **'Нижний'**
  String get lower;

  /// No description provided for @cubeBottom.
  ///
  /// In ru, this message translates to:
  /// **'Низ'**
  String get cubeBottom;

  /// No description provided for @newPart.
  ///
  /// In ru, this message translates to:
  /// **'Новая деталь'**
  String get newPart;

  /// No description provided for @newDimension.
  ///
  /// In ru, this message translates to:
  /// **'Новый размер'**
  String get newDimension;

  /// No description provided for @centerCamera.
  ///
  /// In ru, this message translates to:
  /// **'Центрировать'**
  String get centerCamera;

  /// No description provided for @renameDimension.
  ///
  /// In ru, this message translates to:
  /// **'Переименовать размер'**
  String get renameDimension;

  /// No description provided for @selectDimensionHint.
  ///
  /// In ru, this message translates to:
  /// **'Выберите размер на чертеже или нажмите {shortcut}, чтобы добавить новый'**
  String selectDimensionHint(String shortcut);

  /// No description provided for @newPartWithDimensions.
  ///
  /// In ru, this message translates to:
  /// **'Новая деталь по размерам'**
  String get newPartWithDimensions;

  /// No description provided for @choosePartPosition.
  ///
  /// In ru, this message translates to:
  /// **'Выбрать место'**
  String get choosePartPosition;

  /// No description provided for @placePartHint.
  ///
  /// In ru, this message translates to:
  /// **'Щёлкните, чтобы поставить деталь. Esc — отменить.'**
  String get placePartHint;

  /// No description provided for @hiddenParts.
  ///
  /// In ru, this message translates to:
  /// **'Скрытые детали'**
  String get hiddenParts;

  /// No description provided for @hideCompletely.
  ///
  /// In ru, this message translates to:
  /// **'Полностью скрывать'**
  String get hideCompletely;

  /// No description provided for @showOutlines.
  ///
  /// In ru, this message translates to:
  /// **'Показать контуры'**
  String get showOutlines;

  /// No description provided for @hidePart.
  ///
  /// In ru, this message translates to:
  /// **'Скрыть деталь'**
  String get hidePart;

  /// No description provided for @hideGroupParts.
  ///
  /// In ru, this message translates to:
  /// **'Скрыть все детали группы'**
  String get hideGroupParts;

  /// No description provided for @showGroupParts.
  ///
  /// In ru, this message translates to:
  /// **'Показать все детали группы'**
  String get showGroupParts;

  /// No description provided for @hideSelectedParts.
  ///
  /// In ru, this message translates to:
  /// **'Скрыть выбранные детали'**
  String get hideSelectedParts;

  /// No description provided for @showPart.
  ///
  /// In ru, this message translates to:
  /// **'Показать деталь'**
  String get showPart;

  /// No description provided for @showAllParts.
  ///
  /// In ru, this message translates to:
  /// **'Показать все скрытые детали'**
  String get showAllParts;

  /// No description provided for @newPartShortcut.
  ///
  /// In ru, this message translates to:
  /// **'Новая деталь · {shortcut}'**
  String newPartShortcut(Object shortcut);

  /// No description provided for @newPartHere.
  ///
  /// In ru, this message translates to:
  /// **'Новая деталь здесь'**
  String get newPartHere;

  /// No description provided for @newProject.
  ///
  /// In ru, this message translates to:
  /// **'Новый проект'**
  String get newProject;

  /// No description provided for @leg.
  ///
  /// In ru, this message translates to:
  /// **'Ножка {number}'**
  String leg(Object number);

  /// No description provided for @referencesAreNeededOnBothSides.
  ///
  /// In ru, this message translates to:
  /// **'Нужны опоры с обеих сторон'**
  String get referencesAreNeededOnBothSides;

  /// No description provided for @reverseDirection.
  ///
  /// In ru, this message translates to:
  /// **'Обратить направление'**
  String get reverseDirection;

  /// No description provided for @anchor.
  ///
  /// In ru, this message translates to:
  /// **'Опора'**
  String get anchor;

  /// No description provided for @anchorLabel.
  ///
  /// In ru, this message translates to:
  /// **'Опора · {mode}'**
  String anchorLabel(Object mode);

  /// No description provided for @referencePart.
  ///
  /// In ru, this message translates to:
  /// **'Опорная деталь'**
  String get referencePart;

  /// No description provided for @partAxes.
  ///
  /// In ru, this message translates to:
  /// **'Оси детали'**
  String get partAxes;

  /// No description provided for @projectAxes.
  ///
  /// In ru, this message translates to:
  /// **'Оси проекта'**
  String get projectAxes;

  /// No description provided for @axis.
  ///
  /// In ru, this message translates to:
  /// **'Ось {axis}'**
  String axis(Object axis);

  /// No description provided for @zoomOut.
  ///
  /// In ru, this message translates to:
  /// **'Отдалить'**
  String get zoomOut;

  /// No description provided for @open.
  ///
  /// In ru, this message translates to:
  /// **'Открыть'**
  String get open;

  /// No description provided for @newTab.
  ///
  /// In ru, this message translates to:
  /// **'Новая вкладка'**
  String get newTab;

  /// No description provided for @recentProjects.
  ///
  /// In ru, this message translates to:
  /// **'Недавние проекты'**
  String get recentProjects;

  /// No description provided for @noRecentProjects.
  ///
  /// In ru, this message translates to:
  /// **'Пока нет недавних проектов'**
  String get noRecentProjects;

  /// No description provided for @openProject.
  ///
  /// In ru, this message translates to:
  /// **'Открыть проект'**
  String get openProject;

  /// No description provided for @openProjectMenu.
  ///
  /// In ru, this message translates to:
  /// **'Открыть проект…'**
  String get openProjectMenu;

  /// No description provided for @cancel.
  ///
  /// In ru, this message translates to:
  /// **'Отмена'**
  String get cancel;

  /// No description provided for @undo.
  ///
  /// In ru, this message translates to:
  /// **'Отменить'**
  String get undo;

  /// No description provided for @undoAction.
  ///
  /// In ru, this message translates to:
  /// **'Отменить действие'**
  String get undoAction;

  /// No description provided for @offset.
  ///
  /// In ru, this message translates to:
  /// **'Отступ'**
  String get offset;

  /// No description provided for @referenceEdgeOffset.
  ///
  /// In ru, this message translates to:
  /// **'Отступ от {edge} опоры'**
  String referenceEdgeOffset(Object edge);

  /// No description provided for @clearSearch.
  ///
  /// In ru, this message translates to:
  /// **'Очистить поиск'**
  String get clearSearch;

  /// No description provided for @rightClick.
  ///
  /// In ru, this message translates to:
  /// **'ПКМ'**
  String get rightClick;

  /// No description provided for @moveResizeHint.
  ///
  /// In ru, this message translates to:
  /// **'Перетащите деталь, чтобы переместить её. Shift + перетаскивание края меняет размер.'**
  String get moveResizeHint;

  /// No description provided for @cubeFront.
  ///
  /// In ru, this message translates to:
  /// **'Перед'**
  String get cubeFront;

  /// No description provided for @frontFacing.
  ///
  /// In ru, this message translates to:
  /// **'Передний'**
  String get frontFacing;

  /// No description provided for @frontEdge.
  ///
  /// In ru, this message translates to:
  /// **'Передний край'**
  String get frontEdge;

  /// No description provided for @renamePart.
  ///
  /// In ru, this message translates to:
  /// **'Переименовать деталь'**
  String get renamePart;

  /// No description provided for @renameGroup.
  ///
  /// In ru, this message translates to:
  /// **'Переименовать группу'**
  String get renameGroup;

  /// No description provided for @rename.
  ///
  /// In ru, this message translates to:
  /// **'Переименовать…'**
  String get rename;

  /// No description provided for @moveShortcut.
  ///
  /// In ru, this message translates to:
  /// **'Переместить · {shortcut}'**
  String moveShortcut(Object shortcut);

  /// No description provided for @anchorShortcut.
  ///
  /// In ru, this message translates to:
  /// **'Поставить по опоре · {shortcut}'**
  String anchorShortcut(Object shortcut);

  /// No description provided for @movementAndRuler.
  ///
  /// In ru, this message translates to:
  /// **'Перемещение и линейка'**
  String get movementAndRuler;

  /// No description provided for @movementAndResizing.
  ///
  /// In ru, this message translates to:
  /// **'Перемещение и растягивание'**
  String get movementAndResizing;

  /// No description provided for @intersection.
  ///
  /// In ru, this message translates to:
  /// **'Пересечение'**
  String get intersection;

  /// No description provided for @intersections.
  ///
  /// In ru, this message translates to:
  /// **'Пересечения'**
  String get intersections;

  /// No description provided for @intersectionsLabel.
  ///
  /// In ru, this message translates to:
  /// **'Пересечения · {count}'**
  String intersectionsLabel(Object count);

  /// No description provided for @perspective.
  ///
  /// In ru, this message translates to:
  /// **'Перспектива'**
  String get perspective;

  /// No description provided for @seatSlat.
  ///
  /// In ru, this message translates to:
  /// **'Планка сиденья {number}'**
  String seatSlat(Object number);

  /// No description provided for @plane.
  ///
  /// In ru, this message translates to:
  /// **'Плоскость'**
  String get plane;

  /// No description provided for @buildInThisPlane.
  ///
  /// In ru, this message translates to:
  /// **'Строить в этой плоскости'**
  String get buildInThisPlane;

  /// No description provided for @edgeAligned.
  ///
  /// In ru, this message translates to:
  /// **'По краю'**
  String get edgeAligned;

  /// No description provided for @byAxes.
  ///
  /// In ru, this message translates to:
  /// **'По осям'**
  String get byAxes;

  /// No description provided for @alongThickness.
  ///
  /// In ru, this message translates to:
  /// **'По толщине'**
  String get alongThickness;

  /// No description provided for @alongWidth.
  ///
  /// In ru, this message translates to:
  /// **'По ширине'**
  String get alongWidth;

  /// No description provided for @rotate.
  ///
  /// In ru, this message translates to:
  /// **'Повернуть'**
  String get rotate;

  /// No description provided for @orbitView.
  ///
  /// In ru, this message translates to:
  /// **'Повернуть вид'**
  String get orbitView;

  /// No description provided for @rotatePart.
  ///
  /// In ru, this message translates to:
  /// **'Повернуть деталь'**
  String get rotatePart;

  /// No description provided for @rotateMenu.
  ///
  /// In ru, this message translates to:
  /// **'Повернуть…'**
  String get rotateMenu;

  /// No description provided for @rotation.
  ///
  /// In ru, this message translates to:
  /// **'Поворот'**
  String get rotation;

  /// No description provided for @rotateShortcut.
  ///
  /// In ru, this message translates to:
  /// **'Поворот · {shortcut}'**
  String rotateShortcut(Object shortcut);

  /// No description provided for @brokenPartReferences.
  ///
  /// In ru, this message translates to:
  /// **'Повреждённые ссылки на детали'**
  String get brokenPartReferences;

  /// No description provided for @redo.
  ///
  /// In ru, this message translates to:
  /// **'Повторить'**
  String get redo;

  /// No description provided for @redoAction.
  ///
  /// In ru, this message translates to:
  /// **'Повторить действие'**
  String get redoAction;

  /// No description provided for @showHideDimensions.
  ///
  /// In ru, this message translates to:
  /// **'Показать / скрыть размеры'**
  String get showHideDimensions;

  /// No description provided for @showDimensions.
  ///
  /// In ru, this message translates to:
  /// **'Показать размеры'**
  String get showDimensions;

  /// No description provided for @floor.
  ///
  /// In ru, this message translates to:
  /// **'Пол'**
  String get floor;

  /// No description provided for @partOffsets.
  ///
  /// In ru, this message translates to:
  /// **'Отступы'**
  String get partOffsets;

  /// No description provided for @xFromLeft.
  ///
  /// In ru, this message translates to:
  /// **'X · слева'**
  String get xFromLeft;

  /// No description provided for @yFromBack.
  ///
  /// In ru, this message translates to:
  /// **'Y · от стенки'**
  String get yFromBack;

  /// No description provided for @zFromFloor.
  ///
  /// In ru, this message translates to:
  /// **'Z · от пола'**
  String get zFromFloor;

  /// No description provided for @crossRail.
  ///
  /// In ru, this message translates to:
  /// **'Поперечная царга {number}'**
  String crossRail(Object number);

  /// No description provided for @placeAgainstReference.
  ///
  /// In ru, this message translates to:
  /// **'Поставить по опоре'**
  String get placeAgainstReference;

  /// No description provided for @cubeRight.
  ///
  /// In ru, this message translates to:
  /// **'Право'**
  String get cubeRight;

  /// No description provided for @rightHand.
  ///
  /// In ru, this message translates to:
  /// **'Правый'**
  String get rightHand;

  /// No description provided for @multiSelectionMenuHint.
  ///
  /// In ru, this message translates to:
  /// **'Правый щелчок по выделению — действия со всеми выбранными деталями'**
  String get multiSelectionMenuHint;

  /// No description provided for @continuousDragHint.
  ///
  /// In ru, this message translates to:
  /// **'При перетаскивании положение и длина меняются плавно.'**
  String get continuousDragHint;

  /// No description provided for @zoomIn.
  ///
  /// In ru, this message translates to:
  /// **'Приблизить'**
  String get zoomIn;

  /// No description provided for @rulerSnapModifier.
  ///
  /// In ru, this message translates to:
  /// **'Привязка линейки без {modifier}'**
  String rulerSnapModifier(Object modifier);

  /// No description provided for @snapLabel.
  ///
  /// In ru, this message translates to:
  /// **'Привязка'**
  String get snapLabel;

  /// No description provided for @snapToAnchors.
  ///
  /// In ru, this message translates to:
  /// **'Привязка по опорам'**
  String get snapToAnchors;

  /// No description provided for @apply.
  ///
  /// In ru, this message translates to:
  /// **'Применить'**
  String get apply;

  /// No description provided for @spaceLeftClick.
  ///
  /// In ru, this message translates to:
  /// **'Пробел + ЛКМ'**
  String get spaceLeftClick;

  /// No description provided for @checkTheExpression.
  ///
  /// In ru, this message translates to:
  /// **'Проверьте выражение'**
  String get checkTheExpression;

  /// No description provided for @sideRail.
  ///
  /// In ru, this message translates to:
  /// **'Продольная царга {number}'**
  String sideRail(Object number);

  /// No description provided for @project.
  ///
  /// In ru, this message translates to:
  /// **'Проект'**
  String get project;

  /// No description provided for @neprostoProject.
  ///
  /// In ru, this message translates to:
  /// **'Проект NeProSto'**
  String get neprostoProject;

  /// No description provided for @projectSaved.
  ///
  /// In ru, this message translates to:
  /// **'Проект сохранён'**
  String get projectSaved;

  /// No description provided for @clearance.
  ///
  /// In ru, this message translates to:
  /// **'Просвет'**
  String get clearance;

  /// No description provided for @clearanceLabel.
  ///
  /// In ru, this message translates to:
  /// **'Просвет · {distance} {unit}'**
  String clearanceLabel(Object distance, Object unit);

  /// No description provided for @square.
  ///
  /// In ru, this message translates to:
  /// **'Прямые'**
  String get square;

  /// No description provided for @drawingControls.
  ///
  /// In ru, this message translates to:
  /// **'Работа с чертежом'**
  String get drawingControls;

  /// No description provided for @workPlane.
  ///
  /// In ru, this message translates to:
  /// **'Рабочая плоскость'**
  String get workPlane;

  /// No description provided for @workPlaneLabel.
  ///
  /// In ru, this message translates to:
  /// **'Рабочая плоскость · {plane}'**
  String workPlaneLabel(Object plane);

  /// No description provided for @equalGapValue.
  ///
  /// In ru, this message translates to:
  /// **'Равные зазоры · {distance} {unit}'**
  String equalGapValue(Object distance, Object unit);

  /// No description provided for @unlock.
  ///
  /// In ru, this message translates to:
  /// **'Разблокировать'**
  String get unlock;

  /// No description provided for @ungroup.
  ///
  /// In ru, this message translates to:
  /// **'Разгруппировать'**
  String get ungroup;

  /// No description provided for @dimension.
  ///
  /// In ru, this message translates to:
  /// **'Размер'**
  String get dimension;

  /// No description provided for @dimensionLocked.
  ///
  /// In ru, this message translates to:
  /// **'Размер заблокирован'**
  String get dimensionLocked;

  /// No description provided for @dimensionTabCount.
  ///
  /// In ru, this message translates to:
  /// **'Размеры  {count}'**
  String dimensionTabCount(Object count);

  /// No description provided for @partDimensions.
  ///
  /// In ru, this message translates to:
  /// **'Размеры детали'**
  String get partDimensions;

  /// No description provided for @dimensionsOnDrawing.
  ///
  /// In ru, this message translates to:
  /// **'Размеры на чертеже'**
  String get dimensionsOnDrawing;

  /// No description provided for @endMarkings.
  ///
  /// In ru, this message translates to:
  /// **'Разметка торцов'**
  String get endMarkings;

  /// No description provided for @stretchToHeight.
  ///
  /// In ru, this message translates to:
  /// **'Растянуть по высоте'**
  String get stretchToHeight;

  /// No description provided for @stretchToWidth.
  ///
  /// In ru, this message translates to:
  /// **'Растянуть по ширине'**
  String get stretchToWidth;

  /// No description provided for @editing.
  ///
  /// In ru, this message translates to:
  /// **'Редактирование'**
  String get editing;

  /// No description provided for @modeWithoutModifierKeys.
  ///
  /// In ru, this message translates to:
  /// **'Режим без нажатых клавиш'**
  String get modeWithoutModifierKeys;

  /// No description provided for @snapping.
  ///
  /// In ru, this message translates to:
  /// **'С привязкой'**
  String get snapping;

  /// No description provided for @centimeters.
  ///
  /// In ru, this message translates to:
  /// **'Сантиметры'**
  String get centimeters;

  /// No description provided for @resetShortcuts.
  ///
  /// In ru, this message translates to:
  /// **'Сбросить сочетания'**
  String get resetShortcuts;

  /// No description provided for @viewTop.
  ///
  /// In ru, this message translates to:
  /// **'Сверху'**
  String get viewTop;

  /// No description provided for @free.
  ///
  /// In ru, this message translates to:
  /// **'Свободно'**
  String get free;

  /// No description provided for @freeView.
  ///
  /// In ru, this message translates to:
  /// **'Свободный вид'**
  String get freeView;

  /// No description provided for @properties.
  ///
  /// In ru, this message translates to:
  /// **'Свойства'**
  String get properties;

  /// No description provided for @groupLabel.
  ///
  /// In ru, this message translates to:
  /// **'Сгруппировать'**
  String get groupLabel;

  /// No description provided for @nudge.
  ///
  /// In ru, this message translates to:
  /// **'Сдвиг'**
  String get nudge;

  /// No description provided for @nudgeDistance.
  ///
  /// In ru, this message translates to:
  /// **'Сдвиг · {distance} {unit}'**
  String nudgeDistance(Object distance, Object unit);

  /// No description provided for @panView.
  ///
  /// In ru, this message translates to:
  /// **'Сдвинуть вид'**
  String get panView;

  /// No description provided for @center.
  ///
  /// In ru, this message translates to:
  /// **'Середина'**
  String get center;

  /// No description provided for @edgeMidpoint.
  ///
  /// In ru, this message translates to:
  /// **'Середина ребра'**
  String get edgeMidpoint;

  /// No description provided for @rulerEdge.
  ///
  /// In ru, this message translates to:
  /// **'Ребро'**
  String get rulerEdge;

  /// No description provided for @rulerUpperEdge.
  ///
  /// In ru, this message translates to:
  /// **'Верхнее ребро'**
  String get rulerUpperEdge;

  /// No description provided for @rulerLowerEdge.
  ///
  /// In ru, this message translates to:
  /// **'Нижнее ребро'**
  String get rulerLowerEdge;

  /// No description provided for @rulerCenterline.
  ///
  /// In ru, this message translates to:
  /// **'Средняя линия грани'**
  String get rulerCenterline;

  /// No description provided for @viewBack.
  ///
  /// In ru, this message translates to:
  /// **'Сзади'**
  String get viewBack;

  /// No description provided for @bench.
  ///
  /// In ru, this message translates to:
  /// **'Скамья'**
  String get bench;

  /// No description provided for @downloadStarted.
  ///
  /// In ru, this message translates to:
  /// **'Скачивание началось'**
  String get downloadStarted;

  /// No description provided for @hideDimensions.
  ///
  /// In ru, this message translates to:
  /// **'Скрыть размеры'**
  String get hideDimensions;

  /// No description provided for @viewLeft.
  ///
  /// In ru, this message translates to:
  /// **'Слева'**
  String get viewLeft;

  /// No description provided for @partDimensionIsTooSmall.
  ///
  /// In ru, this message translates to:
  /// **'Слишком маленький размер детали'**
  String get partDimensionIsTooSmall;

  /// No description provided for @changeShortcutFor.
  ///
  /// In ru, this message translates to:
  /// **'Сменить сочетание для «{command}»'**
  String changeShortcutFor(Object command);

  /// No description provided for @viewBottom.
  ///
  /// In ru, this message translates to:
  /// **'Снизу'**
  String get viewBottom;

  /// No description provided for @join.
  ///
  /// In ru, this message translates to:
  /// **'Соединить'**
  String get join;

  /// No description provided for @saving.
  ///
  /// In ru, this message translates to:
  /// **'Сохранение'**
  String get saving;

  /// No description provided for @save.
  ///
  /// In ru, this message translates to:
  /// **'Сохранить'**
  String get save;

  /// No description provided for @saveChanges.
  ///
  /// In ru, this message translates to:
  /// **'Сохранить изменения?'**
  String get saveChanges;

  /// No description provided for @saveAs.
  ///
  /// In ru, this message translates to:
  /// **'Сохранить как…'**
  String get saveAs;

  /// No description provided for @saveProject.
  ///
  /// In ru, this message translates to:
  /// **'Сохранить проект'**
  String get saveProject;

  /// No description provided for @saveProjectsAutomatically.
  ///
  /// In ru, this message translates to:
  /// **'Сохранять проекты автоматически'**
  String get saveProjectsAutomatically;

  /// No description provided for @viewFront.
  ///
  /// In ru, this message translates to:
  /// **'Спереди'**
  String get viewFront;

  /// No description provided for @partsList.
  ///
  /// In ru, this message translates to:
  /// **'Список деталей'**
  String get partsList;

  /// No description provided for @viewRight.
  ///
  /// In ru, this message translates to:
  /// **'Справа'**
  String get viewRight;

  /// No description provided for @stepExample.
  ///
  /// In ru, this message translates to:
  /// **'Стрелка сдвигает деталь на {step} {unit}. При растягивании длина меняется шагами, например {examples} {exampleUnit}.'**
  String stepExample(
    Object step,
    Object unit,
    Object examples,
    Object exampleUnit,
  );

  /// No description provided for @straightUpAlongZ.
  ///
  /// In ru, this message translates to:
  /// **'Строго вверх по Z'**
  String get straightUpAlongZ;

  /// No description provided for @thicknessInitial.
  ///
  /// In ru, this message translates to:
  /// **'Т'**
  String get thicknessInitial;

  /// No description provided for @thickness.
  ///
  /// In ru, this message translates to:
  /// **'Толщина'**
  String get thickness;

  /// No description provided for @thicknessLabel.
  ///
  /// In ru, this message translates to:
  /// **'Толщина, {unit}'**
  String thicknessLabel(Object unit);

  /// No description provided for @onlyWith.
  ///
  /// In ru, this message translates to:
  /// **'Только с {modifier}'**
  String onlyWith(Object modifier);

  /// No description provided for @ends.
  ///
  /// In ru, this message translates to:
  /// **'Торцы'**
  String get ends;

  /// No description provided for @dragWithRightButton.
  ///
  /// In ru, this message translates to:
  /// **'Тянуть ПКМ'**
  String get dragWithRightButton;

  /// No description provided for @removeBounds.
  ///
  /// In ru, this message translates to:
  /// **'Убрать границы'**
  String get removeBounds;

  /// No description provided for @miterJoint.
  ///
  /// In ru, this message translates to:
  /// **'Угловой стык'**
  String get miterJoint;

  /// No description provided for @miterJointMenu.
  ///
  /// In ru, this message translates to:
  /// **'Угловой стык…'**
  String get miterJointMenu;

  /// No description provided for @jointEndToEnd.
  ///
  /// In ru, this message translates to:
  /// **'Торец к торцу'**
  String get jointEndToEnd;

  /// No description provided for @jointEndToFace.
  ///
  /// In ru, this message translates to:
  /// **'Торец к грани'**
  String get jointEndToFace;

  /// No description provided for @jointChooseFace.
  ///
  /// In ru, this message translates to:
  /// **'Выбрать грань'**
  String get jointChooseFace;

  /// No description provided for @jointBottomFace.
  ///
  /// In ru, this message translates to:
  /// **'Нижняя грань'**
  String get jointBottomFace;

  /// No description provided for @jointTopFace.
  ///
  /// In ru, this message translates to:
  /// **'Верхняя грань'**
  String get jointTopFace;

  /// No description provided for @jointCutLine.
  ///
  /// In ru, this message translates to:
  /// **'Линия реза'**
  String get jointCutLine;

  /// No description provided for @jointOffcut.
  ///
  /// In ru, this message translates to:
  /// **'Обрезок'**
  String get jointOffcut;

  /// No description provided for @jointApplyCut.
  ///
  /// In ru, this message translates to:
  /// **'Подрезать'**
  String get jointApplyCut;

  /// No description provided for @jointNoCommonCut.
  ///
  /// In ru, this message translates to:
  /// **'Выбранные торцы не сходятся по одной плоскости. Проверьте торцы и положение деталей.'**
  String get jointNoCommonCut;

  /// No description provided for @jointCutOutsideStock.
  ///
  /// In ru, this message translates to:
  /// **'Линия реза выходит за торец заготовки. Проверьте нахлёст деталей.'**
  String get jointCutOutsideStock;

  /// No description provided for @jointNoFaceCut.
  ///
  /// In ru, this message translates to:
  /// **'На опоре нет грани для сквозного запила выбранной детали. Проверьте положение деталей.'**
  String get jointNoFaceCut;

  /// No description provided for @corner.
  ///
  /// In ru, this message translates to:
  /// **'Угол'**
  String get corner;

  /// No description provided for @delete.
  ///
  /// In ru, this message translates to:
  /// **'Удалить'**
  String get delete;

  /// No description provided for @deleteDimension.
  ///
  /// In ru, this message translates to:
  /// **'Удалить размер'**
  String get deleteDimension;

  /// No description provided for @holdToSnap.
  ///
  /// In ru, this message translates to:
  /// **'Удерживайте {modifier} для привязки.'**
  String holdToSnap(Object modifier);

  /// No description provided for @freeMovementHint.
  ///
  /// In ru, this message translates to:
  /// **'Удерживайте {modifier}, чтобы временно отключить привязку.'**
  String freeMovementHint(Object modifier);

  /// No description provided for @holdDimensionModifier.
  ///
  /// In ru, this message translates to:
  /// **'Удерживайте {modifier}, чтобы {action} размеры.'**
  String holdDimensionModifier(Object modifier, Object action);

  /// No description provided for @hold.
  ///
  /// In ru, this message translates to:
  /// **'Удерживать {modifier}'**
  String hold(Object modifier);

  /// No description provided for @alreadyAssignedTo.
  ///
  /// In ru, this message translates to:
  /// **'Уже назначено для «{command}»'**
  String alreadyAssignedTo(Object command);

  /// No description provided for @setTheSecondDimensionPoint.
  ///
  /// In ru, this message translates to:
  /// **'Укажите вторую точку размера'**
  String get setTheSecondDimensionPoint;

  /// No description provided for @setTheSourceAnchorOnThePart.
  ///
  /// In ru, this message translates to:
  /// **'1 из 2. Щёлкните по исходной точке на перемещаемой детали.'**
  String get setTheSourceAnchorOnThePart;

  /// No description provided for @setTheEndOfThePart.
  ///
  /// In ru, this message translates to:
  /// **'Укажите конец детали'**
  String get setTheEndOfThePart;

  /// No description provided for @setTheStartOfThePart.
  ///
  /// In ru, this message translates to:
  /// **'Укажите начальную точку детали'**
  String get setTheStartOfThePart;

  /// No description provided for @setTheDestinationAnchor.
  ///
  /// In ru, this message translates to:
  /// **'2 из 2. Щёлкните там, куда нужно переместить эту точку.'**
  String get setTheDestinationAnchor;

  /// No description provided for @setTheFirstDimensionPoint.
  ///
  /// In ru, this message translates to:
  /// **'Укажите первую точку размера'**
  String get setTheFirstDimensionPoint;

  /// No description provided for @pickReferenceOnDrawing.
  ///
  /// In ru, this message translates to:
  /// **'Указать опору на чертеже'**
  String get pickReferenceOnDrawing;

  /// No description provided for @stop.
  ///
  /// In ru, this message translates to:
  /// **'Упор · {part}'**
  String stop(Object part);

  /// No description provided for @excelFileSaved.
  ///
  /// In ru, this message translates to:
  /// **'Файл Excel сохранён'**
  String get excelFileSaved;

  /// No description provided for @frontPlane.
  ///
  /// In ru, this message translates to:
  /// **'Фронтальная'**
  String get frontPlane;

  /// No description provided for @rearPlane.
  ///
  /// In ru, this message translates to:
  /// **'Задняя'**
  String get rearPlane;

  /// No description provided for @centerPoint.
  ///
  /// In ru, this message translates to:
  /// **'Центр'**
  String get centerPoint;

  /// No description provided for @faceCenter.
  ///
  /// In ru, this message translates to:
  /// **'Центр грани'**
  String get faceCenter;

  /// No description provided for @partCenter.
  ///
  /// In ru, this message translates to:
  /// **'Центр детали'**
  String get partCenter;

  /// No description provided for @brusDrafts.
  ///
  /// In ru, this message translates to:
  /// **'Черновики Брус'**
  String get brusDrafts;

  /// No description provided for @browserDraftsHint.
  ///
  /// In ru, this message translates to:
  /// **'Черновики открытых вкладок сохраняются в этом браузере.'**
  String get browserDraftsHint;

  /// No description provided for @drawing.
  ///
  /// In ru, this message translates to:
  /// **'Чертёж'**
  String get drawing;

  /// No description provided for @addPartHint.
  ///
  /// In ru, this message translates to:
  /// **'Нажмите {shortcut}, чтобы добавить деталь'**
  String addPartHint(Object shortcut);

  /// No description provided for @widthInitial.
  ///
  /// In ru, this message translates to:
  /// **'Ш'**
  String get widthInitial;

  /// No description provided for @step.
  ///
  /// In ru, this message translates to:
  /// **'Шаг {increment}'**
  String step(Object increment);

  /// No description provided for @width.
  ///
  /// In ru, this message translates to:
  /// **'Ширина'**
  String get width;

  /// No description provided for @widthLabel.
  ///
  /// In ru, this message translates to:
  /// **'Ширина, {unit}'**
  String widthLabel(Object unit);

  /// No description provided for @clickAReferenceInTheDrawingOr.
  ///
  /// In ru, this message translates to:
  /// **'Щёлкните по опоре на чертеже или выберите её из списка.'**
  String get clickAReferenceInTheDrawingOr;

  /// No description provided for @clickTheReferencePart.
  ///
  /// In ru, this message translates to:
  /// **'Щёлкните по опорной детали'**
  String get clickTheReferencePart;

  /// No description provided for @exportToExcel.
  ///
  /// In ru, this message translates to:
  /// **'Экспорт в Excel'**
  String get exportToExcel;

  /// No description provided for @reservedShortcut.
  ///
  /// In ru, this message translates to:
  /// **'Это системное сочетание. Выберите другое.'**
  String get reservedShortcut;

  /// No description provided for @fileAlreadyOpen.
  ///
  /// In ru, this message translates to:
  /// **'Этот файл открыт в другой вкладке'**
  String get fileAlreadyOpen;

  /// No description provided for @off.
  ///
  /// In ru, this message translates to:
  /// **'выкл.'**
  String get off;

  /// No description provided for @leftReferenceEdge.
  ///
  /// In ru, this message translates to:
  /// **'левого края'**
  String get leftReferenceEdge;

  /// No description provided for @mm.
  ///
  /// In ru, this message translates to:
  /// **'мм'**
  String get mm;

  /// No description provided for @bottomReferenceEdge.
  ///
  /// In ru, this message translates to:
  /// **'нижнего края'**
  String get bottomReferenceEdge;

  /// No description provided for @frontReferenceEdge.
  ///
  /// In ru, this message translates to:
  /// **'переднего края'**
  String get frontReferenceEdge;

  /// No description provided for @show.
  ///
  /// In ru, this message translates to:
  /// **'показать'**
  String get show;

  /// No description provided for @hide.
  ///
  /// In ru, this message translates to:
  /// **'скрыть'**
  String get hide;

  /// No description provided for @cm.
  ///
  /// In ru, this message translates to:
  /// **'см'**
  String get cm;

  /// No description provided for @negativeThickness.
  ///
  /// In ru, this message translates to:
  /// **'−Т'**
  String get negativeThickness;

  /// No description provided for @negativeWidth.
  ///
  /// In ru, this message translates to:
  /// **'−Ш'**
  String get negativeWidth;

  /// No description provided for @close.
  ///
  /// In ru, this message translates to:
  /// **'Закрыть'**
  String get close;

  /// No description provided for @appearance.
  ///
  /// In ru, this message translates to:
  /// **'Оформление'**
  String get appearance;

  /// No description provided for @theme.
  ///
  /// In ru, this message translates to:
  /// **'Тема'**
  String get theme;

  /// No description provided for @light.
  ///
  /// In ru, this message translates to:
  /// **'Светлая'**
  String get light;

  /// No description provided for @dark.
  ///
  /// In ru, this message translates to:
  /// **'Тёмная'**
  String get dark;

  /// No description provided for @language.
  ///
  /// In ru, this message translates to:
  /// **'Язык'**
  String get language;

  /// No description provided for @aboutNeprosto.
  ///
  /// In ru, this message translates to:
  /// **'О NeProSto'**
  String get aboutNeprosto;

  /// No description provided for @fileMenu.
  ///
  /// In ru, this message translates to:
  /// **'Файл'**
  String get fileMenu;

  /// No description provided for @settingsMenu.
  ///
  /// In ru, this message translates to:
  /// **'Настройки…'**
  String get settingsMenu;

  /// No description provided for @services.
  ///
  /// In ru, this message translates to:
  /// **'Службы'**
  String get services;

  /// No description provided for @hideNeprosto.
  ///
  /// In ru, this message translates to:
  /// **'Скрыть NeProSto'**
  String get hideNeprosto;

  /// No description provided for @hideOthers.
  ///
  /// In ru, this message translates to:
  /// **'Скрыть остальные'**
  String get hideOthers;

  /// No description provided for @showAll.
  ///
  /// In ru, this message translates to:
  /// **'Показать все'**
  String get showAll;

  /// No description provided for @quitNeprosto.
  ///
  /// In ru, this message translates to:
  /// **'Завершить NeProSto'**
  String get quitNeprosto;

  /// No description provided for @edit.
  ///
  /// In ru, this message translates to:
  /// **'Правка'**
  String get edit;

  /// No description provided for @cut.
  ///
  /// In ru, this message translates to:
  /// **'Вырезать'**
  String get cut;

  /// No description provided for @copy.
  ///
  /// In ru, this message translates to:
  /// **'Копировать'**
  String get copy;

  /// No description provided for @paste.
  ///
  /// In ru, this message translates to:
  /// **'Вставить'**
  String get paste;

  /// No description provided for @pasteAndMatchStyle.
  ///
  /// In ru, this message translates to:
  /// **'Вставить в текущем стиле'**
  String get pasteAndMatchStyle;

  /// No description provided for @selectAll.
  ///
  /// In ru, this message translates to:
  /// **'Выбрать все'**
  String get selectAll;

  /// No description provided for @find.
  ///
  /// In ru, this message translates to:
  /// **'Найти'**
  String get find;

  /// No description provided for @findMenu.
  ///
  /// In ru, this message translates to:
  /// **'Найти…'**
  String get findMenu;

  /// No description provided for @findAndReplace.
  ///
  /// In ru, this message translates to:
  /// **'Найти и заменить…'**
  String get findAndReplace;

  /// No description provided for @findNext.
  ///
  /// In ru, this message translates to:
  /// **'Найти далее'**
  String get findNext;

  /// No description provided for @findPrevious.
  ///
  /// In ru, this message translates to:
  /// **'Найти предыдущее'**
  String get findPrevious;

  /// No description provided for @useSelectionForFind.
  ///
  /// In ru, this message translates to:
  /// **'Искать выделенное'**
  String get useSelectionForFind;

  /// No description provided for @jumpToSelection.
  ///
  /// In ru, this message translates to:
  /// **'Перейти к выделению'**
  String get jumpToSelection;

  /// No description provided for @spellingAndGrammar.
  ///
  /// In ru, this message translates to:
  /// **'Орфография и грамматика'**
  String get spellingAndGrammar;

  /// No description provided for @showSpellingAndGrammar.
  ///
  /// In ru, this message translates to:
  /// **'Показать орфографию и грамматику'**
  String get showSpellingAndGrammar;

  /// No description provided for @checkDocumentNow.
  ///
  /// In ru, this message translates to:
  /// **'Проверить документ'**
  String get checkDocumentNow;

  /// No description provided for @checkSpellingWhileTyping.
  ///
  /// In ru, this message translates to:
  /// **'Проверять при вводе'**
  String get checkSpellingWhileTyping;

  /// No description provided for @checkGrammarWithSpelling.
  ///
  /// In ru, this message translates to:
  /// **'Проверять грамматику'**
  String get checkGrammarWithSpelling;

  /// No description provided for @correctSpellingAutomatically.
  ///
  /// In ru, this message translates to:
  /// **'Исправлять автоматически'**
  String get correctSpellingAutomatically;

  /// No description provided for @substitutions.
  ///
  /// In ru, this message translates to:
  /// **'Замены'**
  String get substitutions;

  /// No description provided for @showSubstitutions.
  ///
  /// In ru, this message translates to:
  /// **'Показать замены'**
  String get showSubstitutions;

  /// No description provided for @smartCopyPaste.
  ///
  /// In ru, this message translates to:
  /// **'Смарт-копирование и вставка'**
  String get smartCopyPaste;

  /// No description provided for @smartQuotes.
  ///
  /// In ru, this message translates to:
  /// **'Смарт-кавычки'**
  String get smartQuotes;

  /// No description provided for @smartDashes.
  ///
  /// In ru, this message translates to:
  /// **'Смарт-тире'**
  String get smartDashes;

  /// No description provided for @smartLinks.
  ///
  /// In ru, this message translates to:
  /// **'Смарт-ссылки'**
  String get smartLinks;

  /// No description provided for @dataDetectors.
  ///
  /// In ru, this message translates to:
  /// **'Распознавать данные'**
  String get dataDetectors;

  /// No description provided for @textReplacement.
  ///
  /// In ru, this message translates to:
  /// **'Замена текста'**
  String get textReplacement;

  /// No description provided for @transformations.
  ///
  /// In ru, this message translates to:
  /// **'Преобразования'**
  String get transformations;

  /// No description provided for @makeUpperCase.
  ///
  /// In ru, this message translates to:
  /// **'Прописные буквы'**
  String get makeUpperCase;

  /// No description provided for @makeLowerCase.
  ///
  /// In ru, this message translates to:
  /// **'Строчные буквы'**
  String get makeLowerCase;

  /// No description provided for @capitalize.
  ///
  /// In ru, this message translates to:
  /// **'С заглавных букв'**
  String get capitalize;

  /// No description provided for @speech.
  ///
  /// In ru, this message translates to:
  /// **'Речь'**
  String get speech;

  /// No description provided for @startSpeaking.
  ///
  /// In ru, this message translates to:
  /// **'Начать чтение'**
  String get startSpeaking;

  /// No description provided for @stopSpeaking.
  ///
  /// In ru, this message translates to:
  /// **'Остановить чтение'**
  String get stopSpeaking;

  /// No description provided for @enterFullScreen.
  ///
  /// In ru, this message translates to:
  /// **'На весь экран'**
  String get enterFullScreen;

  /// No description provided for @window.
  ///
  /// In ru, this message translates to:
  /// **'Окно'**
  String get window;

  /// No description provided for @minimize.
  ///
  /// In ru, this message translates to:
  /// **'Свернуть'**
  String get minimize;

  /// No description provided for @zoomLabel.
  ///
  /// In ru, this message translates to:
  /// **'Увеличить'**
  String get zoomLabel;

  /// No description provided for @bringAllToFront.
  ///
  /// In ru, this message translates to:
  /// **'Все окна на передний план'**
  String get bringAllToFront;

  /// No description provided for @help.
  ///
  /// In ru, this message translates to:
  /// **'Справка'**
  String get help;

  /// No description provided for @blankProject.
  ///
  /// In ru, this message translates to:
  /// **'Пустой проект'**
  String get blankProject;

  /// No description provided for @createProject.
  ///
  /// In ru, this message translates to:
  /// **'Создать проект'**
  String get createProject;

  /// No description provided for @createProjectFromTemplate.
  ///
  /// In ru, this message translates to:
  /// **'Создать проект из шаблона…'**
  String get createProjectFromTemplate;

  /// No description provided for @plywood.
  ///
  /// In ru, this message translates to:
  /// **'Фанера'**
  String get plywood;

  /// No description provided for @mdf.
  ///
  /// In ru, this message translates to:
  /// **'МДФ'**
  String get mdf;

  /// No description provided for @stockShopping.
  ///
  /// In ru, this message translates to:
  /// **'Материалы для покупки'**
  String get stockShopping;

  /// No description provided for @stockOffcut.
  ///
  /// In ru, this message translates to:
  /// **'Подойдёт остаток от {size}'**
  String stockOffcut(String size);

  /// No description provided for @stockKerf.
  ///
  /// In ru, this message translates to:
  /// **'Пропил {size} · размеры заготовок фактические'**
  String stockKerf(String size);

  /// No description provided for @stockBoard.
  ///
  /// In ru, this message translates to:
  /// **'Доска'**
  String get stockBoard;

  /// No description provided for @stockBar.
  ///
  /// In ru, this message translates to:
  /// **'Брусок'**
  String get stockBar;

  /// No description provided for @stockSheet.
  ///
  /// In ru, this message translates to:
  /// **'Лист'**
  String get stockSheet;

  /// No description provided for @shelfPart.
  ///
  /// In ru, this message translates to:
  /// **'Полка'**
  String get shelfPart;

  /// No description provided for @sidePanel.
  ///
  /// In ru, this message translates to:
  /// **'Боковина'**
  String get sidePanel;

  /// No description provided for @topPanel.
  ///
  /// In ru, this message translates to:
  /// **'Верхняя панель'**
  String get topPanel;

  /// No description provided for @bottomPanel.
  ///
  /// In ru, this message translates to:
  /// **'Дно'**
  String get bottomPanel;

  /// No description provided for @dividerPanel.
  ///
  /// In ru, this message translates to:
  /// **'Перегородка'**
  String get dividerPanel;

  /// No description provided for @backPanel.
  ///
  /// In ru, this message translates to:
  /// **'Задняя стенка'**
  String get backPanel;

  /// No description provided for @frontPanel.
  ///
  /// In ru, this message translates to:
  /// **'Передняя стенка'**
  String get frontPanel;

  /// No description provided for @doorPanel.
  ///
  /// In ru, this message translates to:
  /// **'Дверца'**
  String get doorPanel;

  /// No description provided for @tabletop.
  ///
  /// In ru, this message translates to:
  /// **'Столешница'**
  String get tabletop;

  /// No description provided for @seatPanel.
  ///
  /// In ru, this message translates to:
  /// **'Сиденье'**
  String get seatPanel;

  /// No description provided for @tread.
  ///
  /// In ru, this message translates to:
  /// **'Ступень'**
  String get tread;

  /// No description provided for @carryHandle.
  ///
  /// In ru, this message translates to:
  /// **'Рукоятка'**
  String get carryHandle;

  /// No description provided for @categoryShelving.
  ///
  /// In ru, this message translates to:
  /// **'Полки и стеллажи'**
  String get categoryShelving;

  /// No description provided for @categorySeating.
  ///
  /// In ru, this message translates to:
  /// **'Табуреты и скамьи'**
  String get categorySeating;

  /// No description provided for @categoryTables.
  ///
  /// In ru, this message translates to:
  /// **'Столы'**
  String get categoryTables;

  /// No description provided for @categoryCabinets.
  ///
  /// In ru, this message translates to:
  /// **'Тумбы и шкафы'**
  String get categoryCabinets;

  /// No description provided for @categoryWorkshop.
  ///
  /// In ru, this message translates to:
  /// **'Мастерская и офис'**
  String get categoryWorkshop;

  /// No description provided for @templateBookcase.
  ///
  /// In ru, this message translates to:
  /// **'Дощатый стеллаж на четыре полки'**
  String get templateBookcase;

  /// No description provided for @templateCubeShelf.
  ///
  /// In ru, this message translates to:
  /// **'Ступенчатый стеллаж-перегородка'**
  String get templateCubeShelf;

  /// No description provided for @templateWallShelf.
  ///
  /// In ru, this message translates to:
  /// **'Парящая полка со скрытым каркасом'**
  String get templateWallShelf;

  /// No description provided for @templateStool.
  ///
  /// In ru, this message translates to:
  /// **'Табурет с подставкой для гитары'**
  String get templateStool;

  /// No description provided for @templateStepStool.
  ///
  /// In ru, this message translates to:
  /// **'Двухступенчатый табурет'**
  String get templateStepStool;

  /// No description provided for @templateGardenBench.
  ///
  /// In ru, this message translates to:
  /// **'Садовая скамья с подлокотниками'**
  String get templateGardenBench;

  /// No description provided for @templateDiningTable.
  ///
  /// In ru, this message translates to:
  /// **'Обеденный стол на двух опорах'**
  String get templateDiningTable;

  /// No description provided for @templateWritingDesk.
  ///
  /// In ru, this message translates to:
  /// **'Письменный стол с боковыми полками'**
  String get templateWritingDesk;

  /// No description provided for @templateBedsideCabinet.
  ///
  /// In ru, this message translates to:
  /// **'Тумба с дверцей и нишей'**
  String get templateBedsideCabinet;

  /// No description provided for @templateBedroomWardrobe.
  ///
  /// In ru, this message translates to:
  /// **'Трёхстворчатый шкаф для спальни'**
  String get templateBedroomWardrobe;

  /// No description provided for @openDoor.
  ///
  /// In ru, this message translates to:
  /// **'Открыть дверцу'**
  String get openDoor;

  /// No description provided for @closeDoor.
  ///
  /// In ru, this message translates to:
  /// **'Закрыть дверцу'**
  String get closeDoor;

  /// No description provided for @panelHoles.
  ///
  /// In ru, this message translates to:
  /// **'Отверстия'**
  String get panelHoles;

  /// No description provided for @holeSelection.
  ///
  /// In ru, this message translates to:
  /// **'Отверстие {number} из {count}'**
  String holeSelection(int number, int count);

  /// No description provided for @holeReferenceCorner.
  ///
  /// In ru, this message translates to:
  /// **'Отступы от угла'**
  String get holeReferenceCorner;

  /// No description provided for @drillingType.
  ///
  /// In ru, this message translates to:
  /// **'Тип отверстия'**
  String get drillingType;

  /// No description provided for @drillingFace.
  ///
  /// In ru, this message translates to:
  /// **'Сторона сверления'**
  String get drillingFace;

  /// No description provided for @noPanelHoles.
  ///
  /// In ru, this message translates to:
  /// **'На детали пока нет отверстий'**
  String get noPanelHoles;

  /// No description provided for @addHole.
  ///
  /// In ru, this message translates to:
  /// **'Добавить отверстие'**
  String get addHole;

  /// No description provided for @holeName.
  ///
  /// In ru, this message translates to:
  /// **'Название отверстия'**
  String get holeName;

  /// No description provided for @showHoleNumbers.
  ///
  /// In ru, this message translates to:
  /// **'Показать номера на схеме'**
  String get showHoleNumbers;

  /// No description provided for @holeDepthRange.
  ///
  /// In ru, this message translates to:
  /// **'Глубина должна быть больше нуля и меньше толщины детали ({limit}).'**
  String holeDepthRange(String limit);

  /// No description provided for @holeDiameterRange.
  ///
  /// In ru, this message translates to:
  /// **'Диаметр должен быть больше нуля и не больше {limit}.'**
  String holeDiameterRange(String limit);

  /// No description provided for @holeOffsetRange.
  ///
  /// In ru, this message translates to:
  /// **'Отступ от края должен быть от {minimum} до {maximum}.'**
  String holeOffsetRange(String minimum, String maximum);

  /// No description provided for @holeDiameter.
  ///
  /// In ru, this message translates to:
  /// **'Диаметр'**
  String get holeDiameter;

  /// No description provided for @throughHole.
  ///
  /// In ru, this message translates to:
  /// **'Сквозное'**
  String get throughHole;

  /// No description provided for @blindHole.
  ///
  /// In ru, this message translates to:
  /// **'Глухое'**
  String get blindHole;

  /// No description provided for @faceA.
  ///
  /// In ru, this message translates to:
  /// **'Сторона А'**
  String get faceA;

  /// No description provided for @faceB.
  ///
  /// In ru, this message translates to:
  /// **'Сторона Б'**
  String get faceB;

  /// No description provided for @edgeBoringCommand.
  ///
  /// In ru, this message translates to:
  /// **'Присадка по кромке…'**
  String get edgeBoringCommand;

  /// No description provided for @chooseBoringEdge.
  ///
  /// In ru, this message translates to:
  /// **'Нажмите на кромку детали'**
  String get chooseBoringEdge;

  /// No description provided for @edgeBoringTitle.
  ///
  /// In ru, this message translates to:
  /// **'Присадка по кромке'**
  String get edgeBoringTitle;

  /// No description provided for @boltBoreOption.
  ///
  /// In ru, this message translates to:
  /// **'Торцевое отверстие'**
  String get boltBoreOption;

  /// No description provided for @boltFaceOffset.
  ///
  /// In ru, this message translates to:
  /// **'От пласти до оси'**
  String get boltFaceOffset;

  /// No description provided for @boltBoreDepth.
  ///
  /// In ru, this message translates to:
  /// **'Глубина с торца'**
  String get boltBoreDepth;

  /// No description provided for @boltBoreInvalid.
  ///
  /// In ru, this message translates to:
  /// **'Укажите диаметр и положение оси так, чтобы сверло помещалось в торце, а ось попадала в основное отверстие.'**
  String get boltBoreInvalid;

  /// No description provided for @drillingParameters.
  ///
  /// In ru, this message translates to:
  /// **'Параметры сверления'**
  String get drillingParameters;

  /// No description provided for @boringReferenceEdge.
  ///
  /// In ru, this message translates to:
  /// **'Кромка отсчёта'**
  String get boringReferenceEdge;

  /// No description provided for @boltReferenceFace.
  ///
  /// In ru, this message translates to:
  /// **'Базовая пласть'**
  String get boltReferenceFace;

  /// No description provided for @boreCenterDistance.
  ///
  /// In ru, this message translates to:
  /// **'До центра'**
  String get boreCenterDistance;

  /// No description provided for @boreRimDistance.
  ///
  /// In ru, this message translates to:
  /// **'До края отверстия'**
  String get boreRimDistance;

  /// No description provided for @boreCenterPitch.
  ///
  /// In ru, this message translates to:
  /// **'Шаг между центрами — {length}'**
  String boreCenterPitch(String length);

  /// No description provided for @boreCount.
  ///
  /// In ru, this message translates to:
  /// **'Количество отверстий'**
  String get boreCount;

  /// No description provided for @boreOutsidePanel.
  ///
  /// In ru, this message translates to:
  /// **'Задайте отступ так, чтобы отверстие помещалось на детали.'**
  String get boreOutsidePanel;

  /// No description provided for @enterBoreCount.
  ///
  /// In ru, this message translates to:
  /// **'Введите целое количество отверстий от 1.'**
  String get enterBoreCount;

  /// No description provided for @boreEndOffsets.
  ///
  /// In ru, this message translates to:
  /// **'Отступы до центров отверстий'**
  String get boreEndOffsets;

  /// No description provided for @boreEndMarginsInvalid.
  ///
  /// In ru, this message translates to:
  /// **'Укажите отступы от торцов так, чтобы отверстия помещались на детали.'**
  String get boreEndMarginsInvalid;

  /// No description provided for @boreSpacingInvalid.
  ///
  /// In ru, this message translates to:
  /// **'Для такого количества и отступов отверстия расположены слишком близко.'**
  String get boreSpacingInvalid;

  /// No description provided for @boreCollision.
  ///
  /// In ru, this message translates to:
  /// **'Новое отверстие пересекает существующее. Измените отступы или количество.'**
  String get boreCollision;

  /// No description provided for @addBoreRow.
  ///
  /// In ru, this message translates to:
  /// **'Добавить отверстия'**
  String get addBoreRow;

  /// No description provided for @fromLeft.
  ///
  /// In ru, this message translates to:
  /// **'От левого края'**
  String get fromLeft;

  /// No description provided for @fromRight.
  ///
  /// In ru, this message translates to:
  /// **'От правого края'**
  String get fromRight;

  /// No description provided for @fromBottom.
  ///
  /// In ru, this message translates to:
  /// **'От нижнего края'**
  String get fromBottom;

  /// No description provided for @fromTop.
  ///
  /// In ru, this message translates to:
  /// **'От верхнего края'**
  String get fromTop;

  /// No description provided for @invalidHole.
  ///
  /// In ru, this message translates to:
  /// **'Проверьте диаметр и отступы от краёв. Глубина глухого отверстия должна быть меньше толщины детали.'**
  String get invalidHole;

  /// No description provided for @ordinaryPart.
  ///
  /// In ru, this message translates to:
  /// **'Элемент'**
  String get ordinaryPart;

  /// No description provided for @chestLid.
  ///
  /// In ru, this message translates to:
  /// **'Крышка'**
  String get chestLid;

  /// No description provided for @groupType.
  ///
  /// In ru, this message translates to:
  /// **'Тип группы'**
  String get groupType;

  /// No description provided for @groupProperties.
  ///
  /// In ru, this message translates to:
  /// **'Свойства группы'**
  String get groupProperties;

  /// No description provided for @partProperties.
  ///
  /// In ru, this message translates to:
  /// **'Свойства детали'**
  String get partProperties;

  /// No description provided for @bazisExport.
  ///
  /// In ru, this message translates to:
  /// **'Для БАЗИС-Раскрой'**
  String get bazisExport;

  /// No description provided for @partType.
  ///
  /// In ru, this message translates to:
  /// **'Тип детали'**
  String get partType;

  /// No description provided for @forwardDirection.
  ///
  /// In ru, this message translates to:
  /// **'Вперёд'**
  String get forwardDirection;

  /// No description provided for @towardViewer.
  ///
  /// In ru, this message translates to:
  /// **'К вам'**
  String get towardViewer;

  /// No description provided for @awayFromViewer.
  ///
  /// In ru, this message translates to:
  /// **'От вас'**
  String get awayFromViewer;

  /// No description provided for @liftUpDoor.
  ///
  /// In ru, this message translates to:
  /// **'Дверца вверх · петли сверху'**
  String get liftUpDoor;

  /// No description provided for @dropDownDoor.
  ///
  /// In ru, this message translates to:
  /// **'Дверца вниз · петли снизу'**
  String get dropDownDoor;

  /// No description provided for @hingesLeft.
  ///
  /// In ru, this message translates to:
  /// **'Петли слева'**
  String get hingesLeft;

  /// No description provided for @hingesRight.
  ///
  /// In ru, this message translates to:
  /// **'Петли справа'**
  String get hingesRight;

  /// No description provided for @hingesTop.
  ///
  /// In ru, this message translates to:
  /// **'Петли сверху'**
  String get hingesTop;

  /// No description provided for @hingesBottom.
  ///
  /// In ru, this message translates to:
  /// **'Петли снизу'**
  String get hingesBottom;

  /// No description provided for @chooseHingeEdge.
  ///
  /// In ru, this message translates to:
  /// **'Нажмите на край дверцы'**
  String get chooseHingeEdge;

  /// No description provided for @doorAngle.
  ///
  /// In ru, this message translates to:
  /// **'Угол открывания'**
  String get doorAngle;

  /// No description provided for @leftHingedDoor.
  ///
  /// In ru, this message translates to:
  /// **'Распашная дверца с петлями слева'**
  String get leftHingedDoor;

  /// No description provided for @rightHingedDoor.
  ///
  /// In ru, this message translates to:
  /// **'Распашная дверца с петлями справа'**
  String get rightHingedDoor;

  /// No description provided for @clothesRail.
  ///
  /// In ru, this message translates to:
  /// **'Штанга для одежды'**
  String get clothesRail;

  /// No description provided for @templateTvStand.
  ///
  /// In ru, this message translates to:
  /// **'ТВ-тумба с отсеком для техники'**
  String get templateTvStand;

  /// No description provided for @templateWorkbench.
  ///
  /// In ru, this message translates to:
  /// **'Верстак Рубо с раздельной столешницей'**
  String get templateWorkbench;

  /// No description provided for @templateToolTote.
  ///
  /// In ru, this message translates to:
  /// **'Ящик для инструмента с диагональной ручкой'**
  String get templateToolTote;

  /// No description provided for @cuttingLayout.
  ///
  /// In ru, this message translates to:
  /// **'Схема раскроя'**
  String get cuttingLayout;

  /// No description provided for @categoryGarden.
  ///
  /// In ru, this message translates to:
  /// **'Сад и дача'**
  String get categoryGarden;

  /// No description provided for @templateDrawerChest.
  ///
  /// In ru, this message translates to:
  /// **'Комод с четырьмя ящиками'**
  String get templateDrawerChest;

  /// No description provided for @drawerFront.
  ///
  /// In ru, this message translates to:
  /// **'Фасад ящика'**
  String get drawerFront;

  /// No description provided for @planterWall.
  ///
  /// In ru, this message translates to:
  /// **'Доска борта'**
  String get planterWall;

  /// No description provided for @uprightPost.
  ///
  /// In ru, this message translates to:
  /// **'Стойка'**
  String get uprightPost;

  /// No description provided for @deckBoard.
  ///
  /// In ru, this message translates to:
  /// **'Доска настила'**
  String get deckBoard;

  /// No description provided for @frameRail.
  ///
  /// In ru, this message translates to:
  /// **'Обвязка'**
  String get frameRail;

  /// No description provided for @trellisSlat.
  ///
  /// In ru, this message translates to:
  /// **'Рейка шпалеры'**
  String get trellisSlat;

  /// No description provided for @benchBack.
  ///
  /// In ru, this message translates to:
  /// **'Планка спинки'**
  String get benchBack;

  /// No description provided for @landingRail.
  ///
  /// In ru, this message translates to:
  /// **'Поручень'**
  String get landingRail;

  /// No description provided for @roofBoard.
  ///
  /// In ru, this message translates to:
  /// **'Доска крыши'**
  String get roofBoard;

  /// No description provided for @rackFinger.
  ///
  /// In ru, this message translates to:
  /// **'Держатель струбцины'**
  String get rackFinger;

  /// No description provided for @templatePicnicTable.
  ///
  /// In ru, this message translates to:
  /// **'Детский стол для пикника с лавками'**
  String get templatePicnicTable;

  /// No description provided for @templateSawhorse.
  ///
  /// In ru, this message translates to:
  /// **'Столярные козлы'**
  String get templateSawhorse;

  /// No description provided for @templateClampRack.
  ///
  /// In ru, this message translates to:
  /// **'Гребёнка для струбцин'**
  String get templateClampRack;

  /// No description provided for @templateRaisedBed.
  ///
  /// In ru, this message translates to:
  /// **'Высокая грядка с обвязкой'**
  String get templateRaisedBed;

  /// No description provided for @templateStandingPlanter.
  ///
  /// In ru, this message translates to:
  /// **'Деревянное кашпо на ножках'**
  String get templateStandingPlanter;

  /// No description provided for @templateTrellisPlanter.
  ///
  /// In ru, this message translates to:
  /// **'Кашпо со шпалерой'**
  String get templateTrellisPlanter;

  /// No description provided for @templatePorch.
  ///
  /// In ru, this message translates to:
  /// **'Входное крыльцо с площадкой и перилами'**
  String get templatePorch;

  /// No description provided for @templateChaise.
  ///
  /// In ru, this message translates to:
  /// **'Реечный шезлонг'**
  String get templateChaise;

  /// No description provided for @templatePottingBench.
  ///
  /// In ru, this message translates to:
  /// **'Посадочный стол с нишей для лотка'**
  String get templatePottingBench;

  /// No description provided for @templateLogStore.
  ///
  /// In ru, this message translates to:
  /// **'Дровница с односкатной крышей'**
  String get templateLogStore;

  /// No description provided for @categoryConstruction.
  ///
  /// In ru, this message translates to:
  /// **'Столярка и каркасы'**
  String get categoryConstruction;

  /// No description provided for @floorJoist.
  ///
  /// In ru, this message translates to:
  /// **'Лага пола'**
  String get floorJoist;

  /// No description provided for @bridging.
  ///
  /// In ru, this message translates to:
  /// **'Диагональная распорка'**
  String get bridging;

  /// No description provided for @headerBeam.
  ///
  /// In ru, this message translates to:
  /// **'Перемычка проёма'**
  String get headerBeam;

  /// No description provided for @windowSill.
  ///
  /// In ru, this message translates to:
  /// **'Подоконная доска каркаса'**
  String get windowSill;

  /// No description provided for @roofRafter.
  ///
  /// In ru, this message translates to:
  /// **'Стропило'**
  String get roofRafter;

  /// No description provided for @ridgeBeam.
  ///
  /// In ru, this message translates to:
  /// **'Коньковая балка'**
  String get ridgeBeam;

  /// No description provided for @doorStile.
  ///
  /// In ru, this message translates to:
  /// **'Стойка дверного полотна'**
  String get doorStile;

  /// No description provided for @doorPanelInfill.
  ///
  /// In ru, this message translates to:
  /// **'Доска филёнки'**
  String get doorPanelInfill;

  /// No description provided for @gatePicket.
  ///
  /// In ru, this message translates to:
  /// **'Штакетина'**
  String get gatePicket;

  /// No description provided for @framingNote.
  ///
  /// In ru, this message translates to:
  /// **'Показаны лаги и распорки до укладки настила. Опоры, пролёт, сорт древесины, настил и крепёж рассчитывают по местным нагрузкам.'**
  String get framingNote;

  /// No description provided for @roofNote.
  ///
  /// In ru, this message translates to:
  /// **'Эскиз для привязки к участку. Фундамент, анкеры, кровлю и соединения подбирают по грунту, снегу, ветру и сейсмике региона.'**
  String get roofNote;

  /// No description provided for @porchNote.
  ///
  /// In ru, this message translates to:
  /// **'Привяжите отметку площадки к порогу и ходу двери. Для строительства проверьте фундамент, ступени, ограждения и крепления по местным нормам.'**
  String get porchNote;

  /// No description provided for @doorNote.
  ///
  /// In ru, this message translates to:
  /// **'Показано дверное полотно. Монтажные зазоры, коробку и петли подбирают по проёму и массе полотна.'**
  String get doorNote;

  /// No description provided for @gateNote.
  ///
  /// In ru, this message translates to:
  /// **'Петли слева при взгляде со стороны подкоса. Подкос опирается на нижнюю перекладину у петель и поддерживает верхний свободный угол.'**
  String get gateNote;

  /// No description provided for @templateShedFloor.
  ///
  /// In ru, this message translates to:
  /// **'Каркас пола бытовки с распорками «ёлочкой»'**
  String get templateShedFloor;

  /// No description provided for @templateWindowWall.
  ///
  /// In ru, this message translates to:
  /// **'Каркасная стена с оконным проёмом'**
  String get templateWindowWall;

  /// No description provided for @templateCornerWalls.
  ///
  /// In ru, this message translates to:
  /// **'Угол двух каркасных стен'**
  String get templateCornerWalls;

  /// No description provided for @templatePanelDoor.
  ///
  /// In ru, this message translates to:
  /// **'Межкомнатная рамочная дверь'**
  String get templatePanelDoor;

  /// No description provided for @templateGardenGate.
  ///
  /// In ru, this message translates to:
  /// **'Штакетная калитка с подкосом'**
  String get templateGardenGate;

  /// No description provided for @wallFrameNote.
  ///
  /// In ru, this message translates to:
  /// **'Показан каркас до обшивки. По местным нагрузкам рассчитывают стойки, перемычки, обшивку или укосины для жёсткости и анкеровку стен.'**
  String get wallFrameNote;

  /// No description provided for @templateSignatureCabinet.
  ///
  /// In ru, this message translates to:
  /// **'Фирменная тумба NeProSto'**
  String get templateSignatureCabinet;

  /// No description provided for @signatureDoor.
  ///
  /// In ru, this message translates to:
  /// **'Фасад с отверстием для пальца'**
  String get signatureDoor;

  /// No description provided for @endCutsTitle.
  ///
  /// In ru, this message translates to:
  /// **'Торцевые срезы'**
  String get endCutsTitle;

  /// No description provided for @faceMarkAngle.
  ///
  /// In ru, this message translates to:
  /// **'Разметка по ширине'**
  String get faceMarkAngle;

  /// No description provided for @edgeMarkAngle.
  ///
  /// In ru, this message translates to:
  /// **'Разметка по толщине'**
  String get edgeMarkAngle;

  /// No description provided for @cutOffsetReadout.
  ///
  /// In ru, this message translates to:
  /// **'Смещение {distance}'**
  String cutOffsetReadout(String distance);

  /// No description provided for @mitreSaw.
  ///
  /// In ru, this message translates to:
  /// **'Торцовочная пила'**
  String get mitreSaw;

  /// No description provided for @handheldSaw.
  ///
  /// In ru, this message translates to:
  /// **'Ручная циркулярная'**
  String get handheldSaw;

  /// No description provided for @tableSaw.
  ///
  /// In ru, this message translates to:
  /// **'Пильный стол'**
  String get tableSaw;

  /// No description provided for @sawCutLine.
  ///
  /// In ru, this message translates to:
  /// **'Линия пропила'**
  String get sawCutLine;

  /// No description provided for @sawFeed.
  ///
  /// In ru, this message translates to:
  /// **'Подача'**
  String get sawFeed;

  /// No description provided for @sawCrosscutFence.
  ///
  /// In ru, this message translates to:
  /// **'Поперечный упор'**
  String get sawCrosscutFence;

  /// No description provided for @sawTableSight.
  ///
  /// In ru, this message translates to:
  /// **'В разрезе'**
  String get sawTableSight;

  /// No description provided for @sawFeedView.
  ///
  /// In ru, this message translates to:
  /// **'Со стороны подачи'**
  String get sawFeedView;

  /// No description provided for @sawFenceNear.
  ///
  /// In ru, this message translates to:
  /// **'{angle}° · правый край к себе'**
  String sawFenceNear(String angle);

  /// No description provided for @sawFenceFar.
  ///
  /// In ru, this message translates to:
  /// **'{angle}° · правый край от себя'**
  String sawFenceFar(String angle);

  /// No description provided for @sawStockPosition.
  ///
  /// In ru, this message translates to:
  /// **'Деталь плашмя, начало слева'**
  String get sawStockPosition;

  /// No description provided for @sawTableRotation.
  ///
  /// In ru, this message translates to:
  /// **'Поворот стола'**
  String get sawTableRotation;

  /// No description provided for @sawBladeTilt.
  ///
  /// In ru, this message translates to:
  /// **'Наклон диска'**
  String get sawBladeTilt;

  /// No description provided for @sawAngleLeft.
  ///
  /// In ru, this message translates to:
  /// **'{angle}° влево'**
  String sawAngleLeft(String angle);

  /// No description provided for @sawAngleRight.
  ///
  /// In ru, this message translates to:
  /// **'{angle}° вправо'**
  String sawAngleRight(String angle);

  /// No description provided for @resetEndCut.
  ///
  /// In ru, this message translates to:
  /// **'Сбросить углы'**
  String get resetEndCut;

  /// No description provided for @cutsIntersect.
  ///
  /// In ru, this message translates to:
  /// **'Срезы пересекаются или оставляют слишком короткую кромку. Уменьшите угол одного из торцов.'**
  String get cutsIntersect;

  /// No description provided for @angleToLongEdge.
  ///
  /// In ru, this message translates to:
  /// **'К продольной кромке {angle}°'**
  String angleToLongEdge(String angle);

  /// No description provided for @rabbetTitle.
  ///
  /// In ru, this message translates to:
  /// **'Выборка фальца'**
  String get rabbetTitle;

  /// No description provided for @rabbetTopLeft.
  ///
  /// In ru, this message translates to:
  /// **'Верхнее левое'**
  String get rabbetTopLeft;

  /// No description provided for @rabbetTopRight.
  ///
  /// In ru, this message translates to:
  /// **'Верхнее правое'**
  String get rabbetTopRight;

  /// No description provided for @rabbetBottomLeft.
  ///
  /// In ru, this message translates to:
  /// **'Нижнее левое'**
  String get rabbetBottomLeft;

  /// No description provided for @rabbetBottomRight.
  ///
  /// In ru, this message translates to:
  /// **'Нижнее правое'**
  String get rabbetBottomRight;

  /// No description provided for @rabbetDepth.
  ///
  /// In ru, this message translates to:
  /// **'Глубина'**
  String get rabbetDepth;

  /// No description provided for @rabbetView.
  ///
  /// In ru, this message translates to:
  /// **'Вид с конечного торца. Выберите продольное ребро.'**
  String get rabbetView;

  /// No description provided for @rabbetRemove.
  ///
  /// In ru, this message translates to:
  /// **'Убрать фальц'**
  String get rabbetRemove;

  /// No description provided for @invalidRabbet.
  ///
  /// In ru, this message translates to:
  /// **'Задайте положительные ширину и глубину. Между фальцами и до противоположной грани должен оставаться материал.'**
  String get invalidRabbet;

  /// No description provided for @templateLaptopTray.
  ///
  /// In ru, this message translates to:
  /// **'Поднос для ноутбука'**
  String get templateLaptopTray;

  /// No description provided for @templateBagShelf.
  ///
  /// In ru, this message translates to:
  /// **'Вешалка с полкой для сумок'**
  String get templateBagShelf;

  /// No description provided for @templatePantryShelf.
  ///
  /// In ru, this message translates to:
  /// **'Узкая полка за дверью'**
  String get templatePantryShelf;

  /// No description provided for @templateConsoleTable.
  ///
  /// In ru, this message translates to:
  /// **'Консоль за диван с тремя секциями'**
  String get templateConsoleTable;

  /// No description provided for @templateMachineStand.
  ///
  /// In ru, this message translates to:
  /// **'Подставка для торцовочной пилы'**
  String get templateMachineStand;

  /// No description provided for @templateTrestleBench.
  ///
  /// In ru, this message translates to:
  /// **'Лавка на наклонных ножках'**
  String get templateTrestleBench;

  /// No description provided for @templateWindowBox.
  ///
  /// In ru, this message translates to:
  /// **'Оконный ящик для цветов'**
  String get templateWindowBox;

  /// No description provided for @templateBirdhouse.
  ///
  /// In ru, this message translates to:
  /// **'Треугольный домик для птиц'**
  String get templateBirdhouse;

  /// No description provided for @templateCandleShelf.
  ///
  /// In ru, this message translates to:
  /// **'Полка-подсвечник с треугольниками'**
  String get templateCandleShelf;

  /// No description provided for @templateBlanketLadder.
  ///
  /// In ru, this message translates to:
  /// **'Лестница для полотенец'**
  String get templateBlanketLadder;

  /// No description provided for @templateHeadphoneStand.
  ///
  /// In ru, this message translates to:
  /// **'Настольная подставка для наушников'**
  String get templateHeadphoneStand;

  /// No description provided for @templatePlantPanel.
  ///
  /// In ru, this message translates to:
  /// **'Настенная панель для растений'**
  String get templatePlantPanel;

  /// No description provided for @templateToyChest.
  ///
  /// In ru, this message translates to:
  /// **'Реечный ящик для игрушек'**
  String get templateToyChest;

  /// No description provided for @templateShutters.
  ///
  /// In ru, this message translates to:
  /// **'Трёхстворчатые складные ставни'**
  String get templateShutters;

  /// No description provided for @templateLantern.
  ///
  /// In ru, this message translates to:
  /// **'Декоративный фонарь для террасы'**
  String get templateLantern;

  /// No description provided for @templateMirrorFrame.
  ///
  /// In ru, this message translates to:
  /// **'Напольная рама для зеркала'**
  String get templateMirrorFrame;

  /// No description provided for @templateHexShelf.
  ///
  /// In ru, this message translates to:
  /// **'Шестиугольная полка-сота'**
  String get templateHexShelf;

  /// No description provided for @templateCoffeeTable.
  ///
  /// In ru, this message translates to:
  /// **'Журнальный столик с нижней полкой'**
  String get templateCoffeeTable;

  /// No description provided for @templateShoeBench.
  ///
  /// In ru, this message translates to:
  /// **'Скамья для обуви с тремя нишами'**
  String get templateShoeBench;

  /// No description provided for @templateTrivet.
  ///
  /// In ru, this message translates to:
  /// **'Решётчатая подставка под горячее'**
  String get templateTrivet;

  /// No description provided for @categoryHousehold.
  ///
  /// In ru, this message translates to:
  /// **'Для дома'**
  String get categoryHousehold;

  /// No description provided for @planEasy.
  ///
  /// In ru, this message translates to:
  /// **'Легко'**
  String get planEasy;

  /// No description provided for @planMedium.
  ///
  /// In ru, this message translates to:
  /// **'Средняя сложность'**
  String get planMedium;

  /// No description provided for @planAdvanced.
  ///
  /// In ru, this message translates to:
  /// **'Сложно'**
  String get planAdvanced;

  /// No description provided for @planSource.
  ///
  /// In ru, this message translates to:
  /// **'Фото и чертёж оригинала'**
  String get planSource;

  /// No description provided for @planDrawing.
  ///
  /// In ru, this message translates to:
  /// **'Чертёж оригинала (ZIP)'**
  String get planDrawing;

  /// No description provided for @planAdaptation.
  ///
  /// In ru, this message translates to:
  /// **'Модель адаптирована для редактора. В раскрой входят деревянные детали.'**
  String get planAdaptation;

  /// No description provided for @planHardwareHooks.
  ///
  /// In ru, this message translates to:
  /// **'Предусмотрите три крючка и подвесы для стены.'**
  String get planHardwareHooks;

  /// No description provided for @planShutterNote.
  ///
  /// In ru, this message translates to:
  /// **'Между створками оставлено по 3 мм под петли. Уточните зазоры по выбранной фурнитуре.'**
  String get planShutterNote;

  /// No description provided for @planLadderNote.
  ///
  /// In ru, this message translates to:
  /// **'Декоративная вешалка для пледов. Предусмотрите фиксацию к стене.'**
  String get planLadderNote;

  /// No description provided for @planChestNote.
  ///
  /// In ru, this message translates to:
  /// **'Для крышки нужны петли и опора, удерживающая её открытой.'**
  String get planChestNote;

  /// No description provided for @planMirrorNote.
  ///
  /// In ru, this message translates to:
  /// **'Отдельно нужны зеркало 407 × 1525 мм, крепление полотна и фиксация рамы к стене.'**
  String get planMirrorNote;

  /// No description provided for @planRoundedNote.
  ///
  /// In ru, this message translates to:
  /// **'Показаны прямоугольные заготовки. Скруглите контактные кромки при отделке.'**
  String get planRoundedNote;

  /// No description provided for @planTrivetNote.
  ///
  /// In ru, this message translates to:
  /// **'Вариант по рисунку Craftsmanspace: два слоя реек 12 × 7 мм склеиваются крест-накрест.'**
  String get planTrivetNote;

  /// No description provided for @roomKitchen.
  ///
  /// In ru, this message translates to:
  /// **'Кухня'**
  String get roomKitchen;

  /// No description provided for @roomLivingRoom.
  ///
  /// In ru, this message translates to:
  /// **'Гостиная'**
  String get roomLivingRoom;

  /// No description provided for @roomBedroom.
  ///
  /// In ru, this message translates to:
  /// **'Спальня'**
  String get roomBedroom;

  /// No description provided for @roomNursery.
  ///
  /// In ru, this message translates to:
  /// **'Детская'**
  String get roomNursery;

  /// No description provided for @roomEntryway.
  ///
  /// In ru, this message translates to:
  /// **'Прихожая'**
  String get roomEntryway;

  /// No description provided for @roomBathroom.
  ///
  /// In ru, this message translates to:
  /// **'Ванная'**
  String get roomBathroom;

  /// No description provided for @roomOffice.
  ///
  /// In ru, this message translates to:
  /// **'Кабинет'**
  String get roomOffice;

  /// No description provided for @templateAssembly.
  ///
  /// In ru, this message translates to:
  /// **'Как собрать'**
  String get templateAssembly;

  /// No description provided for @templateHoodCabinet.
  ///
  /// In ru, this message translates to:
  /// **'Навесной шкаф под вытяжку'**
  String get templateHoodCabinet;

  /// No description provided for @templateSinkBase.
  ///
  /// In ru, this message translates to:
  /// **'Корпус тумбы под мойку'**
  String get templateSinkBase;

  /// No description provided for @templatePlatformBed.
  ///
  /// In ru, this message translates to:
  /// **'Кровать с реечным основанием'**
  String get templatePlatformBed;

  /// No description provided for @templateBasinShelf.
  ///
  /// In ru, this message translates to:
  /// **'Подвесная тумба с вырезом под сифон'**
  String get templateBasinShelf;

  /// No description provided for @templateFileTrays.
  ///
  /// In ru, this message translates to:
  /// **'Трёхъярусный лоток для бумаги'**
  String get templateFileTrays;

  /// No description provided for @ductOpening.
  ///
  /// In ru, this message translates to:
  /// **'Проход воздуховода'**
  String get ductOpening;

  /// No description provided for @chaseSide.
  ///
  /// In ru, this message translates to:
  /// **'Боковина короба'**
  String get chaseSide;

  /// No description provided for @chaseCover.
  ///
  /// In ru, this message translates to:
  /// **'Съёмная стенка короба'**
  String get chaseCover;

  /// No description provided for @hangingRail.
  ///
  /// In ru, this message translates to:
  /// **'Монтажная планка'**
  String get hangingRail;

  /// No description provided for @hingeCup.
  ///
  /// In ru, this message translates to:
  /// **'Чашка петли'**
  String get hingeCup;

  /// No description provided for @plinth.
  ///
  /// In ru, this message translates to:
  /// **'Цоколь'**
  String get plinth;

  /// No description provided for @slatLedger.
  ///
  /// In ru, this message translates to:
  /// **'Опорная рейка'**
  String get slatLedger;

  /// No description provided for @centerRail.
  ///
  /// In ru, this message translates to:
  /// **'Центральная балка'**
  String get centerRail;

  /// No description provided for @bedSlat.
  ///
  /// In ru, this message translates to:
  /// **'Рейка основания'**
  String get bedSlat;

  /// No description provided for @shelfWing.
  ///
  /// In ru, this message translates to:
  /// **'Боковая часть полки'**
  String get shelfWing;

  /// No description provided for @paperTray.
  ///
  /// In ru, this message translates to:
  /// **'Полка для бумаги'**
  String get paperTray;

  /// No description provided for @bedRim.
  ///
  /// In ru, this message translates to:
  /// **'Борт грядки с запилами'**
  String get bedRim;

  /// No description provided for @assembleHoodCabinet.
  ///
  /// In ru, this message translates to:
  /// **'Дно и крышку стяните с боковинами конфирматами. Полки закрепите между боковинами и щеками короба, лицевую стенку короба прикрутите съёмно. Труба проходит через два соосных отверстия. Положение и диаметр прохода, точки крепления снизу и высоту установки сверьте с монтажным шаблоном вашей вытяжки. Дверцы навесьте на чашечные петли, шкаф закрепите через монтажные планки.'**
  String get assembleHoodCabinet;

  /// No description provided for @assembleSinkBase.
  ///
  /// In ru, this message translates to:
  /// **'Дно и верхние стяжки соедините с боковинами конфирматами, цоколь прикрутите с внутренней стороны. Стяжки связывают открытый верх под столешницей. Задняя перемычка оставляет доступ к водопроводу и сливу.'**
  String get assembleSinkBase;

  /// No description provided for @assemblePantryShelf.
  ///
  /// In ru, this message translates to:
  /// **'Полки закрепите между боковинами винтами через боковые стенки. Передние ограничители прикрутите к торцам боковин. Высокий узкий стеллаж закрепите к стене.'**
  String get assemblePantryShelf;

  /// No description provided for @assembleDiningTable.
  ///
  /// In ru, this message translates to:
  /// **'Сначала соберите две рамные опоры, стянув поперечины с ножками болтами. Прикрепите каждую доску столешницы к обеим рамам снизу, оставив между досками зазоры.'**
  String get assembleDiningTable;

  /// No description provided for @assembleSignatureCabinet.
  ///
  /// In ru, this message translates to:
  /// **'Соберите ступенчатый корпус на шкантах и клею, затем приклейте лицевые планки. Задние стенки удерживают корпус прямоугольным. Навесьте фасад на петли, круглое сквозное отверстие служит ручкой.'**
  String get assembleSignatureCabinet;

  /// No description provided for @assembleBookcase.
  ///
  /// In ru, this message translates to:
  /// **'Соберите две боковые рамы, прикрутив поперечины к стойкам. Закрепите опорные бруски и привинтите доски каждой полки к обеим опорам. Верх стеллажа закрепите к стене.'**
  String get assembleBookcase;

  /// No description provided for @assembleCoffeeTable.
  ///
  /// In ru, this message translates to:
  /// **'Соедините царги с ножками на шкантах с клеем. Нижнюю полку уложите на планки между царгами. Фанерную столешницу закрепите снизу через угловые крепления.'**
  String get assembleCoffeeTable;

  /// No description provided for @assembleTvStand.
  ///
  /// In ru, this message translates to:
  /// **'Соедините панели корпуса и перегородки конфирматами. Закрепите спинку по периметру и к перегородкам. Крайние секции закрываются накладными фасадами, средняя остаётся открытой.'**
  String get assembleTvStand;

  /// No description provided for @assembleBedroomWardrobe.
  ///
  /// In ru, this message translates to:
  /// **'Стяните дно, крышку и перегородки конфирматами. Поставьте штанги на держатели, закрепите полки и задние панели. Петли навесьте со стороны, указанной у каждой двери. Высокий корпус закрепите к стене.'**
  String get assembleBedroomWardrobe;

  /// No description provided for @assemblePlatformBed.
  ///
  /// In ru, this message translates to:
  /// **'Царги соедините разборными кроватными стяжками. Изнутри прикрутите опорные рейки. Центральную балку поставьте на отдельные ножки и закрепите к торцевым царгам. Ламели опираются на три линии и фиксируются от сдвига.'**
  String get assemblePlatformBed;

  /// No description provided for @assembleDrawerChest.
  ///
  /// In ru, this message translates to:
  /// **'Корпус соберите на конфирматах. Дно и заднюю стенку каждого ящика соедините с боковинами, затем закрепите фасад изнутри. Парные направляющие ставьте на одной высоте с учётом бокового зазора выбранного комплекта. Корпус закрепите к стене.'**
  String get assembleDrawerChest;

  /// No description provided for @assembleToyChest.
  ///
  /// In ru, this message translates to:
  /// **'Склейте парные стойки. Торцы досок стенок и нижней обвязки притяните к стойкам косыми шурупами через карманы с внутренней стороны. Доски дна прикрутите сверху к обвязке, планки крышки — снизу к поперечинам. Рояльную петлю поставьте вдоль верхней задней доски. Подберите упор под вес крышки, чтобы он удерживал её в любом положении. Оставьте вентиляционные щели открытыми.'**
  String get assembleToyChest;

  /// No description provided for @assembleCubeShelf.
  ///
  /// In ru, this message translates to:
  /// **'Начните с общей нижней панели. Ступени собирайте снизу вверх на шкантах и мебельных стяжках, пока доступны торцы полок. Собранный стеллаж закрепите к стене.'**
  String get assembleCubeShelf;

  /// No description provided for @assembleStepStool.
  ///
  /// In ru, this message translates to:
  /// **'Склейте фанерные боковины с подступенками на шкантах. Проступи положите сверху на опоры и закрепите потайными шурупами. Проверьте, что обе боковины стоят на полу всей нижней кромкой.'**
  String get assembleStepStool;

  /// No description provided for @assembleShoeBench.
  ///
  /// In ru, this message translates to:
  /// **'Соберите цоколь, поставьте на него дно. Стенки и перегородки стяните с сиденьем и дном на шкантах с клеем. Заднюю панель закрепите по краям, чтобы скамья сохраняла форму.'**
  String get assembleShoeBench;

  /// No description provided for @assembleConsoleTable.
  ///
  /// In ru, this message translates to:
  /// **'Стяните боковины с верхней и нижней панелями. Полки соедините с перегородками шкантами при сборке каждой секции. Для узкой консоли предусмотрите крепление к стене.'**
  String get assembleConsoleTable;

  /// No description provided for @assembleMirrorFrame.
  ///
  /// In ru, this message translates to:
  /// **'Поперечины соедините со стойками на шкантах. Соберите проставки, запилите их задние торцы по модели и закрепите раму к стене. Зеркало установите на отдельные держатели для стекла.'**
  String get assembleMirrorFrame;

  /// No description provided for @assembleBasinShelf.
  ///
  /// In ru, this message translates to:
  /// **'У каждой полки передняя часть и два крыла образуют открытый назад вырез под сифон. Соедините их на шкантах с влагостойким клеем, затем закрепите между боковинами. Монтажные планки за крыльями притяните к стене, торцы фанеры защитите от влаги.'**
  String get assembleBasinShelf;

  /// No description provided for @assembleBlanketLadder.
  ///
  /// In ru, this message translates to:
  /// **'Перекладины соедините со стойками на двух шкантах с каждой стороны, зафиксировав их от проворачивания. Верх закрепите к стене. Лестница предназначена для полотенец.'**
  String get assembleBlanketLadder;

  /// No description provided for @assembleWritingDesk.
  ///
  /// In ru, this message translates to:
  /// **'Столешница опирается на боковину и тумбу с полками. Соедините панели конфирматами, затем закрепите задние перемычки между опорами. Перемычки удерживают стол от бокового раскачивания.'**
  String get assembleWritingDesk;

  /// No description provided for @assembleWallShelf.
  ///
  /// In ru, this message translates to:
  /// **'Прикрутите поперечные бруски к задней рейке. Закрепите рейку на несущем основании стены, наденьте фанерный кожух и прикрутите его к каркасу снизу.'**
  String get assembleWallShelf;

  /// No description provided for @assembleFileTrays.
  ///
  /// In ru, this message translates to:
  /// **'Приклейте опорные рейки попарно на одной высоте. Вложите в каждый ярус фанерную полку и закрепите заднюю стенку, чтобы боковины не расходились.'**
  String get assembleFileTrays;

  /// No description provided for @assembleWorkbench.
  ///
  /// In ru, this message translates to:
  /// **'Склейте ножки и обе половины наборной столешницы по отдельности. Царги стяните с ножками болтами. Половины столешницы закрепите к подстолью снизу, сохранив продольный просвет и возможность сезонного движения древесины.'**
  String get assembleWorkbench;

  /// No description provided for @assembleSawhorse.
  ///
  /// In ru, this message translates to:
  /// **'Запилите торцы наклонных ножек по модели, чтобы они опирались на пол и под верхнюю доску всей плоскостью. Стяните боковые фартуки с ножками болтами и закрепите нижние распорки.'**
  String get assembleSawhorse;

  /// No description provided for @assembleMachineStand.
  ///
  /// In ru, this message translates to:
  /// **'Соберите две торцевые рамы, стяните их продольными царгами. Закрепите фанерные настилы сверху к обвязке. Нижняя полка состоит из трёх частей и обходит ножки.'**
  String get assembleMachineStand;

  /// No description provided for @assembleRaisedBed.
  ///
  /// In ru, this message translates to:
  /// **'Доски стенок прикрутите снаружи к угловым и средним стойкам уличными шурупами. Средние стойки соедините поперечной стяжкой. Все четыре верхних борта запилите с обоих концов под 45° и закрепите сверху к стойкам.'**
  String get assembleRaisedBed;

  /// No description provided for @assembleBench.
  ///
  /// In ru, this message translates to:
  /// **'Соедините продольные и поперечные царги с ножками шкантами на клею или косыми шурупами изнутри. Выставьте одинаковые зазоры между планками сиденья и прикрутите их сверху к царгам.'**
  String get assembleBench;

  /// No description provided for @assemblePicnicTable.
  ///
  /// In ru, this message translates to:
  /// **'Сначала соберите две А-образные опоры. Скошенные ножки соедините с поперечинами сквозными болтами и шайбами. Положите доски стола и сидений на опоры, закрепите их сверху, затем установите продольную стяжку.'**
  String get assemblePicnicTable;

  /// No description provided for @assembleChaise.
  ///
  /// In ru, this message translates to:
  /// **'Соберите боковые рамы. Спинку закрепите в заданном наклоне на болтах, выдерживая запилы опор. Прикрутите рейки сиденья и спинки к обеим боковинам, оставив зазоры для стока воды.'**
  String get assembleChaise;

  /// No description provided for @assemblePottingBench.
  ///
  /// In ru, this message translates to:
  /// **'Соберите каркас из стоек и царг на уличных шурупах. Настил столешницы закрепите на поперечинах, оставив проём для съёмного лотка. Задние стойки несут отдельную верхнюю полку.'**
  String get assemblePottingBench;

  /// No description provided for @assembleLogStore.
  ///
  /// In ru, this message translates to:
  /// **'Стяните стойки продольной обвязкой, положите доски пола на поперечины. Верхние торцы стоек запилите по уклону крыши. Рейки стен закрепите с зазорами для проветривания дров.'**
  String get assembleLogStore;

  /// No description provided for @assembleGardenGate.
  ///
  /// In ru, this message translates to:
  /// **'Прикрутите штакетины к двум поперечинам. Запилите подкос так, чтобы он упирался торцами в обе перекладины и передавал нагрузку от верхнего свободного угла к нижней петле. Петли крепите в поперечины.'**
  String get assembleGardenGate;

  /// No description provided for @assembleBirdhouse.
  ///
  /// In ru, this message translates to:
  /// **'Сведите запиленные кромки скатов в коньке. Торцевые панели и дно прикрутите к скатам через предварительно просверленные отверстия. Один торец закрепите съёмно для очистки.'**
  String get assembleBirdhouse;

  /// No description provided for @assemblePorch.
  ///
  /// In ru, this message translates to:
  /// **'Соберите рамы ступеней и площадки, закрепите настил к поперечинам. Стойки ограждения стяните с рамой болтами. Поручень подрежьте под уклон и закрепите на стойках. Крепление к основанию выбирают по месту установки.'**
  String get assemblePorch;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ky', 'ru'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ky':
      return AppLocalizationsKy();
    case 'ru':
      return AppLocalizationsRu();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
