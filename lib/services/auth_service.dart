import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  Stream<User?> get onAuthStateChanged => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  // LOGIN
  Future<UserCredential> signIn(String email, String senha) async {
    return await _auth.signInWithEmailAndPassword(email: email, password: senha);
  }

  // REGISTRO genérico (responsável) — já com escolaId resolvido antes
  Future<UserCredential> signUp({
    required String nome,
    required String email,
    required String senha,
    required String cpf,
    required String dataNascimento, // Adicionado para consistência
    required String role, // 'responsavel'
    required String escolaId,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(email: email, password: senha);
    await _db.collection('users').doc(cred.user!.uid).set({
      'nome': nome,
      'email': email,
      'cpf': cpf,
      'dataNascimento': dataNascimento, // Adicionado
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
    required String dataNascimento, // Parâmetro adicionado
    required String nomeEscola,
    String? tipoEscola, // opcional
  }) async {
    final userRef = _db.collection('users').doc(uid);
    final escolaRef = _db.collection('escolas').doc();

    // Usar um batch write garante que ambas as operações tenham sucesso ou falhem juntas.
    WriteBatch batch = _db.batch();

    // 1) Prepara a criação do documento do usuário (gestor)
    batch.set(userRef, {
      'nome': nomeGestor,
      'email': email,
      'cpf': cpf,
      'dataNascimento': dataNascimento, // Salva a data de nascimento
      'role': 'gestao',
      'escolaId': escolaRef.id, // Já vincula o ID da futura escola
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

  Stream<DocumentSnapshot<Map<String, dynamic>>>? getUserStream() {
    final uid = currentUser?.uid;
    if (uid == null) return null;
    return _db.collection('users').doc(uid).snapshots();
  }

  Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    await _db.collection('users').doc(uid).update(data);
  }

  Future<void> deleteUserAccount() async {
    final user = currentUser;
    if (user == null) return;
    await _db.collection('users').doc(user.uid).delete();
    try {
      await user.delete();
    } on FirebaseAuthException catch (e) {
      print("Erro ao deletar conta de autenticação: ${e.message}");
    }
  }

  Future<void> signOut() => _auth.signOut();

  Future<String?> getRole(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    return doc.data()?['role'] as String?;
  }

  Future<String?> getSchoolId(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    return doc.data()?['escolaId'] as String?;
  }
}