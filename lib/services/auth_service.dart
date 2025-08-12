import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  Stream<User?> get onAuthStateChanged => _auth.authStateChanges();

  // Obtém o usuário atualmente logado
  User? get currentUser => _auth.currentUser;

  Future<UserCredential> signIn(String email, String senha) async {
    return await _auth.signInWithEmailAndPassword(email: email, password: senha);
  }

  Future<UserCredential> signUp({
    required String nome,
    required String email,
    required String senha,
    required String cpf,
    required String role, // 'responsavel' | 'gestao'
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(email: email, password: senha);
    await _db.collection('users').doc(cred.user!.uid).set({
      'nome': nome,
      'email': email,
      'cpf': cpf,
      'role': role,
      'alunosVinculados': [],
      'turmasVinculadas': [],
    });
    return cred;
  }

  // (READ) Obter um stream com os dados do usuário logado
  Stream<DocumentSnapshot<Map<String, dynamic>>>? getUserStream() {
    if (currentUser == null) return null;
    return _db.collection('users').doc(currentUser!.uid).snapshots();
  }

  // (UPDATE) Atualizar os dados de um usuário
  Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    await _db.collection('users').doc(uid).update(data);
  }

  Future<void> deleteUserAccount() async {
    final user = currentUser;
    if (user == null) return;

    // Deleta os dados do Firestore
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
}
