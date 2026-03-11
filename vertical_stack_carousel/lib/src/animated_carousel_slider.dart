import 'package:flutter/material.dart';

import 'carousel_animation.dart';
import 'carousel_controller.dart';
import 'carousel_item.dart';

/// A reusable vertical stacked carousel slider with smooth drag-based
/// animations and a 3D depth effect.
///
/// Displays [items] in a vertical stack with the front card at the top and
/// successive cards appearing stacked behind it with decreasing scale and
/// depth. Users can swipe vertically (up to advance, down to go back) to
/// cycle through items infinitely.
///
/// ## Basic Usage
/// ```dart
/// AnimatedCarouselSlider(
///   items: [
///     Card(child: Center(child: Text("Item 1"))),
///     Card(child: Center(child: Text("Item 2"))),
///     Card(child: Center(child: Text("Item 3"))),
///   ],
/// )
/// ```
///
/// ## Behavior
/// - When there are **3 or more items**, the full carousel with drag gestures
///   and stacking animation is shown.
/// - When there are **2 or fewer items**, items are displayed in a simple
///   vertical [Column] (no carousel behavior).
/// - Supports cyclic/infinite scrolling in both directions.
///
/// ## Customization
/// - [cardHeight]: Controls the height of each card slot.
/// - [animationDuration]: Controls the transition duration.
/// - [stackOffset]: Adjusts the vertical peek offset of stacked cards.
/// - [itemSpacing]: Adjusts the gap between the front card and the second card.
/// - [curve]: Override the default [SpringCurve] with a custom animation curve.
/// - [onIndexChanged]: Callback fired when the active (front) card index changes.
class AnimatedCarouselSlider extends StatefulWidget {
  /// The list of widgets to display in the carousel.
  /// Each widget occupies one card slot.
  final List<Widget> items;

  /// The height of each card in logical pixels. Default: `100.0`.
  final double cardHeight;

  /// Maximum number of cards visible in the carousel.
  /// If null, all items are considered. Must be ≥ 1.
  final int? maxVisibleCards;

  /// Duration of the swipe-to-next/previous animation. Default: `450ms`.
  final Duration animationDuration;

  /// Vertical offset between stacked back-cards. Default: `7.0`.
  final double stackOffset;

  /// Vertical spacing between the front card and the second card. Default: `0.2`.
  final double itemSpacing;

  /// Custom animation curve. If null, uses the built-in [SpringCurve].
  final Curve? curve;

  /// Called when the current (front) card index changes.
  final ValueChanged<int>? onIndexChanged;

  const AnimatedCarouselSlider({
    super.key,
    required this.items,
    this.cardHeight = 100.0,
    this.maxVisibleCards,
    this.animationDuration = const Duration(milliseconds: 450),
    this.stackOffset = 7.0,
    this.itemSpacing = 0.2,
    this.curve,
    this.onIndexChanged,
  });

  @override
  State<AnimatedCarouselSlider> createState() => _AnimatedCarouselSliderState();
}

