import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cakrawala_educentre/main.dart';

void main() {
  testWidgets('Cakrawala Bimbel landing screen loads properly', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(const CakrawalaBimbelApp());
    await tester.pump();

    // Verify key Bimbel texts exist
    expect(find.textContaining('CAKRAWALA'), findsWidgets);
    expect(find.textContaining('BIMBEL'), findsWidgets);
  });
}
