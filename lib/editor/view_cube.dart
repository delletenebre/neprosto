import '../l10n/strings.dart';

import 'package:cupertino_ui/cupertino_ui.dart';

import 'palette.dart';
import 'model.dart';
import 'scene.dart';

class ViewCube extends StatefulWidget {
  const ViewCube(this.scene, this.onView, {super.key});
  final Scene scene;
  final ValueChanged<ViewAngle> onView;

  @override
  State<ViewCube> createState() => _ViewCubeState();
}

class _ViewCubeState extends State<ViewCube> {
  ViewAngle? hover;

  @override
  Widget build(BuildContext context) {
    const size = _CubePainter.size;
    final origin = Offset(widget.scene.size.width - size.width - 10, 9);
    final painter = _CubePainter(widget.scene, origin, hover, context.colors);
    return Positioned.fromRect(
      rect: origin & size,
      child: MouseRegion(
        cursor: hover == null ? MouseCursor.defer : SystemMouseCursors.click,
        onHover: (event) {
          final next = painter.faceAt(event.localPosition);
          if (next != hover) setState(() => hover = next);
        },
        onExit: (_) => setState(() => hover = null),
        child: GestureDetector(
          onTapUp: (event) {
            final next = painter.faceAt(event.localPosition);
            if (next != null) widget.onView(next);
          },
          child: CustomPaint(size: size, painter: painter),
        ),
      ),
    );
  }
}

class _CubePainter extends CustomPainter {
  static const size = Size(92, 85);

  final EditorPalette colors;
  late final bool overlapsModel;
  _CubePainter(Scene scene, Offset origin, this.hover, this.colors) {
    final camera = scene.camera;
    final sides = [
      (ViewAngle.left, editorStrings.cubeLeft),
      (ViewAngle.right, editorStrings.cubeRight),
      (ViewAngle.front, editorStrings.cubeFront),
      (ViewAngle.back, editorStrings.cubeBack),
      (ViewAngle.bottom, editorStrings.cubeBottom),
      (ViewAngle.top, editorStrings.cubeTop),
    ];
    final right = camera.right, up = camera.up, eye = camera.eye;
    final corners = [
      for (var i = 0; i < 8; i++)
        Vector3(i.isOdd ? 1 : -1, i & 2 == 0 ? -1 : 1, i & 4 == 0 ? -1 : 1),
    ];
    final screen = [
      for (final point in corners)
        size.center(Offset.zero) +
            Offset(point.dot(right), -point.dot(up)) * 24,
    ];
    final silhouette = Path();
    for (var i = 0; i < sides.length; i++) {
      final facing = eye[i ~/ 2] * (i.isOdd ? 1 : -1);
      if (facing <= .001) continue;
      final points = [for (final vertex in faceCorners[i]) screen[vertex]];
      final path = Path()..addPolygon(points, true);
      silhouette.addPath(path, origin);
      faces.add((
        view: sides[i].$1,
        label: sides[i].$2,
        path: path,
        center: points.reduce((a, b) => a + b) / 4,
        facing: facing,
        fill: (colors.isDark
            ? const [Color(0xff354765), Color(0xff435a7a), Color(0xff516b8d)]
            : const [
                Color(0xffd7e7f2),
                Color(0xffe6eff6),
                Color(0xfff9fcff),
              ])[i ~/ 2],
      ));
    }
    final bounds = silhouette.getBounds();
    overlapsModel = scene.faces.any(
      (face) =>
          face.bounds.overlaps(bounds) &&
          !Path.combine(
            PathOperation.intersect,
            face.path,
            silhouette,
          ).getBounds().isEmpty,
    );
  }

  final ViewAngle? hover;
  final faces =
      <
        ({
          ViewAngle view,
          String label,
          Path path,
          Offset center,
          double facing,
          Color fill,
        })
      >[];

  ViewAngle? faceAt(Offset point) =>
      faces.where((face) => face.path.contains(point)).firstOrNull?.view;

  @override
  bool hitTest(Offset position) => faceAt(position) != null;

  @override
  void paint(Canvas canvas, Size size) {
    final outline = Paint()
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round
      ..color = const Color(0xff7f98aa)
      ..strokeWidth = 1;
    for (final face in faces) {
      final fill = face.view == hover
          ? Color.lerp(face.fill, EditorPalette.highlight, .65)!
          : face.fill;
      canvas.drawPath(
        face.path,
        Paint()..color = overlapsModel ? fill.withValues(alpha: .45) : fill,
      );
      canvas.drawPath(face.path, outline);
      if (face.facing < .32) continue;
      final text = TextPainter(
        text: TextSpan(
          text: face.label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: colors.ink,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      canvas.save();
      canvas.translate(face.center.dx, face.center.dy);
      // Keep lettering upright and wholly inside even foreshortened faces.
      var scale = 1.0;
      while (scale >= .72) {
        final box = Rect.fromCenter(
          center: face.center,
          width: (text.width + 2) * scale,
          height: (text.height + 1) * scale,
        );
        if ([
          box.topLeft,
          box.topRight,
          box.bottomLeft,
          box.bottomRight,
        ].every(face.path.contains)) {
          break;
        }
        scale -= .07;
      }
      if (scale >= .72) {
        canvas.scale(scale);
        text.paint(canvas, Offset(-text.width / 2, -text.height / 2));
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_CubePainter old) => true;
}
