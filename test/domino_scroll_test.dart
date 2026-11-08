import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bite_size/core/widgets/domino_scroll.dart';
import 'package:bite_size/core/widgets/lottie_refresh.dart';

double dyOf(WidgetTester tester, int index) {
  final t = tester.widget<Transform>(
    find
        .descendant(
          of: find.byWidgetPredicate(
            (w) => w is DominoItem && w.index == index,
          ),
          matching: find.byType(Transform),
        )
        .first,
  );
  return t.transform.getTranslation().y;
}

/// Same nesting as the dashboard: hand refresh (clamping physics) > domino > list.
Widget dashboardLike({required int rows}) => MaterialApp(
  home: Scaffold(
    body: LottieRefresh(
      onRefresh: () async {},
      // same tuning as the dashboard
      child: DominoScroll(
        lagPerItem: 0.2,
        edgeGain: 0.6,
        damping: 13,
        child: ListView(
          children: [
            // cards with a spacer between them, like the dashboard
            for (var i = 0; i < rows; i++) ...[
              DominoItem(
                index: i,
                child: SizedBox(height: 80, child: Text('row $i')),
              ),
              const SizedBox(height: 14),
            ],
          ],
        ),
      ),
    ),
  ),
);

Future<Map<int, double>> dragAndSample(
  WidgetTester tester,
  String start,
  Offset step,
  List<int> rows,
) async {
  final gesture = await tester.startGesture(tester.getCenter(find.text(start)));
  for (var i = 0; i < 6; i++) {
    await gesture.moveBy(step);
    await tester.pump(const Duration(milliseconds: 16));
  }
  final out = {for (final r in rows) r: dyOf(tester, r)};
  await gesture.up();
  return out;
}

