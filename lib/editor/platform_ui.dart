import 'package:flutter/foundation.dart';

bool get macControls => defaultTargetPlatform == TargetPlatform.macOS;

bool get appleControls =>
    defaultTargetPlatform == TargetPlatform.macOS ||
    defaultTargetPlatform == TargetPlatform.iOS;

String get primaryModifierLabel => appleControls ? '⌘' : 'Ctrl';
