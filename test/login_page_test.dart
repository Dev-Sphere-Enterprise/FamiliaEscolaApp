// test/login_page_test.dart
import 'package:FamiliaEscolaApp/pages/login_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Envolve o widget em um MaterialApp para fornecer o contexto necessário (temas, navegação, etc.)
  Widget createWidgetForTesting({required Widget child}) {
    return MaterialApp(
      home: child,
    );
  }

  group('LoginPage Widget Tests', () {
    testWidgets('Renderiza todos os elementos da UI corretamente', (WidgetTester tester) async {
      // Arrange: Constrói a LoginPage
      await tester.pumpWidget(createWidgetForTesting(child: const LoginPage()));

      // Assert: Verifica se os elementos principais estão na tela
      expect(find.byType(Image), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Email'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Senha'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Entrar'), findsOneWidget);
      expect(find.widgetWithText(OutlinedButton, 'Cadastra-se'), findsOneWidget);
      expect(find.widgetWithText(TextButton, 'Esqueceu a senha ?'), findsOneWidget);
    });

    testWidgets('Mostra erros de validação quando os campos estão vazios', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(createWidgetForTesting(child: const LoginPage()));

      // Act: Toca no botão de entrar sem preencher os campos
      await tester.tap(find.widgetWithText(FilledButton, 'Entrar'));
      await tester.pump(); // Reconstrói o widget para mostrar os erros

      // Assert: Verifica se as mensagens de erro apareceram
      expect(find.text('Informe o e-mail'), findsOneWidget);
      expect(find.text('Informe a senha'), findsOneWidget);
    });

    testWidgets('Não mostra erros de validação quando os campos são preenchidos', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(createWidgetForTesting(child: const LoginPage()));

      // Act: Preenche os campos com dados válidos
      await tester.enterText(find.byKey(const Key('email_field')), 'rianwilker17@ges.com');
      await tester.enterText(find.byKey(const Key('password_field')), 'wilker17');

      // Toca no botão de entrar
      await tester.tap(find.widgetWithText(FilledButton, 'Entrar'));
      await tester.pump();

      // Assert: Verifica se as mensagens de erro NÃO apareceram
      expect(find.text('Informe o e-mail'), findsNothing);
      expect(find.text('Informe a senha'), findsNothing);
    });
  });
}