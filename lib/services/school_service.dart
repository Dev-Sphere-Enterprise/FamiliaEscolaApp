import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
class SchoolService {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  Future<void> addSchool({
    required String schoolName,
    required String schoolType,
    required String otherData,
  }) async {
    final gestorId = _auth.currentUser?.uid;
    if (gestorId == null) {
      throw Exception('Usuário não autenticado.');
    }

    // 1. Criar o documento da escola
    final schoolRef = await _db.collection('escolas').add({
      'nome': schoolName,
      'tipo': schoolType,
      'outros_dados': otherData,
      'gestorId': gestorId,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // 2. Vincular a escola ao gestor
    await _db.collection('users').doc(gestorId).update({
      'id_escola': schoolRef.id,
    });
  }

  // CORREÇÃO: A função foi movida para fora do método addSchool
  Future<DocumentSnapshot> getSchoolData(String schoolId) {
    return _db.collection('escolas').doc(schoolId).get();
  }
}