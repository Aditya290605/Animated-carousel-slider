# AnimatedCarouselSlider

A reusable vertical stacked carousel slider widget for Flutter with smooth drag-based animations and a 3D depth effect.

## Features

- **Vertical stacked carousel** — cards are displayed in a depth-layered stack
- **Smooth drag-based animations** — swipe up/down to cycle through items
- **Infinite cyclic scrolling** — loops seamlessly in both directions
- **Custom spring curve** — 3-phase animation for a natural, responsive feel
- **3D perspective transform** — cards scale and recede for visual depth
- **Zero external dependencies** — only depends on Flutter SDK
- **Customizable** — card height, animation duration, stack offset, curve, and more

## Usage

```dart
import 'package:animated_carousel_slider/animated_carousel_slider.dart';

AnimatedCarouselSlider(
  items: [
    Card(child: Center(child: Text("Item 1"))),
    Card(child: Center(child: Text("Item 2"))),
    Card(child: Center(child: Text("Item 3"))),
    Card(child: Center(child: Text("Item 4"))),
    Card(child: Center(child: Text("Item 5"))),
  ],
  onIndexChanged: (index) => print('Active card: $index'),
)
```

## Parameters

| Parameter | Type | Default | Description |
|---|---|---|---|
| `items` | `List<Widget>` | *required* | Widgets to display in the carousel |
| `cardHeight` | `double` | `100.0` | Height of each card slot |
| `maxVisibleCards` | `int?` | `null` | Limit the number of cycling cards |
| `animationDuration` | `Duration` | `450ms` | Swipe transition duration |
| `stackOffset` | `double` | `7.0` | Vertical peek offset of stacked cards |
| `itemSpacing` | `double` | `0.2` | Gap between front and second card |
| `curve` | `Curve?` | `SpringCurve()` | Custom animation curve |
| `onIndexChanged` | `ValueChanged<int>?` | `null` | Called when active card changes |

## Architecture

```
lib/
├── animated_carousel_slider.dart     ← barrel export
└── src/
    ├── animated_carousel_slider.dart ← main public widget
    ├── carousel_animation.dart       ← SpringCurve + smoothEase
    ├── carousel_controller.dart      ← config, slot layout, animation math
    └── carousel_item.dart            ← positioned/transformed item wrapper
```
