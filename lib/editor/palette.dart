import 'package:material_ui/material_ui.dart';

import 'platform_ui.dart';

enum EditorPalette {
  light,
  dark;

  bool get isDark => this == dark;
  Brightness get brightness => isDark ? Brightness.dark : Brightness.light;
  Color _surface(int macLight, int macDark, int otherLight, int otherDark) =>
      Color(
        macControls
            ? (isDark ? macDark : macLight)
            : (isDark ? otherDark : otherLight),
      );

  Color get ink => _surface(0xff222224, 0xfff2f2f4, 0xff202b48, 0xffe8f3ff);
  Color get muted => _surface(0xff626268, 0xffb5b5bc, 0xff4c607c, 0xffb5c7dc);
  Color get panel => _surface(0xfff6f6f6, 0xff2b2b2d, 0xfff4f8fc, 0xff293452);
  Color get chrome => _surface(0xffececee, 0xff242426, 0xffe1ecf6, 0xff202a45);
  Color get field => _surface(0xffffffff, 0xff39393c, 0xfffcfdff, 0xff354261);
  Color get line => _surface(0xffd3d3d6, 0xff47474b, 0xffb4c6d8, 0xff546684);
  Color get paper => _surface(0xfffdfdfd, 0xff202022, 0xffedf4fa, 0xff1c243a);
  // Thin strokes need a darker shade of lime on light surfaces.
  Color get accent => macControls
      ? (isDark ? highlight : const Color(0xff646d32))
      : (isDark ? const Color(0xffdcea82) : const Color(0xff405981));
  Color get pale => macControls
      ? Color.lerp(panel, highlight, isDark ? .18 : .36)!
      : (isDark ? const Color(0xff414e48) : const Color(0xffe9efc6));
  Color get danger => _surface(0xffb32627, 0xffff847e, 0xff963f2f, 0xffffb59d);
  Color get disabled =>
      _surface(0xff8e8e93, 0xff848489, 0xff758299, 0xff8899b2);
  static const highlight = Color(0xffdfed87);
  static const onHighlight = Color(0xff242f46);

  Color diagramColor(Color color) =>
      isDark ? Color.lerp(color, const Color(0xffe1edff), .52)! : color;

  Color axisColor(int axis) => diagramColor(
    const [Color(0xffac6957), Color(0xff6b8a56), Color(0xff557f9b)][axis],
  );

  ThemeData materialTheme(String? fontFamily) {
    final scheme =
        ColorScheme.fromSeed(
          seedColor: macControls ? highlight : const Color(0xff42577a),
          brightness: brightness,
        ).copyWith(
          primary: macControls ? highlight : accent,
          onPrimary: macControls || isDark ? onHighlight : Colors.white,
          secondaryContainer: pale,
          onSecondaryContainer: ink,
          surface: panel,
          onSurface: ink,
          onSurfaceVariant: muted,
          outline: line,
          error: danger,
        );
    return ThemeData(
      colorScheme: scheme,
      fontFamily: fontFamily,
      scaffoldBackgroundColor: panel,
      dividerColor: line,
      dividerTheme: DividerThemeData(color: line),
      textTheme: TextTheme(
        bodyMedium: TextStyle(fontSize: 13, color: ink, letterSpacing: 0),
      ),
      inputDecorationTheme: InputDecorationThemeData(
        filled: true,
        fillColor: field,
      ),
    );
  }
}

extension EditorThemeContext on BuildContext {
  Color get selectionFill => Theme.of(this).colorScheme.secondaryContainer;

  EditorPalette get colors => Theme.of(this).brightness == Brightness.dark
      ? EditorPalette.dark
      : EditorPalette.light;
}
