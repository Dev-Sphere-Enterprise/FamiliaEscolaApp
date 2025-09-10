import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:FamiliaEscolaApp/main.dart'; // ✅ ajuste o nome do pacote

void main() {
  testWidgets('App carrega sem crash', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const FamiliaEscolaApp());

    // Verifique se aparece algum texto esperado da sua SplashPage ou inicial
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
