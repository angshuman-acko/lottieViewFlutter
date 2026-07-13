import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lottie_viewer/main.dart';

void main() {
  testWidgets('renders Lottie Viewer header', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const LottieViewerApp());
    await tester.pump();

    expect(find.text('Lottie Viewer'), findsOneWidget);
    expect(find.text('Load URL'), findsOneWidget);
    expect(find.text('Pick file'), findsOneWidget);
    expect(find.text('View options'), findsOneWidget);
    expect(find.text('Preview'), findsOneWidget);
  });
}
