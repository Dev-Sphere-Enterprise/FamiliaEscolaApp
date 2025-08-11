import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  Stream<User?> get onAuthStateChanged => _auth.authStateChanges();

  Future<UserCredential> signIn(String email, String senha) async {
    return await _auth.signInWithEmailAndPassword(email: email, password: senha);
  }

  Future<UserCredential> signUp({
    required String nome,
    required String email,
    required String senha,
    required String role, // 'responsavel' | 'gestao'
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(email: email, password: senha);
    await _db.collection('users').doc(cred.user!.uid).set({
      'nome': nome,
      'email': email,
      'role': role,
      'alunosVinculados': [],
      'turmasVinculadas': [],
    });
    return cred;
  }

  Future<void> signOut() => _auth.signOut();

  Future<String?> getRole(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    return doc.data()?['role'] as String?;
  }
}
