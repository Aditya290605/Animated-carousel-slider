import 'package:flutter/material.dart';

/// Internal wrapper that positions and transforms a child widget within the
/// stacked carousel.
///
/// Applies:
/// - [Positioned] for vertical placement at [y]
/// - [RepaintBoundary] for rendering isolation (performance)
/// - [Transform] with a perspective [Matrix4] for 3D depth effect
///
/// The perspective matrix uses `setEntry(3, 2, 0.0006)` to create a subtle
/// 3D effect where cards further back (lower Z) appear smaller and receded.
class CarouselItemWrapper extends StatelessWidget {
  /// The vertical offset from the top of the Stack.
  final double y;

  /// The uniform scale factor (1.0 = full size).
  final double scale;

  /// The Z-axis translation for depth. Higher values are "closer" to the viewer.
  final double z;

  /// The rotation around the X-axis in radians (for tilt effects).
  final double rotateX;

  /// The child widget to display in this carousel slot.
  final Widget child;

  const CarouselItemWrapper({
    super.key,
    required this.y,
    required this.scale,
    required this.z,
    this.rotateX = 0.0,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    // Build a perspective-aware transformation matrix:
    // 1. setEntry(3,2) adds perspective distortion
    // 2. translate on Z-axis pushes card forward/backward
    // 3. rotateX tilts the card (if non-zero)
    // 4. scale shrinks back-cards for visual depth
    final matrix = Matrix4.identity()
      ..setEntry(3, 2, 0.0006)
      // ignore: deprecated_member_use
      ..translate(0.0, 0.0, z)
      ..rotateX(rotateX)
      // ignore: deprecated_member_use
      ..scale(scale);

    return Positioned(
      top: y,
      left: 0,
      right: 0,
      child: RepaintBoundary(
        child: Transform(
          alignment: Alignment.topCenter,
          transform: matrix,
          child: child,
        ),
      ),
    );
  }
}
