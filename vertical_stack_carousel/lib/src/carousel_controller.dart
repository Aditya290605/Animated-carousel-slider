
import 'carousel_animation.dart';

/// Immutable configuration for the carousel layout and behavior.
///
/// These values control the physical appearance and interaction feel of the
/// stacked carousel. Default values match the original Bill Manager carousel.
class CarouselConfig {
  /// Height of each card in logical pixels.
  final double cardHeight;

  /// Vertical offset between stacked (behind) cards in logical pixels.
  /// Controls how much each successive back card peeks out.
  final double stackOffset;

  /// Maximum drag distance (in logical pixels) before resistance caps out.
  final double dragClamp;

  /// Minimum drag displacement (in logical pixels) to trigger a card change.
  final double threshold;

  /// Minimum drag velocity (in pixels/second) to trigger a card change,
  /// even if the displacement threshold is not met.
  final double velocityThreshold;

  /// Vertical spacing between the front card and the second card.
  final double cardSpacing;

  const CarouselConfig({
    this.cardHeight = 100.0,
    this.stackOffset = 7.0,
    this.dragClamp = 220.0,
    this.threshold = 35.0,
    this.velocityThreshold = 650.0,
    this.cardSpacing = 0.2,
  });

  /// The total distance from the top of slot 0 to the top of slot 1.
  /// Used as the baseline for animation progress calculations.
  double get bottomPos => cardHeight + cardSpacing;
}

/// Pre-computed slot layout for the 4 visible card positions.
///
/// The carousel shows up to 4 cards simultaneously:
/// - **Slot 0**: Front card (full size, top position)
/// - **Slot 1**: Second card (full size, below front)
/// - **Slot 2**: First stacked card (slightly scaled down)
/// - **Slot 3**: Second stacked card (further scaled down)
class CarouselSlotConfig {
  /// Y positions for each of the 4 slots.
  final List<double> slotYs;

  /// Scale factors for each slot. Front two cards are full-size (1.0),
  /// back cards are progressively smaller.
  final List<double> slotScales;

  /// Z-depth values for each slot. Higher values are painted on top.
  final List<double> slotZs;

  CarouselSlotConfig._({
    required this.slotYs,
    required this.slotScales,
    required this.slotZs,
  });

  /// Constructs slot config from a [CarouselConfig].
  factory CarouselSlotConfig.fromConfig(CarouselConfig config) {
    final bp = config.bottomPos;
    final so = config.stackOffset;

    return CarouselSlotConfig._(
      slotYs: [
        0.0, // Slot 0: top
        bp, // Slot 1: directly below front
        bp + so * 2, // Slot 2: first stacked card
        bp + so * 3.5, // Slot 3: second stacked card
      ],
      slotScales: [1.0, 1.0, 0.97, 0.94],
      slotZs: [10.0, 5.0, 1.0, -3.0],
    );
  }
}

/// Computes the per-card animation state for all visible cards during a
/// transition between the old and new current index.
///
/// Returns a list of maps, each containing:
/// - `idx`: the item index in the data list
/// - `y`: computed Y position
/// - `scale`: computed scale factor
/// - `z`: computed Z depth (for paint order and perspective)
/// - `tilt`: X-axis rotation (currently always 0.0)
/// - `stackPos`: visual stack position (0 = front, higher = further back)
///
/// [progress] is 0.0–1.0 representing how far the transition has progressed.
/// [newCurrent] and [oldCurrent] are the target and source indices.
/// [len] is the total number of items.
/// [slots] provides the layout geometry.
/// [isUpSwipe] indicates swipe direction (true = advancing to next).
List<Map<String, dynamic>> buildAnimationLayers({
  required double progress,
  required int newCurrent,
  required int oldCurrent,
  required int len,
  required CarouselSlotConfig slots,
  required bool isUpSwipe,
}) {
  final animInfos = <Map<String, dynamic>>[];
  const int numSlots = 4;
  final newIndices = <int>{};

  // Compute interpolated position for each card in the new layout
  for (int k = 0; k < numSlots; k++) {
    final idx = (newCurrent + k) % len;
    newIndices.add(idx);

    // Where was this card in the old layout?
    final oldRel = ((idx - oldCurrent + len) % len).toInt();

    final double oldY;
    final double oldS;
    final double oldZ;

    if (oldRel > 3) {
      // Card was off-screen — start from behind the last slot
      oldY = slots.slotYs[3] + 7.0; // stackOffset
      oldS = slots.slotScales[3] - 0.02;
      oldZ = slots.slotZs[3] - 5.0;
    } else {
      oldY = slots.slotYs[oldRel];
      oldS = slots.slotScales[oldRel];
      oldZ = slots.slotZs[oldRel];
    }

    final newY = slots.slotYs[k];
    final newS = slots.slotScales[k];
    final newZ = slots.slotZs[k];

    // Blend between old and new positions using custom easing
    final y = smoothEase(progress, oldY, newY);
    final s = smoothEase(progress, oldS, newS);
    final z = smoothEase(progress, oldZ, newZ);
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

  // Handle the card that is exiting the visible set
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
    final oldY = slots.slotYs[oldRelOut];
    final oldScale = slots.slotScales[oldRelOut];
    final oldZ = slots.slotZs[oldRelOut];
    final targetY = slots.slotYs[3] + 7.0;
    final targetScale = slots.slotScales[3] - 0.02;
    final targetZ = slots.slotZs[3] - 5.0;

    final y = smoothEase(progress, oldY, targetY);
    final sc = smoothEase(progress, oldScale, targetScale);
    final zz = smoothEase(progress, oldZ, targetZ);

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
