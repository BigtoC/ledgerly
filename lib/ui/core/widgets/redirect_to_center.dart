import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// Sends a press that lands on the child's margin (inside this box but
/// missing every hit target) to the box's centre, as Material buttons do
/// with their padded tap target, so the child's tap target gets it.
class const RedirectToCenter({super.key, required super.child})
    extends SingleChildRenderObjectWidget {
  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderRedirectToCenter();
}

class _RenderRedirectToCenter extends RenderProxyBox {
  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    if (!size.contains(position)) return false;
    if (super.hitTest(result, position: position)) return true;
    final center = size.center(Offset.zero);
    return result.addWithRawTransform(
      transform: MatrixUtils.forceToPoint(center),
      position: center,
      hitTest: (result, _) => child!.hitTest(result, position: center),
    );
  }
}
