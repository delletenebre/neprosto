// ignore_for_file: deprecated_member_use

// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get layFaceDown => 'Lay this face down';

  @override
  String get stockTurnHint =>
      'Choose a plane and click −90° or +90° on the workpiece.';

  @override
  String linkToHole(int number) {
    return 'Link to center of hole $number';
  }

  @override
  String get holeGroups => 'Hole groups';

  @override
  String get addLinkedShaft => 'Add linked edge hole';

  @override
  String get addEdgeBore => 'Add edge hole…';

  @override
  String linkedFaceHole(int number) {
    return 'Go to hole $number';
  }

  @override
  String anchoredFaceHole(int number) {
    return 'Anchored to hole $number';
  }

  @override
  String get detachHoleAnchor => 'Remove anchor';

  @override
  String get pointAnchor => 'Anchored to point';

  @override
  String get faceMagnet => 'Snap while dragging';

  @override
  String pickHoleAnchor(String modifier) {
    return '$modifier-click the drawing to anchor to a point or another hole center';
  }

  @override
  String get drillMode => '3D';

  @override
  String get faceMarkA => 'A';

  @override
  String get faceMarkB => 'B';

  @override
  String get spatialOverview => 'Overview';

  @override
  String get clearOrbitPivot => 'Clear rotation pivot';

  @override
  String holeNavigationHint(String modifier) {
    return '$modifier+Shift-click to set pivot · Right-drag to rotate · $modifier + wheel to zoom';
  }

  @override
  String get openingSensor => 'Opening sensor';

  @override
  String get customDrill => 'Custom bore';

  @override
  String get drillMagnet => 'Magnet';

  @override
  String get drillHint => 'Click to drill · Shift-click to set zero';

  @override
  String get edgeOrbitHint => 'Click an edge face to select it';

  @override
  String get resetDatum => 'Reset datum';

  @override
  String get drillGridInvalid =>
      'Enter a non-negative offset and a positive spacing.';

  @override
  String get addConnection => 'Add connection';

  @override
  String get confirmat => 'Confirmat';

  @override
  String get dowel => 'Dowel';

  @override
  String get dowels => 'Dowels';

  @override
  String get connectionRuler => 'Connection ruler';

  @override
  String get datumOffset => 'First mark from datum';

  @override
  String get markPitch => 'Mark spacing';

  @override
  String get baseDistance => 'Distance from datum';

  @override
  String get panelFaces => 'Faces';

  @override
  String get panelEdges => 'Edges';

  @override
  String get beforeHardware => 'Before';

  @override
  String get afterHardware => 'After';

  @override
  String get bothHardware => 'Both sides';

  @override
  String get chooseConnectionBase =>
      'Click the edge near the end to use as zero.';

  @override
  String get placeConnection => 'Move along the ruler and click to drill.';

  @override
  String get placeOnDrawing => 'Place on drawing';

  @override
  String get connectionDoesNotFit =>
      'The drilling pattern does not fit this part.';

  @override
  String get camThickness => 'Panel too thin for this housing';

  @override
  String get datum => 'Datum';

  @override
  String get emptyEdge => 'No bores on this edge';

  @override
  String get pocketShoulder => 'Depth to shoulder';

  @override
  String get edgeBanding => 'Edge banding';

  @override
  String get bandWholePerimeter => 'All edges';

  @override
  String get deselectAllEdges => 'Clear selection';

  @override
  String get bandingEdges => 'Edges';

  @override
  String get bandThickness => 'Tape thickness';

  @override
  String get bandWidth => 'Tape width';

  @override
  String get matchPanelThickness => 'Match panel thickness';

  @override
  String get invalidEdgeBanding => 'Invalid edge banding';

  @override
  String get positiveBandSize => 'Enter a size greater than zero.';

  @override
  String get woodBasedPanel => 'Wood-based panel';

  @override
  String get woodBasedPanelFullName => 'Wood-based panel';

  @override
  String get panelFaceColor => 'Face color';

  @override
  String get edgeBandColor => 'Edge band color';

  @override
  String get partFinish => 'Material';

  @override
  String get mixedValues => 'Mixed';

  @override
  String get pineColor => 'Pine';

  @override
  String get oakColor => 'Oak';

  @override
  String get whiteColor => 'White';

  @override
  String get grayColor => 'Gray';

  @override
  String get graphiteColor => 'Graphite';

  @override
  String get beigeColor => 'Beige';

  @override
  String get blackColor => 'Black';

  @override
  String get greenColor => 'Green';

  @override
  String get blueColor => 'Blue';

  @override
  String get brickColor => 'Brick red';

  @override
  String get finishTexture => 'Texture';

  @override
  String get finishColor => 'Color';

  @override
  String get metal => 'Metal';

  @override
  String get solidColor => 'Solid color';

  @override
  String get naturalWood => 'Wood';

  @override
  String get whiteBoard => 'White melamine board';

  @override
  String get oakBoard => 'Oak melamine board';

  @override
  String get aluminumProfile => 'Aluminum profile';

  @override
  String get steelProfile => 'Graphite steel profile';

  @override
  String get invalidPartFinish => 'Invalid part material';

  @override
  String get invalidHexColor => 'Enter a color in #RRGGBB format';

  @override
  String get positiveThickness => '+T';

  @override
  String get positiveWidth => '+W';

  @override
  String get xWidth => 'X · width';

  @override
  String get horizontalPlane => 'Horizontal';

  @override
  String get workPlanePurpose => 'Where do you want to draw and move parts?';

  @override
  String get horizontalPlaneExample => 'Like a shelf or tabletop';

  @override
  String get frontPlaneExample => 'Like a cabinet door';

  @override
  String get sidePlaneExample => 'Like the side of a cabinet';

  @override
  String get partFacePlane => 'On a part face';

  @override
  String get workPlaneNeedsPart => 'A visible part is needed in the drawing';

  @override
  String get yDepth => 'Y · depth';

  @override
  String get zHeight => 'Z · height';

  @override
  String edgeCaption(Object side) {
    return '$side\nedge';
  }

  @override
  String scrollGesture(Object modifier) {
    return '$modifier + scroll';
  }

  @override
  String sketchEndHint(
    Object part,
    Object width,
    Object thickness,
    Object unit,
  ) {
    return '$part · $width × $thickness $unit · set the end point';
  }

  @override
  String liftHint(Object instruction, Object modifier) {
    return '$instruction · $modifier to lift · add Shift to follow Z';
  }

  @override
  String endAngleValue(Object end, Object angle) {
    return '$end · $angle° from square';
  }

  @override
  String unsavedTab(Object name) {
    return '$name · Unsaved changes';
  }

  @override
  String depthDirection(Object axis) {
    return '$axis · into depth';
  }

  @override
  String heightGesture(Object mode) {
    return '$mode · move the pointer up to set the height';
  }

  @override
  String placeEndHint(Object mode) {
    return '$mode · click to place the end of the part';
  }

  @override
  String resizeLockHint(Object action, Object dimension) {
    return '$action resizing · $dimension';
  }

  @override
  String pieceCount(Object count) {
    return '$count pcs';
  }

  @override
  String partsFilename(Object name) {
    return '$name — parts list';
  }

  @override
  String get automatic => 'Auto';

  @override
  String get autosave => 'Autosave';

  @override
  String get axonometric => 'Axonometric';

  @override
  String get untitled => 'Untitled';

  @override
  String numberedUntitled(Object number) {
    return 'Untitled $number';
  }

  @override
  String get lock => 'Lock';

  @override
  String get partLocks => 'Part locks';

  @override
  String get side => 'Side';

  @override
  String get inTheThicknessPlane => 'In the thickness plane';

  @override
  String get inTheWidthPlane => 'In the width plane';

  @override
  String get thisProjectHasNoPartsYet => 'This project has no parts yet';

  @override
  String get noStopInThisDirection => 'No stop in this direction';

  @override
  String get invalidInsideAngle => 'Enter an inside angle between 0° and 180°';

  @override
  String get positiveIntegerHint => 'Enter a whole number of 1 or more.';

  @override
  String get up => 'Up';

  @override
  String get vertical => 'Vertical';

  @override
  String get cubeTop => 'Top';

  @override
  String get upper => 'Upper';

  @override
  String get fixedDimensionsFillSpan =>
      'Locked dimensions occupy the full span';

  @override
  String get view => 'View';

  @override
  String get views => 'Views';

  @override
  String get gridVisibility => 'Grid visibility';

  @override
  String get left => 'Left';

  @override
  String get down => 'Down';

  @override
  String get insideAngle => 'Inside angle';

  @override
  String get fitToWindow => 'Fit to window';

  @override
  String fitShortcut(Object shortcut) {
    return 'Fit to window · $shortcut';
  }

  @override
  String get right => 'Right';

  @override
  String get alwaysVisible => 'Always visible';

  @override
  String get shortcutKeyHint =>
      'Choose a letter, number, arrow or function key';

  @override
  String get selectTheSecondShelf => 'Select the second shelf';

  @override
  String get selectWorkPlaneFace =>
      'Click the surface of a part in the drawing';

  @override
  String get chooseParallelShelf =>
      'Select another shelf with an overlapping projection and a parallel face';

  @override
  String get chooseAlignmentHint =>
      'Pick a point on each part, or choose an alignment in the panel';

  @override
  String get chooseMovingAnchor => '2 of 2. Pick a point on the part to move.';

  @override
  String get selectAnAnchorOnThePart => 'Select an anchor on the part';

  @override
  String get chooseAReference => 'Choose a reference…';

  @override
  String get selectTheFirstShelf => 'Select the first shelf';

  @override
  String get selectParts => 'Select parts';

  @override
  String selectedParts(Object count) {
    return 'Selected parts · $count';
  }

  @override
  String selectShortcut(Object shortcut) {
    return 'Select · $shortcut';
  }

  @override
  String get selectAllParts => 'Select all parts';

  @override
  String get chooseReferenceFromList => 'Choose a reference part from the list';

  @override
  String get alignment => 'Alignment';

  @override
  String get alignToReference => 'Align to reference…';

  @override
  String overallSizeMustExceed(Object size, Object unit) {
    return 'Overall size must exceed $size $unit';
  }

  @override
  String get projectBounds => 'Project bounds';

  @override
  String get assemblyDimensions => 'Assembly dimensions';

  @override
  String get keyboardShortcuts => 'Keyboard shortcuts';

  @override
  String get done => 'Done';

  @override
  String get resizeProducts => 'Resize products';

  @override
  String get face => 'Face';

  @override
  String get shelfFace => 'Shelf face';

  @override
  String numberedGroup(Object number) {
    return 'Group $number';
  }

  @override
  String get lengthInitial => 'L';

  @override
  String get twoPoints => 'Two points';

  @override
  String get moveAndResizeInIncrements => 'Move and resize in increments';

  @override
  String get partsTree => 'Parts tree';

  @override
  String partCount(Object count) {
    return 'Parts · $count';
  }

  @override
  String get partsLabel => 'Parts';

  @override
  String partsTabCount(Object count) {
    return 'Parts  $count';
  }

  @override
  String get assemblyParts => 'Assembly parts';

  @override
  String get noMatchingParts => 'No matching parts';

  @override
  String get part => 'Part';

  @override
  String numberedPart(Object id) {
    return 'Part $id';
  }

  @override
  String get thePartIntersectsItsReference =>
      'The part intersects its reference';

  @override
  String get alreadyTouchesReferences =>
      'The part already touches both references';

  @override
  String get length => 'Length';

  @override
  String get stockLength => 'Stock length';

  @override
  String stockLengthInUnits(Object unit) {
    return 'Stock length, $unit';
  }

  @override
  String get lengthTooShortForCuts =>
      'Length is shorter than the difference between cuts';

  @override
  String shortAndLongEdgeLengths(Object unit) {
    return 'Short and long edge lengths, $unit';
  }

  @override
  String get matchingSectionsRequired =>
      'Choose matching cross sections for a symmetrical joint';

  @override
  String bothStops(Object first, Object second) {
    return 'To stops · $first and $second';
  }

  @override
  String get upToNextStop => 'Up to next stop';

  @override
  String get leftToNextStop => 'Left to next stop';

  @override
  String get downToNextStop => 'Down to next stop';

  @override
  String get rightToNextStop => 'Right to next stop';

  @override
  String get addASecondPartToAlignThem => 'Add a second part to align them';

  @override
  String get duplicate => 'Duplicate';

  @override
  String get inches => 'Inches';

  @override
  String discardChangesWarning(Object name) {
    return 'Closing “$name” will discard your latest changes.';
  }

  @override
  String get stockPiece => 'Stock piece';

  @override
  String get stockTooShort => 'The stock is too short for this cut';

  @override
  String get stock => 'Stock';

  @override
  String get cubeBack => 'Back';

  @override
  String get rear => 'Rear';

  @override
  String get backEdge => 'Back edge';

  @override
  String gap(Object distance, Object unit) {
    return 'Gap $distance $unit';
  }

  @override
  String get closeTab => 'Close tab';

  @override
  String closeProjectTab(String name) {
    return 'Close “$name” tab';
  }

  @override
  String get closeGridSettings => 'Close grid settings';

  @override
  String get closePartDimensions => 'Close part dimensions';

  @override
  String miterEndAngle(Object angle) {
    return 'Cut each end $angle° from square';
  }

  @override
  String get autosaveFilesHint =>
      'Changes are written to open project files. New projects are kept as local drafts.';

  @override
  String measureShortcut(Object shortcut) {
    return 'Measure · $shortcut';
  }

  @override
  String get measureDistance => 'Measure distance';

  @override
  String get tools => 'Tools';

  @override
  String get intervalMin => 'Interval, min';

  @override
  String get excelWorkbook => 'Excel workbook';

  @override
  String get qty => 'Qty';

  @override
  String get quantityPcs => 'Quantity, pcs';

  @override
  String get endPoint => 'End';

  @override
  String get endCut => 'End cut';

  @override
  String edges(Object lengths, Object unit) {
    return 'Edges · $lengths $unit';
  }

  @override
  String get cubeLeft => 'Left';

  @override
  String get leftHand => 'Left-hand';

  @override
  String get ruler => 'Ruler';

  @override
  String get zoom => 'Zoom';

  @override
  String get actionsMenu => 'Actions menu';

  @override
  String get precision => 'Precision';

  @override
  String get anglePrecision => 'Angle precision';

  @override
  String get editingIncrement => 'Editing increment';

  @override
  String get measurementUnits => 'Measurement units';

  @override
  String get millimeters => 'Millimeters';

  @override
  String get onDrawing => 'On drawing';

  @override
  String get pressKeys => 'Press keys…';

  @override
  String get recordShortcutHint =>
      'Click a shortcut and press its new keys. Esc cancels.';

  @override
  String get rotationInputHint =>
      'Click an arrow to rotate 90° or enter an angle';

  @override
  String get partName => 'Part name';

  @override
  String get groupName => 'Group name';

  @override
  String get nameAndDimensions => 'Name and dimensions…';

  @override
  String get projectName => 'Project name';

  @override
  String get assign => 'Assign';

  @override
  String searchMatches(Object found, Object total) {
    return 'Showing $found of $total';
  }

  @override
  String get findAPart => 'Find a part';

  @override
  String get tiltInAVerticalPlane => 'Tilt in a vertical plane';

  @override
  String get direction => 'Direction';

  @override
  String get settings => 'Settings';

  @override
  String get projectSettings => 'Project settings';

  @override
  String get projectSettingsMenu => 'Project settings…';

  @override
  String get start => 'Start';

  @override
  String get startCut => 'Start cut';

  @override
  String get discardChanges => 'Don’t save';

  @override
  String get draftSaveError => 'Could not save the draft';

  @override
  String get updateProjectError => 'Could not update the file. Use “Save as…”.';

  @override
  String get draftOpenError => 'Could not open the local draft';

  @override
  String get openProjectError => 'Could not open the project file';

  @override
  String get gridSaveError => 'Could not save grid visibility';

  @override
  String get settingsSaveError => 'Could not save settings';

  @override
  String get saveProjectError => 'Could not save the project. Use “Save as…”.';

  @override
  String get snapSaveError => 'Could not save the snapping mode';

  @override
  String get workbookSaveError => 'Could not save the Excel file. Try again.';

  @override
  String get unknownProjectFormat => 'Unknown project format';

  @override
  String get invalidPartGeometry => 'Invalid part geometry';

  @override
  String get invalidFace => 'Invalid face';

  @override
  String get invalidVector => 'Invalid vector';

  @override
  String get invalidWorkspaceDimensions => 'Invalid workspace dimensions';

  @override
  String get invalidEndCut => 'Invalid end cut';

  @override
  String get invalidCorner => 'Invalid corner';

  @override
  String get noOverlappingProjection => 'No overlapping projection';

  @override
  String get noOpenProjects => 'No open projects';

  @override
  String get lower => 'Lower';

  @override
  String get cubeBottom => 'Bottom';

  @override
  String get newPart => 'New part';

  @override
  String get newDimension => 'New dimension';

  @override
  String get centerCamera => 'Center view';

  @override
  String get renameDimension => 'Rename dimension';

  @override
  String selectDimensionHint(String shortcut) {
    return 'Select a dimension on the drawing or press $shortcut to add one';
  }

  @override
  String get newPartWithDimensions => 'New part by dimensions';

  @override
  String get choosePartPosition => 'Choose position';

  @override
  String get placePartHint => 'Click to place the part. Press Esc to cancel.';

  @override
  String get hiddenParts => 'Hidden parts';

  @override
  String get hideCompletely => 'Hide completely';

  @override
  String get showOutlines => 'Show outlines';

  @override
  String get hidePart => 'Hide part';

  @override
  String get hideGroupParts => 'Hide all parts in group';

  @override
  String get showGroupParts => 'Show all parts in group';

  @override
  String get hideSelectedParts => 'Hide selected parts';

  @override
  String get showPart => 'Show part';

  @override
  String get showAllParts => 'Show all hidden parts';

  @override
  String newPartShortcut(Object shortcut) {
    return 'New part · $shortcut';
  }

  @override
  String get newPartHere => 'New part here';

  @override
  String get newProject => 'New project';

  @override
  String leg(Object number) {
    return 'Leg $number';
  }

  @override
  String get referencesAreNeededOnBothSides =>
      'References are needed on both sides';

  @override
  String get reverseDirection => 'Reverse direction';

  @override
  String get anchor => 'Anchor';

  @override
  String anchorLabel(Object mode) {
    return 'Anchor · $mode';
  }

  @override
  String get referencePart => 'Reference part';

  @override
  String get partAxes => 'Part axes';

  @override
  String get projectAxes => 'Project axes';

  @override
  String axis(Object axis) {
    return 'Axis $axis';
  }

  @override
  String get zoomOut => 'Zoom out';

  @override
  String get open => 'Open';

  @override
  String get newTab => 'New tab';

  @override
  String get recentProjects => 'Recent projects';

  @override
  String get noRecentProjects => 'No recent projects yet';

  @override
  String get openProject => 'Open project';

  @override
  String get openProjectMenu => 'Open project…';

  @override
  String get cancel => 'Cancel';

  @override
  String get undo => 'Undo';

  @override
  String get undoAction => 'Undo action';

  @override
  String get offset => 'Offset';

  @override
  String referenceEdgeOffset(Object edge) {
    return 'Offset from the $edge of the reference';
  }

  @override
  String get clearSearch => 'Clear search';

  @override
  String get rightClick => 'Right click';

  @override
  String get moveResizeHint =>
      'Drag a part to move it. Shift-drag an edge to resize it.';

  @override
  String get cubeFront => 'Front';

  @override
  String get frontFacing => 'Front-facing';

  @override
  String get frontEdge => 'Front edge';

  @override
  String get renamePart => 'Rename part';

  @override
  String get renameGroup => 'Rename group';

  @override
  String get rename => 'Rename…';

  @override
  String moveShortcut(Object shortcut) {
    return 'Move · $shortcut';
  }

  @override
  String anchorShortcut(Object shortcut) {
    return 'Place against reference · $shortcut';
  }

  @override
  String get movementAndRuler => 'Movement and ruler';

  @override
  String get movementAndResizing => 'Movement and resizing';

  @override
  String get intersection => 'Intersection';

  @override
  String get intersections => 'Intersections';

  @override
  String intersectionsLabel(Object count) {
    return 'Intersections · $count';
  }

  @override
  String get perspective => 'Perspective';

  @override
  String seatSlat(Object number) {
    return 'Seat slat $number';
  }

  @override
  String get plane => 'Plane';

  @override
  String get buildInThisPlane => 'Build in this plane';

  @override
  String get edgeAligned => 'Edge aligned';

  @override
  String get byAxes => 'By axes';

  @override
  String get alongThickness => 'Along thickness';

  @override
  String get alongWidth => 'Along width';

  @override
  String get rotate => 'Rotate';

  @override
  String get orbitView => 'Orbit view';

  @override
  String get rotatePart => 'Rotate part';

  @override
  String get rotateMenu => 'Rotate…';

  @override
  String get rotation => 'Rotation';

  @override
  String rotateShortcut(Object shortcut) {
    return 'Rotate · $shortcut';
  }

  @override
  String get brokenPartReferences => 'Broken part references';

  @override
  String get redo => 'Redo';

  @override
  String get redoAction => 'Redo action';

  @override
  String get showHideDimensions => 'Show / hide dimensions';

  @override
  String get showDimensions => 'Show dimensions';

  @override
  String get floor => 'Floor';

  @override
  String get partOffsets => 'Offsets';

  @override
  String get xFromLeft => 'X · from left';

  @override
  String get yFromBack => 'Y · from wall';

  @override
  String get zFromFloor => 'Z · from floor';

  @override
  String crossRail(Object number) {
    return 'Cross rail $number';
  }

  @override
  String get placeAgainstReference => 'Place against reference';

  @override
  String get cubeRight => 'Right';

  @override
  String get rightHand => 'Right-hand';

  @override
  String get multiSelectionMenuHint =>
      'Right-click the selection for actions on all selected parts';

  @override
  String get continuousDragHint =>
      'Dragging moves and resizes parts continuously.';

  @override
  String get zoomIn => 'Zoom in';

  @override
  String rulerSnapModifier(Object modifier) {
    return 'Ruler snapping without $modifier';
  }

  @override
  String get snapLabel => 'Snap';

  @override
  String get snapToAnchors => 'Snap to anchors';

  @override
  String get apply => 'Apply';

  @override
  String get spaceLeftClick => 'Space + left click';

  @override
  String get checkTheExpression => 'Check the expression';

  @override
  String sideRail(Object number) {
    return 'Side rail $number';
  }

  @override
  String get project => 'Project';

  @override
  String get neprostoProject => 'NeProSto project';

  @override
  String get projectSaved => 'Project saved';

  @override
  String get clearance => 'Clearance';

  @override
  String clearanceLabel(Object distance, Object unit) {
    return 'Clearance · $distance $unit';
  }

  @override
  String get square => 'Square';

  @override
  String get drawingControls => 'Drawing controls';

  @override
  String get workPlane => 'Work plane';

  @override
  String workPlaneLabel(Object plane) {
    return 'Work plane · $plane';
  }

  @override
  String equalGapValue(Object distance, Object unit) {
    return 'Equal gaps · $distance $unit';
  }

  @override
  String get unlock => 'Unlock';

  @override
  String get ungroup => 'Ungroup';

  @override
  String get dimension => 'Dimension';

  @override
  String get dimensionLocked => 'Dimension locked';

  @override
  String dimensionTabCount(Object count) {
    return 'Dimensions  $count';
  }

  @override
  String get partDimensions => 'Part dimensions';

  @override
  String get dimensionsOnDrawing => 'Dimensions on drawing';

  @override
  String get endMarkings => 'End markings';

  @override
  String get stretchToHeight => 'Stretch to height';

  @override
  String get stretchToWidth => 'Stretch to width';

  @override
  String get editing => 'Editing';

  @override
  String get modeWithoutModifierKeys => 'Mode without modifier keys';

  @override
  String get snapping => 'Snapping';

  @override
  String get centimeters => 'Centimeters';

  @override
  String get resetShortcuts => 'Reset shortcuts';

  @override
  String get viewTop => 'Top';

  @override
  String get free => 'Free';

  @override
  String get freeView => 'Free view';

  @override
  String get properties => 'Properties';

  @override
  String get groupLabel => 'Group';

  @override
  String get nudge => 'Nudge';

  @override
  String nudgeDistance(Object distance, Object unit) {
    return 'Move · $distance $unit';
  }

  @override
  String get panView => 'Pan view';

  @override
  String get center => 'Center';

  @override
  String get edgeMidpoint => 'Edge midpoint';

  @override
  String get rulerEdge => 'Edge';

  @override
  String get rulerUpperEdge => 'Upper edge';

  @override
  String get rulerLowerEdge => 'Lower edge';

  @override
  String get rulerCenterline => 'Face centerline';

  @override
  String get viewBack => 'Back';

  @override
  String get bench => 'Bench';

  @override
  String get downloadStarted => 'Download started';

  @override
  String get hideDimensions => 'Hide dimensions';

  @override
  String get viewLeft => 'Left';

  @override
  String get partDimensionIsTooSmall => 'Part dimension is too small';

  @override
  String changeShortcutFor(Object command) {
    return 'Change shortcut for “$command”';
  }

  @override
  String get viewBottom => 'Bottom';

  @override
  String get join => 'Join';

  @override
  String get saving => 'Saving';

  @override
  String get save => 'Save';

  @override
  String get saveChanges => 'Save changes?';

  @override
  String get saveAs => 'Save as…';

  @override
  String get saveProject => 'Save project';

  @override
  String get saveProjectsAutomatically => 'Save projects automatically';

  @override
  String get viewFront => 'Front';

  @override
  String get partsList => 'Parts list';

  @override
  String get viewRight => 'Right';

  @override
  String stepExample(
    Object step,
    Object unit,
    Object examples,
    Object exampleUnit,
  ) {
    return 'The arrow moves the part by $step $unit. Resizing uses steps such as $examples $exampleUnit.';
  }

  @override
  String get straightUpAlongZ => 'Straight up along Z';

  @override
  String get thicknessInitial => 'T';

  @override
  String get thickness => 'Thickness';

  @override
  String thicknessLabel(Object unit) {
    return 'Thickness, $unit';
  }

  @override
  String onlyWith(Object modifier) {
    return 'Only with $modifier';
  }

  @override
  String get ends => 'Ends';

  @override
  String get dragWithRightButton => 'Drag with right button';

  @override
  String get removeBounds => 'Remove bounds';

  @override
  String get miterJoint => 'Miter joint';

  @override
  String get miterJointMenu => 'Miter joint…';

  @override
  String get jointEndToEnd => 'End to end';

  @override
  String get jointEndToFace => 'End to face';

  @override
  String get jointChooseFace => 'Choose face';

  @override
  String get jointNeedsOverlap =>
      'Position the selected parts so they overlap at the joint.';

  @override
  String get jointNoAvailableCut =>
      'A through cut is unavailable here. Check the overlap and whether the parts’ lengths are locked.';

  @override
  String get jointBottomFace => 'Bottom face';

  @override
  String get jointTopFace => 'Top face';

  @override
  String get jointCutLine => 'Cut line';

  @override
  String get jointOffcut => 'Offcut';

  @override
  String get jointApplyCut => 'Trim';

  @override
  String get jointNoCommonCut =>
      'The selected ends cannot meet on one plane. Check the ends and part positions.';

  @override
  String get jointCutOutsideStock =>
      'The cut line extends beyond the end of the stock. Check how far the parts overlap.';

  @override
  String get jointNoFaceCut =>
      'No support face gives a through cut on this part. Check the part positions.';

  @override
  String get corner => 'Corner';

  @override
  String get delete => 'Delete';

  @override
  String get deleteDimension => 'Delete dimension';

  @override
  String holdToSnap(Object modifier) {
    return 'Hold $modifier to snap.';
  }

  @override
  String freeMovementHint(Object modifier) {
    return 'Hold $modifier to temporarily disable snapping.';
  }

  @override
  String holdDimensionModifier(Object modifier, Object action) {
    return 'Hold $modifier to $action dimensions.';
  }

  @override
  String hold(Object modifier) {
    return 'Hold $modifier';
  }

  @override
  String alreadyAssignedTo(Object command) {
    return 'Already assigned to “$command”';
  }

  @override
  String get setTheSecondDimensionPoint => 'Set the second dimension point';

  @override
  String get setTheSourceAnchorOnThePart =>
      '1 of 2. Click the starting point on the part you want to move.';

  @override
  String get setTheEndOfThePart => 'Set the end of the part';

  @override
  String get setTheStartOfThePart => 'Set the start of the part';

  @override
  String get setTheDestinationAnchor =>
      '2 of 2. Click where you want to place that point.';

  @override
  String get setTheFirstDimensionPoint => 'Set the first dimension point';

  @override
  String get pickReferenceOnDrawing => 'Pick reference on drawing';

  @override
  String stop(Object part) {
    return 'Stop · $part';
  }

  @override
  String get excelFileSaved => 'Excel file saved';

  @override
  String get frontPlane => 'Front';

  @override
  String get rearPlane => 'Rear';

  @override
  String get centerPoint => 'Center';

  @override
  String get faceCenter => 'Face center';

  @override
  String get partCenter => 'Part center';

  @override
  String get brusDrafts => 'Brus drafts';

  @override
  String get browserDraftsHint =>
      'Drafts of open tabs are saved in this browser.';

  @override
  String get drawing => 'Drawing';

  @override
  String addPartHint(Object shortcut) {
    return 'Press $shortcut to add a part';
  }

  @override
  String get widthInitial => 'W';

  @override
  String step(Object increment) {
    return 'Step $increment';
  }

  @override
  String get width => 'Width';

  @override
  String widthLabel(Object unit) {
    return 'Width, $unit';
  }

  @override
  String get clickAReferenceInTheDrawingOr =>
      'Click a reference in the drawing or select one from the list.';

  @override
  String get clickTheReferencePart => 'Click the reference part';

  @override
  String get exportToExcel => 'Export to Excel';

  @override
  String get reservedShortcut =>
      'This shortcut is reserved by the system. Choose another.';

  @override
  String get fileAlreadyOpen => 'This file is open in another tab';

  @override
  String get off => 'off';

  @override
  String get leftReferenceEdge => 'left edge';

  @override
  String get mm => 'mm';

  @override
  String get bottomReferenceEdge => 'bottom edge';

  @override
  String get frontReferenceEdge => 'front edge';

  @override
  String get show => 'show';

  @override
  String get hide => 'hide';

  @override
  String get cm => 'cm';

  @override
  String get negativeThickness => '−T';

  @override
  String get negativeWidth => '−W';

  @override
  String get close => 'Close';

  @override
  String get appearance => 'Appearance';

  @override
  String get theme => 'Theme';

  @override
  String get light => 'Light';

  @override
  String get dark => 'Dark';

  @override
  String get language => 'Language';

  @override
  String get aboutNeprosto => 'About NeProSto';

  @override
  String get fileMenu => 'File';

  @override
  String get settingsMenu => 'Settings…';

  @override
  String get services => 'Services';

  @override
  String get hideNeprosto => 'Hide NeProSto';

  @override
  String get hideOthers => 'Hide Others';

  @override
  String get showAll => 'Show All';

  @override
  String get quitNeprosto => 'Quit NeProSto';

  @override
  String get edit => 'Edit';

  @override
  String get cut => 'Cut';

  @override
  String get copy => 'Copy';

  @override
  String get paste => 'Paste';

  @override
  String get pasteAndMatchStyle => 'Paste and Match Style';

  @override
  String get selectAll => 'Select All';

  @override
  String get find => 'Find';

  @override
  String get findMenu => 'Find…';

  @override
  String get findAndReplace => 'Find and Replace…';

  @override
  String get findNext => 'Find Next';

  @override
  String get findPrevious => 'Find Previous';

  @override
  String get useSelectionForFind => 'Use Selection for Find';

  @override
  String get jumpToSelection => 'Jump to Selection';

  @override
  String get spellingAndGrammar => 'Spelling and Grammar';

  @override
  String get showSpellingAndGrammar => 'Show Spelling and Grammar';

  @override
  String get checkDocumentNow => 'Check Document Now';

  @override
  String get checkSpellingWhileTyping => 'Check Spelling While Typing';

  @override
  String get checkGrammarWithSpelling => 'Check Grammar With Spelling';

  @override
  String get correctSpellingAutomatically => 'Correct Spelling Automatically';

  @override
  String get substitutions => 'Substitutions';

  @override
  String get showSubstitutions => 'Show Substitutions';

  @override
  String get smartCopyPaste => 'Smart Copy/Paste';

  @override
  String get smartQuotes => 'Smart Quotes';

  @override
  String get smartDashes => 'Smart Dashes';

  @override
  String get smartLinks => 'Smart Links';

  @override
  String get dataDetectors => 'Data Detectors';

  @override
  String get textReplacement => 'Text Replacement';

  @override
  String get transformations => 'Transformations';

  @override
  String get makeUpperCase => 'Make Upper Case';

  @override
  String get makeLowerCase => 'Make Lower Case';

  @override
  String get capitalize => 'Capitalize';

  @override
  String get speech => 'Speech';

  @override
  String get startSpeaking => 'Start Speaking';

  @override
  String get stopSpeaking => 'Stop Speaking';

  @override
  String get enterFullScreen => 'Enter Full Screen';

  @override
  String get window => 'Window';

  @override
  String get minimize => 'Minimize';

  @override
  String get zoomLabel => 'Zoom';

  @override
  String get bringAllToFront => 'Bring All to Front';

  @override
  String get help => 'Help';

  @override
  String get blankProject => 'Blank project';

  @override
  String get createProject => 'Create project';

  @override
  String get createProjectFromTemplate => 'Create project from template…';

  @override
  String get plywood => 'Plywood';

  @override
  String get mdf => 'MDF';

  @override
  String get stockShopping => 'Shopping list';

  @override
  String stockOffcut(String size) {
    return 'An offcut of $size will fit';
  }

  @override
  String stockKerf(String size) {
    return 'Saw kerf $size · actual stock sizes';
  }

  @override
  String get stockBoard => 'Board';

  @override
  String get stockBar => 'Square timber';

  @override
  String get stockSheet => 'Sheet';

  @override
  String get shelfPart => 'Shelf';

  @override
  String get sidePanel => 'Side panel';

  @override
  String get topPanel => 'Top panel';

  @override
  String get bottomPanel => 'Bottom';

  @override
  String get dividerPanel => 'Divider';

  @override
  String get backPanel => 'Back panel';

  @override
  String get frontPanel => 'Front panel';

  @override
  String get doorPanel => 'Door';

  @override
  String get tabletop => 'Tabletop';

  @override
  String get seatPanel => 'Seat';

  @override
  String get tread => 'Tread';

  @override
  String get carryHandle => 'Handle';

  @override
  String get categoryShelving => 'Shelving';

  @override
  String get categorySeating => 'Stools and benches';

  @override
  String get categoryTables => 'Tables';

  @override
  String get categoryCabinets => 'Cabinets';

  @override
  String get categoryWorkshop => 'Workshop and office';

  @override
  String get templateBookcase => 'Four-tier timber shelving';

  @override
  String get templateCubeShelf => 'Staircase room divider';

  @override
  String get templateWallShelf => 'Floating box shelf';

  @override
  String get templateStool => 'Guitarist’s stool and stand';

  @override
  String get templateStepStool => 'Two-step stool';

  @override
  String get templateGardenBench => 'Garden bench with armrests';

  @override
  String get templateDiningTable => 'Trestle dining table';

  @override
  String get templateWritingDesk => 'Writing desk with side shelves';

  @override
  String get templateBedsideCabinet => 'Bedside cabinet with cubby';

  @override
  String get templateBedroomWardrobe => 'Three-door bedroom wardrobe';

  @override
  String get openDoor => 'Open door';

  @override
  String get closeDoor => 'Close door';

  @override
  String get panelHoles => 'Holes';

  @override
  String holeSelection(int number, int count) {
    return 'Hole $number of $count';
  }

  @override
  String get holeReferenceCorner => 'Offsets from corner';

  @override
  String get drillingType => 'Hole type';

  @override
  String get drillingFace => 'Drilling face';

  @override
  String get noPanelHoles => 'This part has no holes yet';

  @override
  String get addHole => 'Add hole';

  @override
  String get holeName => 'Hole name';

  @override
  String get showHoleNumbers => 'Show numbers on the diagram';

  @override
  String holeDepthRange(String limit) {
    return 'Depth must be greater than zero and less than the part thickness ($limit).';
  }

  @override
  String holeDiameterRange(String limit) {
    return 'Diameter must be greater than zero and at most $limit.';
  }

  @override
  String holeOffsetRange(String minimum, String maximum) {
    return 'The edge distance must be between $minimum and $maximum.';
  }

  @override
  String get holeDiameter => 'Diameter';

  @override
  String get throughHole => 'Through';

  @override
  String get blindHole => 'Blind';

  @override
  String get faceA => 'Face A';

  @override
  String get faceB => 'Face B';

  @override
  String get edgeBoringCommand => 'Bore along edge…';

  @override
  String get chooseBoringEdge => 'Select a panel edge';

  @override
  String get edgeBoringTitle => 'Bore along edge';

  @override
  String get boltBoreOption => 'Edge bore';

  @override
  String get boltFaceOffset => 'Axis from face';

  @override
  String get boltBoreDepth => 'Edge bore depth';

  @override
  String get boltBoreInvalid =>
      'Set the diameter and axis offset so the bit fits within the edge and its axis enters the face bore.';

  @override
  String get drillingParameters => 'Drilling settings';

  @override
  String get boringReferenceEdge => 'Reference edge';

  @override
  String get boltReferenceFace => 'Reference face';

  @override
  String get boreCenterDistance => 'To centre';

  @override
  String get boreRimDistance => 'To hole rim';

  @override
  String boreCenterPitch(String length) {
    return 'Centre-to-centre spacing · $length';
  }

  @override
  String get boreCount => 'Number of holes';

  @override
  String get boreOutsidePanel =>
      'Set the edge distance so the hole fits on the panel.';

  @override
  String get enterBoreCount => 'Enter a whole number of holes, at least 1.';

  @override
  String get boreEndOffsets => 'End distances to hole centres';

  @override
  String get boreEndMarginsInvalid =>
      'Set the end distances so each hole fits on the panel.';

  @override
  String get boreSpacingInvalid =>
      'There is too little space for this count and these end distances.';

  @override
  String get boreCollision =>
      'A new hole overlaps an existing hole. Adjust the offsets or the count.';

  @override
  String get addBoreRow => 'Add holes';

  @override
  String get fromLeft => 'From left edge';

  @override
  String get fromRight => 'From right edge';

  @override
  String get fromBottom => 'From bottom edge';

  @override
  String get fromTop => 'From top edge';

  @override
  String get invalidHole =>
      'Check the diameter and edge distances. A blind hole must be shallower than the part thickness.';

  @override
  String get ordinaryPart => 'Element';

  @override
  String get chestLid => 'Lid';

  @override
  String get groupType => 'Group type';

  @override
  String get groupProperties => 'Group properties';

  @override
  String get partProperties => 'Part properties';

  @override
  String get bazisExport => 'For BAZIS Cutting';

  @override
  String get partType => 'Part type';

  @override
  String get forwardDirection => 'Forward';

  @override
  String get towardViewer => 'Toward you';

  @override
  String get awayFromViewer => 'Away from you';

  @override
  String get liftUpDoor => 'Lift-up door · top hinges';

  @override
  String get dropDownDoor => 'Drop-down door · bottom hinges';

  @override
  String get hingesLeft => 'Hinges on the left';

  @override
  String get hingesRight => 'Hinges on the right';

  @override
  String get hingesTop => 'Hinges at the top';

  @override
  String get hingesBottom => 'Hinges at the bottom';

  @override
  String get chooseHingeEdge => 'Select an edge of the door';

  @override
  String get doorAngle => 'Opening angle';

  @override
  String get leftHingedDoor => 'Left-hinged door';

  @override
  String get rightHingedDoor => 'Right-hinged door';

  @override
  String get clothesRail => 'Clothes rail';

  @override
  String get templateTvStand => 'Media console';

  @override
  String get templateWorkbench => 'Split-top Roubo workbench';

  @override
  String get templateToolTote => 'Diagonal-handle tool tote';

  @override
  String get cuttingLayout => 'Cutting layout';

  @override
  String get categoryGarden => 'Garden and patio';

  @override
  String get templateDrawerChest => 'Four-drawer dresser';

  @override
  String get drawerFront => 'Drawer front';

  @override
  String get planterWall => 'Wall board';

  @override
  String get uprightPost => 'Post';

  @override
  String get deckBoard => 'Deck board';

  @override
  String get frameRail => 'Frame rail';

  @override
  String get trellisSlat => 'Trellis slat';

  @override
  String get benchBack => 'Backrest slat';

  @override
  String get landingRail => 'Handrail';

  @override
  String get roofBoard => 'Roof board';

  @override
  String get rackFinger => 'Clamp support';

  @override
  String get templatePicnicTable => 'Children’s picnic table';

  @override
  String get templateSawhorse => 'Trestle sawhorse';

  @override
  String get templateClampRack => 'Wall-mounted clamp rack';

  @override
  String get templateRaisedBed => 'Raised bed with a mitred cap';

  @override
  String get templateStandingPlanter => 'Planter on legs';

  @override
  String get templateTrellisPlanter => 'Trellis planter';

  @override
  String get templatePorch => 'Entry porch with landing and rail';

  @override
  String get templateChaise => 'Slatted chaise longue';

  @override
  String get templatePottingBench => 'Potting bench with tray recess';

  @override
  String get templateLogStore => 'Lean-to firewood shelter';

  @override
  String get categoryConstruction => 'Joinery and framing';

  @override
  String get floorJoist => 'Floor joist';

  @override
  String get bridging => 'Diagonal bridging';

  @override
  String get headerBeam => 'Window header';

  @override
  String get windowSill => 'Rough sill';

  @override
  String get roofRafter => 'Rafter';

  @override
  String get ridgeBeam => 'Ridge beam';

  @override
  String get doorStile => 'Door stile';

  @override
  String get doorPanelInfill => 'Panel board';

  @override
  String get gatePicket => 'Picket';

  @override
  String get framingNote =>
      'Joists and bridging are shown before decking. Design bearings, span, timber grade, decking and connections for local loads.';

  @override
  String get roofNote =>
      'Site-specific design is required for footings, anchors, roofing and joints based on soil, snow, wind and seismic loads.';

  @override
  String get porchNote =>
      'Match the landing to the threshold and door swing. Verify foundations, stairs, guards and connections to local requirements before building.';

  @override
  String get doorNote =>
      'Door leaf only. Size frame, installation clearances and hinges for the opening and leaf weight.';

  @override
  String get gateNote =>
      'Hinge on the left when viewed from the brace side. The brace transfers load from the upper latch corner to the lower hinge rail.';

  @override
  String get templateShedFloor => 'Cabin floor with herringbone bridging';

  @override
  String get templateWindowWall => 'Wall frame with window opening';

  @override
  String get templateCornerWalls => 'Two-wall framing corner';

  @override
  String get templatePanelDoor => 'Frame-and-panel interior door';

  @override
  String get templateGardenGate => 'Braced picket gate';

  @override
  String get wallFrameNote =>
      'Studwork is shown before sheathing. Design studs, headers, bracing or structural sheathing and wall anchorage for local loads.';

  @override
  String get templateSignatureCabinet => 'NeProSto signature cabinet';

  @override
  String get signatureDoor => 'Door with finger pull';

  @override
  String get endCutsTitle => 'End cuts';

  @override
  String get faceMarkAngle => 'Mark across width';

  @override
  String get edgeMarkAngle => 'Mark across thickness';

  @override
  String cutOffsetReadout(String distance) {
    return 'Offset $distance';
  }

  @override
  String get mitreSaw => 'Mitre saw';

  @override
  String get handheldSaw => 'Handheld circular saw';

  @override
  String get tableSaw => 'Table saw';

  @override
  String get sawCutLine => 'Cut line';

  @override
  String get sawFeed => 'Feed';

  @override
  String get sawCrosscutFence => 'Miter gauge';

  @override
  String get sawTableSight => 'Cutaway';

  @override
  String get sawFeedView => 'Infeed view';

  @override
  String sawFenceNear(String angle) {
    return '$angle° · right end toward you';
  }

  @override
  String sawFenceFar(String angle) {
    return '$angle° · right end away';
  }

  @override
  String get sawStockPosition => 'Stock flat, start on the left';

  @override
  String get sawTableRotation => 'Table rotation';

  @override
  String get sawBladeTilt => 'Blade tilt';

  @override
  String sawAngleLeft(String angle) {
    return '$angle° left';
  }

  @override
  String sawAngleRight(String angle) {
    return '$angle° right';
  }

  @override
  String get resetEndCut => 'Reset angles';

  @override
  String get cutsIntersect =>
      'The cuts cross or leave an edge too short. Reduce the angle at one end.';

  @override
  String angleToLongEdge(String angle) {
    return 'To the long edge $angle°';
  }

  @override
  String get rabbetTitle => 'Rabbet cutting';

  @override
  String get rabbetTopLeft => 'Upper left';

  @override
  String get rabbetTopRight => 'Upper right';

  @override
  String get rabbetBottomLeft => 'Lower left';

  @override
  String get rabbetBottomRight => 'Lower right';

  @override
  String get rabbetDepth => 'Depth';

  @override
  String get rabbetView => 'End view. Select a lengthwise edge.';

  @override
  String get rabbetRemove => 'Remove rabbet';

  @override
  String get invalidRabbet =>
      'Enter a positive width and depth. Leave material between rabbets and before the opposite face.';

  @override
  String get templateLaptopTray => 'Laptop tray';

  @override
  String get templateBagShelf => 'Bag rack with shelf';

  @override
  String get templatePantryShelf => 'Behind-door pantry rack';

  @override
  String get templateConsoleTable => 'Three-bay sofa console';

  @override
  String get templateMachineStand => 'Miter saw stand';

  @override
  String get templateTrestleBench => 'Splayed-leg bench';

  @override
  String get templateWindowBox => 'Window flower box';

  @override
  String get templateBirdhouse => 'A-frame bird shelter';

  @override
  String get templateCandleShelf => 'Candle shelf with triangular trim';

  @override
  String get templateBlanketLadder => 'Leaning towel ladder';

  @override
  String get templateHeadphoneStand => 'Headphone stand';

  @override
  String get templatePlantPanel => 'Wall panel for plants';

  @override
  String get templateToyChest => 'Slatted toy chest';

  @override
  String get templateShutters => 'Three-panel folding shutters';

  @override
  String get templateLantern => 'Terrace lantern';

  @override
  String get templateMirrorFrame => 'Floor mirror frame';

  @override
  String get templateHexShelf => 'Honeycomb shelf';

  @override
  String get templateCoffeeTable => 'Coffee table with lower shelf';

  @override
  String get templateShoeBench => 'Three-cubby shoe bench';

  @override
  String get templateTrivet => 'Lattice trivet';

  @override
  String get categoryHousehold => 'Home accessories';

  @override
  String get planEasy => 'Easy';

  @override
  String get planMedium => 'Intermediate';

  @override
  String get planAdvanced => 'Advanced';

  @override
  String get planSource => 'Original photos and plan';

  @override
  String get planDrawing => 'Original drawing (ZIP)';

  @override
  String get planAdaptation =>
      'Adapted for the editor. The cutting list covers wooden parts.';

  @override
  String get planHardwareHooks => 'Allow for three hooks and wall hangers.';

  @override
  String get planShutterNote =>
      'A 3 mm hinge gap separates each panel. Check the required clearance for your hinges.';

  @override
  String get planLadderNote => 'Decorative blanket rack. Fit a wall restraint.';

  @override
  String get planChestNote =>
      'Fit hinges and a lid stay that holds the lid open.';

  @override
  String get planMirrorNote =>
      'Add a 407 × 1525 mm mirror, mirror fixings and a wall restraint.';

  @override
  String get planRoundedNote =>
      'Rectangular blanks are shown. Round the contact edges during finishing.';

  @override
  String get planTrivetNote =>
      'Adapted from the Craftsmanspace pattern with two crossed layers of 12 × 7 mm strips glued together.';

  @override
  String get roomKitchen => 'Kitchen';

  @override
  String get roomLivingRoom => 'Living room';

  @override
  String get roomBedroom => 'Bedroom';

  @override
  String get roomNursery => 'Children’s room';

  @override
  String get roomEntryway => 'Entryway';

  @override
  String get roomBathroom => 'Bathroom';

  @override
  String get roomOffice => 'Home office';

  @override
  String get templateAssembly => 'Assembly';

  @override
  String get templateHoodCabinet => 'Wall cabinet for a range hood';

  @override
  String get templateSinkBase => 'Sink base cabinet';

  @override
  String get templatePlatformBed => 'Slatted platform bed';

  @override
  String get templateBasinShelf => 'Floating vanity with a trap opening';

  @override
  String get templateFileTrays => 'Three-tier letter tray';

  @override
  String get ductOpening => 'Duct opening';

  @override
  String get chaseSide => 'Duct chase side';

  @override
  String get chaseCover => 'Removable chase cover';

  @override
  String get hangingRail => 'Mounting rail';

  @override
  String get hingeCup => 'Hinge cup';

  @override
  String get plinth => 'Plinth';

  @override
  String get slatLedger => 'Support cleat';

  @override
  String get centerRail => 'Centre beam';

  @override
  String get bedSlat => 'Bed slat';

  @override
  String get shelfWing => 'Shelf wing';

  @override
  String get paperTray => 'Paper tray';

  @override
  String get bedRim => 'Mitred bed cap';

  @override
  String get assembleHoodCabinet =>
      'Use confirmat screws to join the top and bottom to the sides. Fix the shelves between the sides and the duct chase. Screw on its removable cover. The duct passes through two aligned holes. Check opening size, position, mounting points and installation height against your hood’s template. Fit cup hinges and secure the cabinet through its mounting rails.';

  @override
  String get assembleSinkBase =>
      'Join the bottom and top rails to the sides with confirmats. Screw the recessed plinth from the inside. The rails tie the open top beneath the worktop. The rear brace leaves the water and drain connections accessible.';

  @override
  String get assemblePantryShelf =>
      'Screw the shelves between the sides. Fasten the front retaining strips across the front edges of the sides. Anchor the tall, shallow unit to the wall.';

  @override
  String get assembleDiningTable =>
      'Bolt the crosspieces to the legs to make two trestles. Fasten each tabletop board from below to both trestles, keeping the gaps between boards.';

  @override
  String get assembleSignatureCabinet =>
      'Dowel and glue the stepped carcass, then glue on the face strips. The backs keep it square. Hang the door on hinges and use the round through-hole as a finger pull.';

  @override
  String get assembleBookcase =>
      'Screw the crosspieces to the uprights to build the two end frames. Fit the ledgers, then screw each shelf board to both supports. Anchor the top to the wall.';

  @override
  String get assembleCoffeeTable =>
      'Dowel and glue the aprons to the legs. Rest the lower shelf on the cleats between the rails. Secure the plywood top from below with corner brackets.';

  @override
  String get assembleTvStand =>
      'Join the carcass and dividers with confirmats. Fasten the back around its edges and to the dividers. Overlay doors cover the outer bays, with an open bay in the middle.';

  @override
  String get assembleBedroomWardrobe =>
      'Join the top, base and dividers with confirmats. Fit the rails in sockets and fasten the shelves and backs. Mount each door on its indicated hinge edge. Anchor the tall carcass to the wall.';

  @override
  String get assemblePlatformBed =>
      'Join the perimeter rails with knock-down bed fittings. Screw the ledgers to the inside faces. Support the centre beam on its own feet and attach it to the end rails. Secure the slats against sliding across the three supports.';

  @override
  String get assembleDrawerChest =>
      'Assemble the carcass with confirmats. Attach each drawer bottom and back to its sides, then screw on the front from inside. Fit paired runners level, allowing the clearance specified for the hardware. Anchor the carcass to the wall.';

  @override
  String get assembleToyChest =>
      'Glue the paired corner posts. Drive pocket screws from the inside ends of the wall boards and lower rails into the posts. Screw the floorboards to the lower rails and fasten the lid slats from underneath through the battens. Fit a piano hinge along the upper back board and a lid support rated to hold the lid in any position. Keep the ventilation gaps open.';

  @override
  String get assembleCubeShelf =>
      'Start with the continuous base. Assemble the stepped bays from the bottom up with dowels and panel connectors while the shelf ends are accessible. Anchor the unit to the wall.';

  @override
  String get assembleStepStool =>
      'Dowel and glue the plywood sides to the risers. Seat the treads on the supports and fasten with countersunk screws. Both side panels should bear along their full bottom edges.';

  @override
  String get assembleShoeBench =>
      'Build the plinth and set the base on it. Dowel and glue the sides and dividers between the seat and base. Fasten the back around its edges to keep the bench square.';

  @override
  String get assembleConsoleTable =>
      'Connect the sides to the top and base. Dowel the shelves into the dividers as each bay goes together. Provide wall anchoring for the narrow console.';

  @override
  String get assembleMirrorFrame =>
      'Dowel the crossbars into the posts. Assemble the stand-offs, cut their wall ends to the modelled angle and anchor the frame. Fit the mirror with separate glass clips.';

  @override
  String get assembleBasinShelf =>
      'Dowel and glue each front panel to its two wings with water-resistant glue, leaving the trap slot open at the back. Fix the shelves between the sides. Anchor the rails behind the wings to the wall and seal exposed plywood edges.';

  @override
  String get assembleBlanketLadder =>
      'Use two dowels at each end of every rung to prevent rotation. Secure the top to the wall. This ladder is a towel rack.';

  @override
  String get assembleWritingDesk =>
      'The desktop bears on an end panel and a shelving pedestal. Join the panels with confirmats, then secure the rear braces between the supports to resist sideways racking.';

  @override
  String get assembleWallShelf =>
      'Screw the projecting arms to the rear ledger. Anchor the ledger to a suitable wall structure, slide on the plywood shell and secure it to the frame from below.';

  @override
  String get assembleFileTrays =>
      'Glue each pair of cleats level on the sides. Set a plywood tray on each pair and fasten the back panel to keep the sides parallel.';

  @override
  String get assembleWorkbench =>
      'Glue the laminated legs and each slab separately. Bolt the base rails to the legs. Fasten the slabs from below, maintaining the central gap and allowing seasonal movement across the grain.';

  @override
  String get assembleSawhorse =>
      'Cut the splayed legs to the modelled end angles for full contact with the floor and cap. Bolt the aprons to the legs and fasten the lower ties.';

  @override
  String get assembleMachineStand =>
      'Build both end frames and bolt them together with the long rails. Screw the plywood decks down onto the rails. The three-piece lower shelf fits around the legs.';

  @override
  String get assembleRaisedBed =>
      'Screw the wall boards to the corner and centre posts from outside with exterior screws. Tie the centre posts together across the bed. Mitre both ends of all four cap boards at 45° and screw them down to the posts.';

  @override
  String get assembleBench =>
      'Join the long and short aprons to the legs with glued dowels or pocket screws from inside. Space the seat slats evenly and screw them down to the rails.';

  @override
  String get assemblePicnicTable =>
      'Build the two A-frames first. Through-bolt the splayed legs to the crosspieces with washers. Screw the tabletop and seat boards down onto the supports, then fit the longitudinal tie.';

  @override
  String get assembleChaise =>
      'Build the two side frames. Bolt the fixed backrest at its designed angle against the cut supports. Screw the seat and back slats to both sides, leaving drainage gaps.';

  @override
  String get assemblePottingBench =>
      'Screw the rails to the posts using exterior fasteners. Fix the worktop boards to the crosspieces, keeping the insert opening clear. The tall rear posts carry the upper shelf.';

  @override
  String get assembleLogStore =>
      'Tie the posts together with the long rails and fix the floor slats to the crosspieces. Cut the post tops to the roof slope. Space the wall slats to ventilate the firewood.';

  @override
  String get assembleGardenGate =>
      'Fasten the pickets to the two rails. Cut the diagonal brace to bear at both ends, from the upper latch corner down to the lower hinge. Fix the hinges into the rails.';

  @override
  String get assembleBirdhouse =>
      'Bring the mitred roof edges together at the ridge. Drill pilot holes and fasten the end panels and base to the roof boards. Make one end removable for cleaning.';

  @override
  String get assemblePorch =>
      'Assemble the step and landing frames and screw the decking to the crosspieces. Bolt the guard posts to the frame. Cut the handrail to the slope and fix it to the posts. Select anchorage for the installation site.';
}
