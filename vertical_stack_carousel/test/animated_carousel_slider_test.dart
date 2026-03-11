import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:animated_carousel_slider/animated_carousel_slider.dart';

void main() {
  group('AnimatedCarouselSlider', () {
    List<Widget> buildItems(int count) {
      return List.generate(
        count,
        (i) => Container(
          key: ValueKey('item_$i'),
          height: 100,
          color: Colors.primaries[i % Colors.primaries.length],
          child: Center(child: Text('Item $i')),
        ),
      );
    }

    testWidgets('renders with given items', (tester) async {
      final items = buildItems(5);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnimatedCarouselSlider(items: items),
          ),
        ),
      );

      // The carousel should render (it has > 2 items)
      expect(find.byType(AnimatedCarouselSlider), findsOneWidget);
      expect(find.byType(GestureDetector), findsWidgets);
    });

    testWidgets('falls back to Column when items <= 2', (tester) async {
      final items = buildItems(2);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnimatedCarouselSlider(items: items),
          ),
        ),
      );

      // With <= 2 items, should render a Column instead of GestureDetector
      expect(find.byType(Column), findsWidgets);
      expect(find.text('Item 0'), findsOneWidget);
      expect(find.text('Item 1'), findsOneWidget);
    });

    testWidgets('renders single item without crash', (tester) async {
      final items = buildItems(1);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnimatedCarouselSlider(items: items),
          ),
        ),
      );

      expect(find.text('Item 0'), findsOneWidget);
    });

    testWidgets('fires onIndexChanged on swipe up', (tester) async {
      int? reportedIndex;
      final items = buildItems(5);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnimatedCarouselSlider(
              items: items,
              onIndexChanged: (i) => reportedIndex = i,
            ),
          ),
        ),
      );

      // Perform a swipe-up gesture (drag upward to advance)
      await tester.fling(
        find.byType(GestureDetector).first,
        const Offset(0, -100),
        800,
      );

      // Let the animation complete
      await tester.pumpAndSettle();

      expect(reportedIndex, isNotNull);
      expect(reportedIndex, equals(1));
    });
  });
}
