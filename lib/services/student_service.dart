import 'package:cloud_firestore/cloud_firestore.dart';

class StudentService {
  final _db = FirebaseFirestore.instance;

  /// ➕ Adiciona um novo aluno vinculado à escola
  Future<void> addStudent({
    required String schoolId,
    required String studentName,
    required String studentBirthDate,
    required String responsibleName,
    required String responsibleCpf,
  }) async {
    await _db.collection('escolas').doc(schoolId).collection('alunos').add({
      'name': studentName,
      'birthDate': studentBirthDate,
      'responsibleName': responsibleName,
      'responsibleCpf': responsibleCpf,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// 🔎 Busca alunos vinculados a um responsável pelo CPF em uma escola específica
  Stream<List<DocumentSnapshot>> getStudentsForResponsibleByCpf(
      String schoolId, String cpf) {
    return _db
        .collection('escolas')
        .doc(schoolId)
        .collection('alunos')
        .where('responsibleCpf', isEqualTo: cpf)
        .snapshots()
        .map((snapshot) => snapshot.docs);
  }

  /// ✏️ Atualiza dados de um aluno
  Future<void> updateStudent(
      String schoolId, String studentId, Map<String, dynamic> data) async {
    await _db
        .collection('escolas')
        .doc(schoolId)
        .collection('alunos')
        .doc(studentId)
        .update(data);
  }

  /// ❌ Remove um aluno
  Future<void> deleteStudent(String schoolId, String studentId) async {
    await _db
        .collection('escolas')
        .doc(schoolId)
        .collection('alunos')
        .doc(studentId)
        .delete();
  }
}
