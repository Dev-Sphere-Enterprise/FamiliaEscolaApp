import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:FamiliaEscolaApp/services/auth_service.dart';

// 1. Gera automaticamente as classes Mock para os tipos abaixo.
@GenerateMocks([
  FirebaseAuth,
  FirebaseFirestore,
  UserCredential,
  User,
  CollectionReference,
  DocumentReference,
  WriteBatch,
])
import 'auth_service_test.mocks.dart'; // Este arquivo será gerado no próximo passo.

void main() {
  // Declaração das variáveis que serão inicializadas no setUp
  late AuthService authService;
  late MockFirebaseAuth mockAuth;
  late MockFirebaseFirestore mockFirestore;
  late MockCollectionReference<Map<String, dynamic>> mockUsersCollection;
  late MockCollectionReference<Map<String, dynamic>> mockSchoolsCollection;
  late MockDocumentReference<Map<String, dynamic>> mockUserDoc;
  late MockDocumentReference<Map<String, dynamic>> mockSchoolDoc;
  late MockWriteBatch mockWriteBatch;
  late MockUserCredential mockUserCredential;
  late MockUser mockUser;

  // Roda antes de cada teste para garantir um ambiente limpo
  setUp(() {
    // Instancia os mocks
    mockAuth = MockFirebaseAuth();
    mockFirestore = MockFirebaseFirestore();
    mockUsersCollection = MockCollectionReference<Map<String, dynamic>>();
    mockSchoolsCollection = MockCollectionReference<Map<String, dynamic>>();
    mockUserDoc = MockDocumentReference<Map<String, dynamic>>();
    mockSchoolDoc = MockDocumentReference<Map<String, dynamic>>();
    mockWriteBatch = MockWriteBatch();
    mockUserCredential = MockUserCredential();
    mockUser = MockUser();

    // Injeta os mocks no serviço que estamos testando
    authService = AuthService(auth: mockAuth, db: mockFirestore);

    // Configura o comportamento esperado dos mocks (stubbing)
    when(mockFirestore.collection('users')).thenReturn(mockUsersCollection);
    when(mockFirestore.collection('escolas')).thenReturn(mockSchoolsCollection);

    when(mockUsersCollection.doc(any)).thenReturn(mockUserDoc);
    when(mockSchoolsCollection.doc()).thenReturn(mockSchoolDoc); // Para quando um novo doc é criado sem ID
    when(mockSchoolsCollection.doc(any)).thenReturn(mockSchoolDoc); // Para quando um doc é acessado com ID

    when(mockSchoolDoc.id).thenReturn('mock_school_id');
    when(mockFirestore.batch()).thenReturn(mockWriteBatch);
    when(mockUserCredential.user).thenReturn(mockUser);
    when(mockUser.uid).thenReturn('mock_uid');
  });

  group('AuthService Unit Tests', () {
    test('signIn should call FirebaseAuth with correct email and password', () async {
      // Arrange
      when(mockAuth.signInWithEmailAndPassword(
        email: 'test@test.com',
        password: 'password',
      )).thenAnswer((_) async => mockUserCredential);

      // Act
      await authService.signIn('test@test.com', 'password');

      // Assert
      verify(mockAuth.signInWithEmailAndPassword(
        email: 'test@test.com',
        password: 'password',
      )).called(1);
    });

    test('criarGestorEEscola should complete and call correct batch methods', () async {
      // Arrange
      when(mockWriteBatch.commit()).thenAnswer((_) async {});

      // Act
      await authService.criarGestorEEscola(
        uid: 'new_gestor_uid',
        nomeGestor: 'Gestor Teste',
        email: 'gestor@test.com',
        cpf: '12345678900',
        dataNascimento: '01/01/1980',
        nomeEscola: 'Escola Teste',
      );

      // Assert
      verify(mockFirestore.batch()).called(1);
      verify(mockWriteBatch.commit()).called(1);

      verify(mockWriteBatch.set(
        mockUserDoc,
        any,
      )).called(1);

      verify(mockWriteBatch.set(
        mockSchoolDoc,
        any,
      )).called(1);
    });
  });
}

