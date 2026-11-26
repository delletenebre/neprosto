import 'dart:math' as math;
import 'dart:ui';

import 'part_finish.dart';

Color finishColor(PartFinish finish) => Color(0xff000000 | finish.rgb);

Color? panelCoreColor(PartTexture texture) => switch (texture) {
  PartTexture.laminate || PartTexture.woodLaminate => const Color(0xffbd9d79),
  PartTexture.mdf => finishColor(FinishPreset.mdf.finish),
  PartTexture.plywood => finishColor(FinishPreset.plywood.finish),
  PartTexture.wood ||
  PartTexture.brushedMetal ||
  PartTexture.paintedMetal => null,
};

// Corners run around the face. The edge from a to b follows the stock length.
void paintFinishTexture(
  Canvas canvas,
  PartTexture texture,
  Color base,
  Offset a,
  Offset b,
  Offset c,
  Offset d, {
  int seed = 1,
  bool cutSurface = false,
}) {
  if (texture == PartTexture.paintedMetal || texture == PartTexture.mdf) return;
  final laminated =
      texture == PartTexture.laminate || texture == PartTexture.woodLaminate;
  if (texture == PartTexture.laminate && !cutSurface) return;
  final width = (d - a).distance;
  final length = (b - a).distance;
  if (width < 2 || length < 2) return;

  Offset point(double u, double v) =>
      Offset.lerp(Offset.lerp(a, d, v)!, Offset.lerp(b, c, v)!, u)!;
  if (laminated && cutSurface) {
    // Short irregular flecks on a cut chipboard end.
    final pen = Paint()..strokeWidth = 1.2;
    final random = math.Random(seed);
    final count = (width * length / 17).clamp(3, 140).toInt();
    for (var i = 0; i < count; i++) {
      final u = random.nextDouble(), v = random.nextDouble();
      pen.color = i.isEven ? const Color(0x66704c33) : const Color(0x77f4dbad);
      canvas.drawLine(
        point(u, v),
        point(math.min(1, u + 3 / length), math.min(1, v + 1 / width)),
        pen,
      );
    }
    return;
  }
  final brushed = texture == PartTexture.brushedMetal;
  if (brushed) {
    // Keep the highlight parallel to the stock even on an oblique projection.
    final normal = Offset(a.dy - b.dy, b.dx - a.dx) / length;
    final across = (c + d - a - b) / 2;
    final span = across.dx * normal.dx + across.dy * normal.dy;
    if (span.abs() > 1) {
      canvas.drawPath(
        Path()..addPolygon([a, b, c, d], true),
        Paint()
          ..shader = Gradient.linear(
            a,
            a + normal * span,
            const [Color(0x18000000), Color(0x60ffffff), Color(0x08000000)],
            const [0, .38, 1],
          ),
      );
    }
  }
  final count = (width / (brushed ? 3 : 5)).clamp(2, 28).toInt();
  final contrast = base.computeLuminance() < .10
      ? const Color(0xffffffff)
      : const Color(0xff000000);
  final grain = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = brushed ? .5 : .75
    ..color = contrast.withValues(alpha: brushed ? .13 : .21);
  for (var i = 1; i <= count; i++) {
    final t = (i + math.sin(i * 12.31 + seed * 7.1) * .31) / (count + 1);
    final start = point(0, t), end = point(1, t);
    if (brushed) {
      canvas.drawLine(start, end, grain);
    } else {
      final wave = math.sin(i * 2.1 + seed) * math.min(.045, .8 / count);
      final p = point(.3, t + wave), q = point(.72, t - wave);
      canvas.drawPath(
        Path()
          ..moveTo(start.dx, start.dy)
          ..cubicTo(p.dx, p.dy, q.dx, q.dy, end.dx, end.dy),
        grain,
      );
    }
  }
}
