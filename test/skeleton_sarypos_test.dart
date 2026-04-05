import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sarypos/widgets/skeleton_sarypos.dart';

void main() {
  testWidgets('SkeletonBox renders with given size', (tester) async {
    const ukuran = 120.0;

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(child: SkeletonBox(width: ukuran, height: 16)),
        ),
      ),
    );

    expect(find.byType(SkeletonBox), findsOneWidget);
    expect(find.byType(Center), findsOneWidget);
  });
}
