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

    final schoolRef = await _db.collection('escolas').add({
      'nome': schoolName,
      'tipo': schoolType,
      'outros_dados': otherData,
      'gestorId': gestorId,
      'createdAt': FieldValue.serverTimestamp(),
    });

    await _db.collection('users').doc(gestorId).update({
      'id_escola': schoolRef.id,
    });
  }

  //Busca os dados de uma escola uma única vez
  Future<DocumentSnapshot> getSchoolData(String schoolId) {
    return _db.collection('escolas').doc(schoolId).get();
  }

  //Busca os dados da escola em tempo real (para a tela de detalhes)
  Stream<DocumentSnapshot> getSchoolStream(String schoolId) {
    return _db.collection('escolas').doc(schoolId).snapshots();
  }

  //Atualiza os dados da escola
  Future<void> updateSchool({
    required String schoolId,
    required String schoolName,
    required String schoolType,
    required String otherData,
  }) async {
    await _db.collection('escolas').doc(schoolId).update({
      'nome': schoolName,
      'tipo': schoolType,
      'outros_dados': otherData,
    });
  }

  //Deleta a escola
  Future<void> deleteSchool(String schoolId) async {
    final gestorId = _auth.currentUser?.uid;
    if (gestorId == null) {
      throw Exception('Usuário não autenticado.');
    }

    // 1. Deletar o documento da escola
    await _db.collection('escolas').doc(schoolId).delete();

    // 2. Desvincular a escola do gestor (removendo o campo)
    await _db.collection('users').doc(gestorId).update({
      'id_escola': FieldValue.delete(),
    });
  }
}