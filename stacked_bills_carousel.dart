import 'dart:math';

import 'package:bill_manager/features/carousel/domain/entities/bill_entity.dart';
import 'package:flutter/material.dart';

import 'bill_card.dart';

class CardCarousel extends StatefulWidget {
  final List<BillEntity> bills;
  final double cardHeight;
  final int? animationDurationMs;
  final int? maxVisibleCards;

  const CardCarousel({
    super.key,
    required this.bills,
    this.cardHeight = 100.0,
    this.animationDurationMs,
    this.maxVisibleCards,
  });

  @override
  State<CardCarousel> createState() => _CardCarouselState();
}

class _CardCarouselState extends State<CardCarousel>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  int _currentIndex = 0;
  bool _isAnimating = false;
  double _dragOffset = 0;
  bool _isDraggingUp = false;

  late double _bottomPos;
  final double _stackOffset = 7.0;
  final double _dragClamp = 220.0;
  static const double _threshold = 35.0;
  static const double _velocityThreshold = 650.0;
  final double _cardSpacing = 0.2;

  int get _effectiveMaxCards {
    if (widget.maxVisibleCards != null && widget.maxVisibleCards! > 0) {
      return widget.maxVisibleCards!.clamp(1, widget.bills.length);
    }
    return widget.bills.length;
  }

  void _onVerticalDragStart(DragStartDetails details) {
    if (_isAnimating || !_showCarousel) return;
    _dragOffset = 0;
  }

  void _onVerticalDragUpdate(DragUpdateDetails details) {
    if (_isAnimating || !_showCarousel) return;

    double resistance = 1.0;
    double absDragOffset = _dragOffset.abs();

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

    double velocity = details.velocity.pixelsPerSecond.dy;
    final int len = _effectiveMaxCards;

    if (_dragOffset < -_threshold || velocity < -_velocityThreshold) {
      double progressStart = (-_dragOffset / _bottomPos).clamp(0.0, 1.0);
      if (progressStart >= 1.0) {
        setState(() {
          _currentIndex = (_currentIndex + 1) % len;
          _dragOffset = 0;
        });
      } else {
        _animateToNext(progressStart);
      }
    } else if (_dragOffset > _threshold || velocity > _velocityThreshold) {
      double progressStart = (_dragOffset / _bottomPos).clamp(0.0, 1.0);
      if (progressStart >= 1.0) {
        setState(() {
          _currentIndex = (_currentIndex - 1 + len) % len;
          _dragOffset = 0;
        });
      } else {
        _animateToPrevious(progressStart);
      }
    } else {
      setState(() {
        _dragOffset = 0;
      });
    }
  }

  void _animateToNext(double progressStart) {
    setState(() {
      _isAnimating = true;
      _isDraggingUp = true;
    });

    _controller.forward(from: progressStart).then((_) {
      if (mounted) {
        setState(() {
          _currentIndex = (_currentIndex + 1) % _effectiveMaxCards;
          _isAnimating = false;
          _dragOffset = 0;
        });
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
        setState(() {
          _currentIndex =
              (_currentIndex - 1 + _effectiveMaxCards) % _effectiveMaxCards;
          _isAnimating = false;
          _dragOffset = 0;
        });
        _controller.reset();
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _bottomPos = widget.cardHeight + _cardSpacing;

    final duration = widget.animationDurationMs ?? 450;

    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: duration),
    );

    _animation = CurvedAnimation(
      parent: _controller,
      curve: const _SpringCurve(),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _showCarousel => _effectiveMaxCards > 2;

  @override
  Widget build(BuildContext context) {
    return _buildCardStack();
  }

  Widget _buildCardStack() {
    if (!_showCarousel) {
      final cardsToShow = widget.bills.take(_effectiveMaxCards).toList();
      return Column(
        children: cardsToShow.map((bill) => BillCard(bill: bill)).toList(),
      );
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onVerticalDragStart: _onVerticalDragStart,
      onVerticalDragUpdate: _onVerticalDragUpdate,
      onVerticalDragEnd: _onVerticalDragEnd,
      child: SizedBox(
        height: (_bottomPos * 2) + _stackOffset * 2 + 60,
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

  List<Widget> _buildCardLayers() {
    final int len = _effectiveMaxCards;

    List<double> slotYs = [
      0.0,
      _bottomPos,
      _bottomPos + _stackOffset * 2,
      _bottomPos + _stackOffset * 3.5,
    ];

    List<double> slotScales = [1.0, 1.0, 0.97, 0.94];
    List<double> slotZs = [10.0, 5.0, 1.0, -3.0];

    List<Widget> cards = [];

    if (!_isAnimating && _dragOffset == 0) {
      for (int slot = 3; slot >= 0; slot--) {
        double y = slotYs[slot];
        double scale = slot <= 1 ? 1.0 : slotScales[slot];
        double z = slotZs[slot];
        int stackPos = slot >= 2 ? slot - 2 : 0;
        int cardIdx = (_currentIndex + slot) % len;
        cards.add(_buildTransformedCard(cardIdx, y, scale, z, 0.0, stackPos));
      }
    } else {
      double progress;
      bool isUpSwipe;
      int newC;
      if (_isAnimating) {
        progress = _animation.value;
        isUpSwipe = _isDraggingUp;
        newC = isUpSwipe
            ? (_currentIndex + 1) % len
            : (_currentIndex - 1 + len) % len;
      } else {
        progress = (_dragOffset.abs() / _bottomPos).clamp(0.0, 1.0);
        isUpSwipe = _dragOffset < 0;
        newC = isUpSwipe
            ? (_currentIndex + 1) % len
            : (_currentIndex - 1 + len) % len;
      }

      List<Map<String, dynamic>> animInfos = _buildAnimationLayers(
        progress,
        newC,
        _currentIndex,
        len,
        slotYs,
        slotScales,
        slotZs,
        isUpSwipe,
      );

      animInfos.sort((a, b) => (a['z'] as double).compareTo(b['z'] as double));

      for (var info in animInfos) {
        cards.add(
          _buildTransformedCard(
            info['idx'] as int,
            info['y'] as double,
            info['scale'] as double,
            info['z'] as double,
            info['tilt'] as double,
            info['stackPos'] as int,
          ),
        );
      }
    }

    return cards;
  }

  List<Map<String, dynamic>> _buildAnimationLayers(
    double progress,
    int newCurrent,
    int oldCurrent,
    int len,
    List<double> slotYs,
    List<double> slotScales,
    List<double> slotZs,
    bool isUpSwipe,
  ) {
    final animInfos = <Map<String, dynamic>>[];
    const int numSlots = 4;
    final newIndices = <int>{};

    for (int k = 0; k < numSlots; k++) {
      final idx = (newCurrent + k) % len;
      newIndices.add(idx);
      final oldRel = ((idx - oldCurrent + len) % len).toInt();

      final double oldY;
      final double oldS;
      final double oldZ;
      if (oldRel > 3) {
        oldY = slotYs[3] + _stackOffset;
        oldS = slotScales[3] - 0.02;
        oldZ = slotZs[3] - 5.0;
      } else {
        oldY = slotYs[oldRel];
        oldS = slotScales[oldRel];
        oldZ = slotZs[oldRel];
      }

      final newY = slotYs[k];
      final newS = slotScales[k];
      final newZ = slotZs[k];

      final y = _smoothEase(progress, oldY, newY);
      final s = _smoothEase(progress, oldS, newS);
      final z = _smoothEase(progress, oldZ, newZ);
      final stackP = k >= 2 ? k - 2 : 0;

      animInfos.add({
        'idx': idx,
        'y': y,
        'scale': s,
        'z': z,
        'tilt': 0.0,
        'stackPos': stackP,
      });
    }

    final int outIdx;
    final int oldRelOut;
    if (isUpSwipe) {
      outIdx = oldCurrent % len;
      oldRelOut = 0;
    } else {
      outIdx = (oldCurrent + 3) % len;
      oldRelOut = 3;
    }

    if (!newIndices.contains(outIdx)) {
      final oldY = slotYs[oldRelOut];
      final oldScale = slotScales[oldRelOut];
      final oldZ = slotZs[oldRelOut];
      final targetY = slotYs[3] + _stackOffset;
      final targetScale = slotScales[3] - 0.02;
      final targetZ = slotZs[3] - 5.0;

      final y = _smoothEase(progress, oldY, targetY);
      final sc = _smoothEase(progress, oldScale, targetScale);
      final zz = _smoothEase(progress, oldZ, targetZ);

      animInfos.add({
        'idx': outIdx,
        'y': y,
        'scale': sc,
        'z': zz,
        'tilt': 0.0,
        'stackPos': 2,
      });
    }
    return animInfos;
  }

  double _smoothEase(double t, double start, double end) {
    double easeOutQuart = 1.0 - pow(1.0 - t, 4.0);
    double easeOutExpo = t == 1.0 ? 1.0 : 1.0 - pow(2.0, -8.0 * t);
    double easeOutCirc = sqrt(1.0 - pow(t - 1.0, 2.0));

    double blended =
        (0.3 * easeOutQuart) + (0.4 * easeOutExpo) + (0.3 * easeOutCirc);
    return start + (end - start) * blended;
  }

  Widget _buildTransformedCard(
    int idx,
    double y,
    double scale,
    double z,
    double rotateX,
    int stackPosition,
  ) {
    final matrix = Matrix4.identity()
      ..setEntry(3, 2, 0.0006)
      ..translate(0.0, 0.0, z)
      ..rotateX(rotateX)
      ..scale(scale);

    return Positioned(
      top: y,
      left: 0,
      right: 0,
      child: RepaintBoundary(
        child: Transform(
          alignment: Alignment.topCenter,
          transform: matrix,
          child: BillCard(bill: widget.bills[idx]),
        ),
      ),
    );
  }
}

class _SpringCurve extends Curve {
  const _SpringCurve();

  @override
  double transformInternal(double t) {
    if (t < 0.3) {
      double phase1 = t / 0.3;
      return 0.35 * (1.0 - pow(1.0 - phase1, 2.5));
    } else if (t < 0.8) {
      double phase2 = (t - 0.3) / 0.5;
      double easeOut = 1.0 - pow(1.0 - phase2, 3.0);
      return 0.35 + (0.55 * easeOut);
    } else {
      double phase3 = (t - 0.8) / 0.2;
      double gentle = 1.0 - pow(1.0 - phase3, 4.0);
      return 0.9 + (0.1 * gentle);
    }
  }
}
