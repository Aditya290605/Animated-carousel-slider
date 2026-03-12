# AnimatedCarouselSlider

A highly customizable, reusable vertical stacked carousel slider widget for Flutter. It features smooth drag-based animations, a beautiful 3D depth effect, and infinite cyclic scrolling.

![AnimatedCarouselSlider Demo](https://raw.githubusercontent.com/aditya-magar/animated_carousel_slider/main/example/demo.gif)
*(Note: Replace the link above with the actual URL to your screen recording or GIF after publishing)*

## ✨ Features

- **Vertical Stacked Layout** — Cards are displayed in a visually appealing depth-layered stack.
- **Smooth Drag Animations** — Swipe up or down to cycle through items with progressive drag resistance.
- **Infinite Cyclic Scrolling** — Loops seamlessly in both directions, making it perfect for endless content.
- **3D Perspective Transform** — Cards scale down and recede along the Z-axis for a realistic visual depth effect.
- **Custom Spring Curve** — Uses a custom 3-phase animation curve for a natural, responsive feel.
- **Zero External Dependencies** — Built entirely using the core Flutter SDK. No extra bloat!
- **Highly Customizable** — Control card height, animation duration, stack offset, item spacing, and animation curves.

---

## 🚀 Installation

Add `animated_carousel_slider` to your `pubspec.yaml` file:

```yaml
dependencies:
  animated_carousel_slider: ^0.1.0
```

Then run:
```bash
flutter pub get
```

---

## 📖 Detailed Usage Guide

Import the package in your Dart code:

```dart
import 'package:animated_carousel_slider/animated_carousel_slider.dart';
```

### 1. Basic Usage

The simplest way to use the carousel is to provide a list of widgets (e.g., `Card` or `Container`) to the `items` property. The carousel requires at least 3 items to show the full stacking effect. If fewer than 3 items are provided, it cleanly falls back to a standard `Column`.

```dart
AnimatedCarouselSlider(
  items: [
    Card(color: Colors.blue.shade100, child: const Center(child: Text("Item 1"))),
    Card(color: Colors.green.shade100, child: const Center(child: Text("Item 2"))),
    Card(color: Colors.red.shade100, child: const Center(child: Text("Item 3"))),
  ],
)
```

### 2. Advanced Usage Structure (with state tracking)

Usually, you want to perform actions when the user swipes through the carousel (e.g., updating data, playing a sound, or animating a background). You can use the `onIndexChanged` callback to track the currently active card at the front.

```dart
class MyCarouselPage extends StatefulWidget {
  @override
  _MyCarouselPageState createState() => _MyCarouselPageState();
}

class _MyCarouselPageState extends State<MyCarouselPage> {
  int _currentIndex = 0;

  final List<Color> _colors = [
    Colors.purple.shade200,
    Colors.orange.shade200,
    Colors.teal.shade200,
    Colors.pink.shade200,
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'Currently viewing card: ${_currentIndex + 1}',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 20),
        AnimatedCarouselSlider(
          // Set custom physical dimensions
          cardHeight: 120.0,
          stackOffset: 10.0,
          itemSpacing: 2.0,
          
          // Set custom animation timings
          animationDuration: const Duration(milliseconds: 500),
          
          // Limits the physical widget list (optimizes memory if you have 100+ items)
          maxVisibleCards: 4, 
          
          onIndexChanged: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          items: _colors.map((color) {
            return Container(
              height: 120,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  )
                ]
              ),
              child: const Center(child: Text('Custom Card', style: TextStyle(fontSize: 24))),
            );
          }).toList(),
        ),
      ],
    );
  }
}
```

---

## ⚙️ Customization & API Reference

The `AnimatedCarouselSlider` provides several parameters to fine-tune the visuals and physics to match your app's design system.

| Parameter | Type | Default | Description |
|---|---|---|---|
| `items` | `List<Widget>` | **Required** | The list of widgets to display. Ideally, these should have bounded heights, or you should provide a `cardHeight`. |
| `cardHeight` | `double` | `100.0` | The logical pixel height allocated for each individual card slot in the layout. |
| `maxVisibleCards` | `int?` | `null` | Limits the number of cards that participate in the animation cycle. Useful for performance if your `items` list is very large. |
| `animationDuration` | `Duration` | `450ms` | How long the smooth settling animation takes after a successful swipe. |
| `stackOffset` | `double` | `7.0` | The vertical pixels by which stacked cards peek out from behind the front card. A larger number spreads the stack out further. |
| `itemSpacing` | `double` | `0.2` | The vertical space separating the front-most card and the immediate second card. |
| `curve` | `Curve?` | `SpringCurve()` | Override the default 3-phase custom animation curve with any standard Flutter `Curve` (e.g., `Curves.easeInOut`). |
| `onIndexChanged` | `ValueChanged<int>?`| `null` | Callback function that fires with the new index when the active front card changes via an up/down swipe. |

### Note on Performance
To ensure 60fps/120fps animations, the package wraps every active carousel item in a `RepaintBoundary`. This means the complex UI inside your cards won't be constantly repainted while the user is dragging the stack.

---

## 🤝 Contributing
Contributions, issues, and feature requests are welcome! Feel free to check the [issues page](https://github.com/aditya-magar/animated_carousel_slider/issues).

## 📄 License
This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
