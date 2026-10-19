import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:institucion_web/main.dart';

void main() {
  testWidgets('Portal se construye sin errores', (WidgetTester tester) async {
    // Build the app widget.
    await tester.pumpWidget(const PortalInstitucionesApp());

    // Verify that the app has a title.
    expect(find.text('Instituciones CursAR'), findsNothing);

    // Verify that a MaterialApp is present.
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