class _AnimatedCarouselSliderState extends State<AnimatedCarouselSlider>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  int _currentIndex = 0;
  bool _isAnimating = false;
  double _dragOffset = 0;
  bool _isDraggingUp = false;

  late CarouselConfig _config;
  late CarouselSlotConfig _slots;

  // Drag resistance constants
  static const double _dragClamp = 220.0;
  static const double _threshold = 35.0;
  static const double _velocityThreshold = 650.0;

  /// Effective number of cards participating in the carousel cycle.
  int get _effectiveMaxCards {
    if (widget.maxVisibleCards != null && widget.maxVisibleCards! > 0) {
      return widget.maxVisibleCards!.clamp(1, widget.items.length);
    }
    return widget.items.length;
  }

  /// Whether the full carousel should be shown (needs ≥ 3 items).
  bool get _showCarousel => _effectiveMaxCards > 2;

  // ─── Lifecycle ───────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _config = CarouselConfig(
      cardHeight: widget.cardHeight,
      stackOffset: widget.stackOffset,
      cardSpacing: widget.itemSpacing,
    );
    _slots = CarouselSlotConfig.fromConfig(_config);

    _controller = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
    );

    _animation = CurvedAnimation(
      parent: _controller,
      curve: widget.curve ?? const SpringCurve(),
    );
  }

  @override
  void didUpdateWidget(covariant AnimatedCarouselSlider oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Rebuild config if layout parameters changed
    if (oldWidget.cardHeight != widget.cardHeight ||
        oldWidget.stackOffset != widget.stackOffset ||
        oldWidget.itemSpacing != widget.itemSpacing) {
      _config = CarouselConfig(
        cardHeight: widget.cardHeight,
        stackOffset: widget.stackOffset,
        cardSpacing: widget.itemSpacing,
      );
      _slots = CarouselSlotConfig.fromConfig(_config);
    }

    // Rebuild animation if duration or curve changed
    if (oldWidget.animationDuration != widget.animationDuration) {
      _controller.duration = widget.animationDuration;
    }
    if (oldWidget.curve != widget.curve) {
      _animation = CurvedAnimation(
        parent: _controller,
        curve: widget.curve ?? const SpringCurve(),
      );
    }

    // Clamp current index if items list shrank
    if (_currentIndex >= _effectiveMaxCards) {
      _currentIndex = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // ─── Drag Handling ───────────────────────────────────────────────────

  void _onVerticalDragStart(DragStartDetails details) {
    if (_isAnimating || !_showCarousel) return;
    _dragOffset = 0;
  }

  void _onVerticalDragUpdate(DragUpdateDetails details) {
    if (_isAnimating || !_showCarousel) return;

    // Apply progressive resistance as the user drags further
    double resistance = 1.0;
    final absDragOffset = _dragOffset.abs();
    if (absDragOffset > _dragClamp * 0.6) {
      resistance = 0.5;
    } else if (absDragOffset > _dragClamp * 0.3) {
      resistance = 0.75;
    }

    setState(() {
      _dragOffset += details.delta.dy * resistance;
      _dragOffset = _dragOffset.clamp(-_dragClamp, _dragClamp);
    });
  }

  void _onVerticalDragEnd(DragEndDetails details) {
    if (_isAnimating || !_showCarousel) return;

    final velocity = details.velocity.pixelsPerSecond.dy;
    final int len = _effectiveMaxCards;
    final bottomPos = _config.bottomPos;

    // Swipe UP → advance to next
    if (_dragOffset < -_threshold || velocity < -_velocityThreshold) {
      final progressStart = (-_dragOffset / bottomPos).clamp(0.0, 1.0);
      if (progressStart >= 1.0) {
        _setIndex((_currentIndex + 1) % len);
      } else {
        _animateToNext(progressStart);
      }
    }
    // Swipe DOWN → go to previous
    else if (_dragOffset > _threshold || velocity > _velocityThreshold) {
      final progressStart = (_dragOffset / bottomPos).clamp(0.0, 1.0);
      if (progressStart >= 1.0) {
        _setIndex((_currentIndex - 1 + len) % len);
      } else {
        _animateToPrevious(progressStart);
      }
    }
    // Below threshold → snap back
    else {
      setState(() {
        _dragOffset = 0;
      });
    }
  }

  // ─── Animation Triggers ──────────────────────────────────────────────

  void _animateToNext(double progressStart) {
    setState(() {
      _isAnimating = true;
      _isDraggingUp = true;
    });

    _controller.forward(from: progressStart).then((_) {
      if (mounted) {
        _setIndex((_currentIndex + 1) % _effectiveMaxCards);
        _controller.reset();
      }
    });
  }

  void _animateToPrevious(double progressStart) {
    setState(() {
      _isAnimating = true;
      _isDraggingUp = false;
    });

    _controller.forward(from: progressStart).then((_) {
      if (mounted) {
        _setIndex((_currentIndex - 1 + _effectiveMaxCards) % _effectiveMaxCards);
        _controller.reset();
      }
    });
  }

  /// Updates the current index, resets drag state, and notifies listener.
  void _setIndex(int newIndex) {
    setState(() {
      _currentIndex = newIndex;
      _isAnimating = false;
      _dragOffset = 0;
    });
    widget.onIndexChanged?.call(newIndex);
  }

  // ─── Build ───────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return _buildCardStack();
  }

  Widget _buildCardStack() {
    // Fallback: show items in a simple column when < 3 items
    if (!_showCarousel) {
      final cardsToShow = widget.items.take(_effectiveMaxCards).toList();
      return Column(children: cardsToShow);
    }

    final bottomPos = _config.bottomPos;
    final stackOffset = _config.stackOffset;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onVerticalDragStart: _onVerticalDragStart,
      onVerticalDragUpdate: _onVerticalDragUpdate,
      onVerticalDragEnd: _onVerticalDragEnd,
      child: SizedBox(
        height: (bottomPos * 2) + stackOffset * 2 + 60,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withValues(alpha: 0.08),
                blurRadius: 15.0,
                offset: const Offset(0, 2),
              ),
              BoxShadow(
                color: Colors.grey.withValues(alpha: 0.04),
                blurRadius: 25.0,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: RepaintBoundary(
            child: AnimatedBuilder(
              animation: _animation,
              builder: (context, _) {
                return Stack(
                  clipBehavior: Clip.none,
                  children: _buildCardLayers(),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  /// Builds the list of positioned card widgets for the current state.
  ///
  /// Two modes:
  /// 1. **Static** (no drag, no animation): cards sit at their slot positions.
  /// 2. **Animating/Dragging**: cards interpolate between old and new slots.
  List<Widget> _buildCardLayers() {
    final int len = _effectiveMaxCards;
    final List<Widget> cards = [];

    // ── Static layout ──
    if (!_isAnimating && _dragOffset == 0) {
      for (int slot = 3; slot >= 0; slot--) {
        final y = _slots.slotYs[slot];
        final scale = slot <= 1 ? 1.0 : _slots.slotScales[slot];
        final z = _slots.slotZs[slot];
        final cardIdx = (_currentIndex + slot) % len;

        cards.add(
          CarouselItemWrapper(
            key: ValueKey('card_$cardIdx'),
            y: y,
            scale: scale,
            z: z,
            child: widget.items[cardIdx],
          ),
        );
      }
      return cards;
    }

    // ── Animated / Dragging layout ──
    final double progress;
    final bool isUpSwipe;
    final int newC;

    if (_isAnimating) {
      progress = _animation.value;
      isUpSwipe = _isDraggingUp;
      newC = isUpSwipe
          ? (_currentIndex + 1) % len
          : (_currentIndex - 1 + len) % len;
    } else {
      progress = (_dragOffset.abs() / _config.bottomPos).clamp(0.0, 1.0);
      isUpSwipe = _dragOffset < 0;
      newC = isUpSwipe
          ? (_currentIndex + 1) % len
          : (_currentIndex - 1 + len) % len;
    }

    final animInfos = buildAnimationLayers(
      progress: progress,
      newCurrent: newC,
      oldCurrent: _currentIndex,
      len: len,
      slots: _slots,
      isUpSwipe: isUpSwipe,
    );

    // Sort by Z-depth so back cards paint first
    animInfos.sort((a, b) => (a['z'] as double).compareTo(b['z'] as double));

    for (final info in animInfos) {
      cards.add(
        CarouselItemWrapper(
          key: ValueKey('card_${info['idx']}'),
          y: info['y'] as double,
          scale: info['scale'] as double,
          z: info['z'] as double,
          rotateX: info['tilt'] as double,
          child: widget.items[info['idx'] as int],
        ),
      );
    }

    return cards;
  }
}
