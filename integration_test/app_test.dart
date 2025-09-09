// integration_test/app_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:FamiliaEscolaApp/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Fluxo de Login Completo', () {
    testWidgets('Usuário consegue fazer login e chegar na HomePage', (WidgetTester tester) async {
      // Arrange: Inicia o aplicativo
      app.main();
      await tester.pumpAndSettle(); // Aguarda o app inicializar e a splash screen terminar

      // Act & Assert: Verifica se está na tela de login
      expect(find.byType(Image), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Entrar'), findsOneWidget);

      // Act: Preenche o formulário de login
      // Substitua com um e-mail e senha VÁLIDOS do seu Firebase Auth
      await tester.enterText(find.byKey(const Key('email_field')), 'rianwilker17@ges.com');
      await tester.enterText(find.byKey(const Key('password_field')), 'wilker17');

      // Toca no botão de entrar
      await tester.tap(find.widgetWithText(FilledButton, 'Entrar'));

      // Aguarda a animação de loading e a navegação
      await tester.pump(const Duration(seconds: 1)); // Aguarda o loading
      await tester.pumpAndSettle(); // Aguarda a navegação e o carregamento da próxima tela

      // Assert: Verifica se a HomePage foi carregada
      // Use um elemento específico da sua HomePage para confirmar
      expect(find.textContaining('Olá,'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Alunos'), findsOneWidget);
    });
  });
}