part of 'hole_dialog.dart';

/// Canvas gestures shared by the orthographic drawing and the spatial view.
/// Primary clicks and drags stay with the editing tool under the pointer.
class _HoleNavigation extends StatefulWidget {
  const _HoleNavigation({
    required this.pan,
    required this.zoom,
    this.beginOrbit,
    this.orbit,
    required this.child,
  });
  final ValueChanged<Offset> pan;
  final void Function(double factor, Offset focus) zoom;
  final ValueChanged<Offset>? beginOrbit, orbit;
  final Widget child;

  @override
  State<_HoleNavigation> createState() => _HoleNavigationState();
}

class _HoleNavigationState extends State<_HoleNavigation> {
  int? pointer;
  bool rotating = false;
  double pinchScale = 1;
  bool get zoomModifier =>
      HardwareKeyboard.instance.isMetaPressed ||
      HardwareKeyboard.instance.isControlPressed;

  @override
  Widget build(BuildContext context) => Listener(
    behavior: HitTestBehavior.opaque,
    onPointerDown: (event) {
      if (event.buttons != kSecondaryMouseButton &&
          event.buttons != kMiddleMouseButton) {
        return;
      }
      pointer = event.pointer;
      rotating = event.buttons == kSecondaryMouseButton && widget.orbit != null;
      if (rotating) widget.beginOrbit?.call(event.localPosition);
    },
    onPointerMove: (event) {
      if (event.pointer != pointer) return;
      (rotating ? widget.orbit! : widget.pan)(event.localDelta);
    },
    onPointerUp: (event) {
      if (event.pointer == pointer) pointer = null;
    },
    onPointerCancel: (event) {
      if (event.pointer == pointer) pointer = null;
    },
    onPointerSignal: (event) {
      if (event is! PointerScrollEvent) return;
      GestureBinding.instance.pointerSignalResolver.register(event, (_) {
        if (zoomModifier) {
          widget.zoom(
            math.exp(-event.scrollDelta.dy.clamp(-400, 400) * .0035),
            event.localPosition,
          );
        } else {
          widget.pan(-event.scrollDelta);
        }
      });
    },
    onPointerPanZoomStart: (event) {
      pinchScale = 1;
      widget.beginOrbit?.call(event.localPosition);
    },
    onPointerPanZoomUpdate: (event) {
      if (zoomModifier) {
        widget.zoom(
          math.exp(event.panDelta.dy.clamp(-400, 400) * .008),
          event.localPosition,
        );
      } else if (HardwareKeyboard.instance.isAltPressed &&
          widget.orbit != null) {
        widget.orbit!(event.panDelta);
      } else {
        widget.pan(event.panDelta);
      }
      if (event.scale != pinchScale) {
        widget.zoom(event.scale / pinchScale, event.localPosition);
        pinchScale = event.scale;
      }
    },
    child: widget.child,
  );
}
