import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth;
  final FirebaseFirestore _db;

  /// Construtor que permite a injeção de dependências para testes.
  /// No aplicativo real, ele usará as instâncias padrão do Firebase.
  AuthService({FirebaseAuth? auth, FirebaseFirestore? db})
      : _auth = auth ?? FirebaseAuth.instance,
        _db = db ?? FirebaseFirestore.instance;

  Stream<User?> get onAuthStateChanged => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  /// Realiza o login de um usuário com e-mail e senha.
  Future<UserCredential> signIn(String email, String senha) async {
    return await _auth.signInWithEmailAndPassword(email: email, password: senha);
  }

  /// Registra um novo usuário (geralmente um responsável).
  Future<UserCredential> signUp({
    required String nome,
    required String email,
    required String senha,
    required String cpf,
    required String dataNascimento,
    required String role,
    required String escolaId,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(email: email, password: senha);
    await _db.collection('users').doc(cred.user!.uid).set({
      'nome': nome,
      'email': email,
      'cpf': cpf,
      'dataNascimento': dataNascimento,
      'role': role,
      'escolaId': escolaId,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return cred;
  }

  /// >>> REGISTRO DE GESTOR E ESCOLA COM BATCH WRITE <<<
  /// Garante que o usuário e a escola sejam criados juntos, ou nenhum deles.
  Future<void> criarGestorEEscola({
    required String uid,
    required String nomeGestor,
    required String email,
    required String cpf,
    required String dataNascimento,
    required String nomeEscola,
    String? tipoEscola,
  }) async {
    final userRef = _db.collection('users').doc(uid);
    final escolaRef = _db.collection('escolas').doc();

    WriteBatch batch = _db.batch();

    // 1) Prepara a criação do documento do usuário (gestor)
    batch.set(userRef, {
      'nome': nomeGestor,
      'email': email,
      'cpf': cpf,
      'dataNascimento': dataNascimento,
      'role': 'gestao',
      'escolaId': escolaRef.id, // Vincula o ID da futura escola
      'createdAt': FieldValue.serverTimestamp(),
    });

    // 2) Prepara a criação do documento da escola
    batch.set(escolaRef, {
      'nome': nomeEscola,
      'gestorId': uid,
      if (tipoEscola != null) 'tipo': tipoEscola,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // 3) Executa as duas operações de uma vez
    await batch.commit();
  }

  /// Retorna um Stream com os dados do usuário logado.
  Stream<DocumentSnapshot<Map<String, dynamic>>>? getUserStream() {
    final uid = currentUser?.uid;
    if (uid == null) return null;
    return _db.collection('users').doc(uid).snapshots();
  }

  /// Atualiza os dados de um usuário no Firestore.
  Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    await _db.collection('users').doc(uid).update(data);
  }

  /// Deleta a conta do usuário no Firestore e no Authentication.
  Future<void> deleteUserAccount() async {
    final user = currentUser;
    if (user == null) return;
    await _db.collection('users').doc(user.uid).delete();
    try {
      await user.delete();
    } on FirebaseAuthException catch (e) {
      // ignore: avoid_print
      print("Erro ao deletar conta de autenticação: ${e.message}");
    }
  }

  /// Desloga o usuário atual.
  Future<void> signOut() => _auth.signOut();

  /// Busca o perfil ('role') de um usuário pelo UID.
  Future<String?> getRole(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    return doc.data()?['role'] as String?;
  }

  /// Busca o ID da escola de um usuário pelo UID.
  Future<String?> getSchoolId(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    return doc.data()?['escolaId'] as String?;
  }
}
