import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'palette.dart';

/// The visible element that launched a dialog. Keep its last bounds if the
/// element is removed while the dialog closes (for example, a project tab).
class DialogSource {
  DialogSource._(this._box, this._localBounds)
    : _bounds = MatrixUtils.transformRect(
        _box.getTransformTo(null),
        _localBounds ?? Offset.zero & _box.size,
      );

  final RenderBox _box;
  final Rect? _localBounds;
  Rect _bounds;

  static DialogSource? of(BuildContext? context, [Rect? localBounds]) {
    if (context == null || !context.mounted || localBounds?.isEmpty == true) {
      return null;
    }
    final box = context.findRenderObject();
    if (box is! RenderBox ||
        !box.attached ||
        !box.hasSize ||
        box.size.isEmpty) {
      return null;
    }
    return DialogSource._(box, localBounds);
  }

  Rect get bounds {
    if (_box.attached && _box.hasSize) {
      final next = MatrixUtils.transformRect(
        _box.getTransformTo(null),
        _localBounds ?? Offset.zero & _box.size,
      );
      if (next.isFinite && !next.isEmpty) _bounds = next;
    }
    return _bounds;
  }

  // Carry the initiating control through callbacks that await a file operation
  // or a native menu before pushing their dialog. Each action has its own scope.
  static DialogSource? get current =>
      Zone.current[DialogSource] as DialogSource?;
  static void invoke(DialogSource? source, VoidCallback action) {
    runZoned(action, zoneValues: {DialogSource: source});
  }
}

class DeskDialogRoute<T> extends RawDialogRoute<T> {
  DeskDialogRoute({
    required this.source,
    required super.pageBuilder,
    required super.barrierDismissible,
    required super.barrierLabel,
    required super.barrierColor,
    required super.transitionDuration,
    super.anchorPoint,
  }) : super(traversalEdgeBehavior: TraversalEdgeBehavior.closedLoop);

  final DialogSource? source;
  final _surface = GlobalKey();

  static Key? surfaceKey(BuildContext context) {
    final route = ModalRoute.of(context);
    return route is DeskDialogRoute ? route._surface : null;
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (transitionDuration == Duration.zero) return child;
    if (source == null) return FadeTransition(opacity: animation, child: child);
    return AnimatedBuilder(
      animation: animation,
      child: child,
      builder: (context, page) => _DialogFlight(
        source: source!,
        surface: _surface,
        color: context.colors.panel,
        progress: Curves.easeInOutCubic.transform(animation.value),
        child: page!,
      ),
    );
  }
}

class _DialogFlight extends SingleChildRenderObjectWidget {
  const _DialogFlight({
    required this.source,
    required this.surface,
    required this.color,
    required this.progress,
    required super.child,
  });

  final DialogSource source;
  final GlobalKey surface;
  final Color color;
  final double progress;

  @override
  _RenderDialogFlight createRenderObject(BuildContext context) =>
      _RenderDialogFlight(this);

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderDialogFlight renderObject,
  ) {
    renderObject.flight = this;
    renderObject.markNeedsPaint();
  }
}

class _RenderDialogFlight extends RenderProxyBox {
  _RenderDialogFlight(this.flight);
  _DialogFlight flight;

  @override
  bool get alwaysNeedsCompositing => true;

  Rect _paintedFrame = Rect.zero;

  @override
  bool hitTestSelf(Offset position) =>
      flight.progress < 1 && _paintedFrame.contains(position);

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      flight.progress == 1 && super.hitTestChildren(result, position: position);

  @override
  void paint(PaintingContext context, Offset offset) {
    final t = flight.progress;
    if (t == 1) {
      super.paint(context, offset);
      return;
    }
    final surface = flight.surface.currentContext?.findRenderObject();
    if (surface is! RenderBox || !surface.hasSize || surface.size.isEmpty) {
      context.pushOpacity(offset, (255 * t).round(), super.paint);
      return;
    }
    final target = MatrixUtils.transformRect(
      surface.getTransformTo(this),
      Offset.zero & surface.size,
    );
    final bounds = flight.source.bounds;
    final source = Rect.fromPoints(
      globalToLocal(bounds.topLeft),
      globalToLocal(bounds.bottomRight),
    );
    final frame = Rect.lerp(source, target, t)!;
    _paintedFrame = frame;
    final outline = RRect.fromRectAndRadius(frame, Radius.circular(6 + 5 * t));
    final reveal = Curves.easeOut.transform((t / .18).clamp(0, 1));
    final shape = Path()..addRRect(outline.shift(offset));
    context.canvas
      ..drawShadow(
        shape,
        const Color(0x44000000).withValues(alpha: .27 * t),
        7 * t,
        false,
      )
      ..drawPath(
        shape,
        Paint()..color = flight.color.withValues(alpha: reveal),
      );
    // The silhouette follows both dimensions, but the contents keep their
    // proportions, even for long, narrow controls and projected parts.
    final opacity = ((t - .12) / .76).clamp(0.0, 1.0);
    if (opacity == 0) return;
    final scale = math.max(
      frame.width / target.width,
      frame.height / target.height,
    );
    final transform = Matrix4.identity()
      ..translateByDouble(frame.center.dx, frame.center.dy, 0, 1)
      ..scaleByDouble(scale, scale, 1, 1)
      ..translateByDouble(-target.center.dx, -target.center.dy, 0, 1);
    context.pushClipRRect(true, offset, frame, outline, (context, offset) {
      context.pushTransform(true, offset, transform, (context, offset) {
        context.pushOpacity(offset, (255 * opacity).round(), super.paint);
      });
    });
  }
}
