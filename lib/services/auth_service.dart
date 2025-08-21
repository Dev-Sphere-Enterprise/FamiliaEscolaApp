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
    required String role, // 'responsavel'
    required String escolaId,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(email: email, password: senha);
    await _db.collection('users').doc(cred.user!.uid).set({
      'nome': nome,
      'email': email,
      'cpf': cpf,
      'role': role,
      'escolaId': escolaId,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return cred;
  }

  /// >>> REGISTRO DE GESTOR SEM BATCH <<<
  /// Passo 1: cria/garante users/{uid} com role=gestao
  /// Passo 2: cria escolas/{escolaId}
  /// Passo 3: atualiza users/{uid}.escolaId
  Future<String> criarGestorEEscola({
    required String uid,
    required String nomeGestor,
    required String email,
    required String cpf,
    required String nomeEscola,
    String? tipoEscola, // opcional
  }) async {
    final userRef = _db.collection('users').doc(uid);

    // 1) garante perfil com role gestao (as regras de /escolas dependem disso)
    await userRef.set({
      'nome': nomeGestor,
      'email': email,
      'cpf': cpf,
      'role': 'gestao',
      'updatedAt': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    // 2) cria a escola (agora permitido, pois o user já tem role=gestao)
    final escolaRef = _db.collection('escolas').doc();
    await escolaRef.set({
      'nome': nomeEscola,
      if (tipoEscola != null) 'tipo': tipoEscola,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // 3) vincula escolaId no usuário
    await userRef.update({
      'escolaId': escolaRef.id,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    return escolaRef.id;
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
    try { await user.delete(); } on FirebaseAuthException catch (e) {
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