void main() {
  testWidgets('short list (fits on screen) still ripples when dragged up', (
    tester,
  ) async {
    await tester.pumpWidget(dashboardLike(rows: 5));
    final dy = await dragAndSample(tester, 'row 4', const Offset(0, -20), [
      4,
      2,
      0,
    ]);
    // pushing up past the bottom: the row under the finger follows it most
    expect(dy[4]!, lessThan(-5));
    expect(dy[2]!, lessThan(0));
    expect(dy[2]!, greaterThan(dy[4]!));
    expect(dy[0]!.abs(), lessThanOrEqualTo(dy[2]!.abs()));
    await tester.pumpAndSettle();
    for (final r in [0, 2, 4]) {
      expect(dyOf(tester, r), 0);
    }
  });

  testWidgets('pulling down for the hand refresh ripples the rows too', (
    tester,
  ) async {
    await tester.pumpWidget(dashboardLike(rows: 5));
    final dy = await dragAndSample(tester, 'row 0', const Offset(0, 20), [
      0,
      2,
      4,
    ]);
    expect(
      dy[0]!,
      greaterThan(5),
      reason: 'row under the finger stretches with it',
    );
    expect(dy[4]!.abs(), lessThan(dy[0]!.abs()), reason: 'far rows lag');
    await tester.pumpAndSettle();
    for (final r in [0, 2, 4]) {
      expect(dyOf(tester, r), 0);
    }
  });

  testWidgets(
    'slow real-finger drag (2px per 120Hz frame) still stretches clearly',
    (tester) async {
      // What the Pixel actually sends: tiny overscroll steps. The old impulse
      // model let the spring cancel these out (~4px); the stretch must build.
      await tester.pumpWidget(dashboardLike(rows: 5));
      final gesture = await tester.startGesture(
        tester.getCenter(find.text('row 3')),
      );
      for (var i = 0; i < 60; i++) {
        await gesture.moveBy(const Offset(0, -2));
        await tester.pump(const Duration(milliseconds: 8));
      }
      expect(
        dyOf(tester, 3),
        lessThan(-25),
        reason: 'row under the finger follows it',
      );
      expect(
        dyOf(tester, 0).abs(),
        lessThan(dyOf(tester, 3).abs() * 0.5),
        reason: 'far row lags well behind: the domino',
      );
      await gesture.up();
      var overshoot = 0.0;
      for (var i = 0; i < 90; i++) {
        await tester.pump(const Duration(milliseconds: 8));
        overshoot = dyOf(tester, 3) > overshoot ? dyOf(tester, 3) : overshoot;
      }
      expect(overshoot, greaterThan(1), reason: 'bounces past home on release');
      await tester.pumpAndSettle();
      expect(dyOf(tester, 3), 0);
    },
  );

  testWidgets('pushing up never slides a row over the one above it', (
    tester,
  ) async {
    await tester.pumpWidget(dashboardLike(rows: 5));
    final gesture = await tester.startGesture(
      tester.getCenter(find.text('row 4')),
    );
    for (var i = 0; i < 60; i++) {
      await gesture.moveBy(const Offset(0, -3));
      await tester.pump(const Duration(milliseconds: 8));
      for (var r = 1; r < 5; r++) {
        // 14px apart: row r's top must stay at/below row r-1's bottom
        expect(
          dyOf(tester, r),
          greaterThanOrEqualTo(dyOf(tester, r - 1) - 14.5),
        );
      }
    }
    expect(
      dyOf(tester, 0),
      lessThan(-1),
      reason: 'the top row got shoved up too',
    );
    await gesture.up();
    await tester.pumpAndSettle();
  });

  Future<(double, double)> watchRelease(WidgetTester tester) async {
    // biggest trail of the top and bottom rows while the list moves back up
    var top = 0.0, bottom = 0.0;
    for (var i = 0; i < 400; i++) {
      await tester.pump(const Duration(milliseconds: 8));
      top = dyOf(tester, 0).abs() > top ? dyOf(tester, 0).abs() : top;
      bottom = dyOf(tester, 4).abs() > bottom ? dyOf(tester, 4).abs() : bottom;
    }
    return (top, bottom);
  }

  testWidgets('letting go short of the trigger: rows bounce as it snaps back', (
    tester,
  ) async {
    await tester.pumpWidget(dashboardLike(rows: 5));
    final gesture = await tester.startGesture(
      tester.getCenter(find.text('row 0')),
    );
    for (var i = 0; i < 20; i++) {
      // ~70px of list travel, under the trigger
      await gesture.moveBy(const Offset(0, 6));
      await tester.pump(const Duration(milliseconds: 8));
    }
    final atRelease = dyOf(tester, 4);
    await gesture.up();
    final (_, bottom) = await watchRelease(tester);
    // only the snap-back itself can push the bottom row further than the drag did
    expect(bottom, greaterThan(atRelease.abs() + 4));
    await tester.pumpAndSettle();
    for (final r in [0, 2, 4]) {
      expect(dyOf(tester, r), 0);
    }
  });

  testWidgets(
    'after a refresh, the list closing back up makes the rows bounce',
    (tester) async {
      await tester.pumpWidget(dashboardLike(rows: 5));
      final gesture = await tester.startGesture(
        tester.getCenter(find.text('row 0')),
      );
      for (var i = 0; i < 40; i++) {
        await gesture.moveBy(const Offset(0, 8)); // well past the trigger
        await tester.pump(const Duration(milliseconds: 8));
      }
      await gesture.up();
      // let the rows settle into the loading position first
      for (var i = 0; i < 60; i++) {
        await tester.pump(const Duration(milliseconds: 8));
      }
      final (top, bottom) = await watchRelease(tester);
      expect(
        bottom,
        greaterThan(4),
        reason: 'rows trail while the list closes',
      );
      expect(bottom, greaterThan(top));
      await tester.pumpAndSettle();
      for (final r in [0, 2, 4]) {
        expect(dyOf(tester, r), 0);
      }
    },
  );

  testWidgets('long list keeps the scroll domino', (tester) async {
    await tester.pumpWidget(dashboardLike(rows: 30));
    await tester.drag(find.text('row 3'), const Offset(0, -200));
    final gesture = await tester.startGesture(
      tester.getCenter(find.text('row 4')),
    );
    for (var i = 0; i < 5; i++) {
      await gesture.moveBy(const Offset(0, -20));
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(dyOf(tester, 8), greaterThan(dyOf(tester, 6)));
    expect(dyOf(tester, 6), greaterThan(0));
    await gesture.up();
    await tester.pumpAndSettle();
  });
}
