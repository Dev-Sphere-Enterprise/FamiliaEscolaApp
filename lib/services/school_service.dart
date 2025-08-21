import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SchoolService {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  // ➕ Adicionar escola (apenas gestores podem criar)
  Future<void> addSchool({
    required String schoolName,
    required String schoolType,
    required String otherData,
  }) async {
    final gestorId = _auth.currentUser?.uid;
    if (gestorId == null) {
      throw Exception('Usuário não autenticado.');
    }

    // Cria a escola
    final schoolRef = await _db.collection('escolas').add({
      'nome': schoolName,
      'tipo': schoolType,
      'info': otherData,
      'gestorId': gestorId,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Vincula gestor à escola criada
    await _db.collection('users').doc(gestorId).update({
      'escolaId': schoolRef.id,
    });
  }

  // 🔎 Buscar os dados de uma escola uma única vez
  Future<DocumentSnapshot<Map<String, dynamic>>> getSchoolData(String schoolId) {
    return _db.collection('escolas').doc(schoolId).get();
  }

  // 🔄 Buscar os dados da escola em tempo real (para a tela de detalhes)
  Stream<DocumentSnapshot<Map<String, dynamic>>> getSchoolStream(String schoolId) {
    return _db.collection('escolas').doc(schoolId).snapshots();
  }

  // ✏️ Atualizar os dados da escola
  Future<void> updateSchool({
    required String schoolId,
    required String schoolName,
    required String schoolType,
    required String otherData,
  }) async {
    await _db.collection('escolas').doc(schoolId).update({
      'nome': schoolName,
      'tipo': schoolType,
      'info': otherData,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ❌ Deletar escola
  Future<void> deleteSchool(String schoolId) async {
    final gestorId = _auth.currentUser?.uid;
    if (gestorId == null) {
      throw Exception('Usuário não autenticado.');
    }

    // 1. Deleta o documento da escola
    await _db.collection('escolas').doc(schoolId).delete();

    // 2. Desvincula a escola do gestor
    await _db.collection('users').doc(gestorId).update({
      'escolaId': FieldValue.delete(),
    });
  }

  // 📋 Listar todas as escolas (para dropdown de responsáveis)
  Stream<QuerySnapshot<Map<String, dynamic>>> getAllSchoolsStream() {
    return _db.collection('escolas').orderBy('nome').snapshots();
  }
}
