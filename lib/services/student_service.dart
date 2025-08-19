import 'package:cloud_firestore/cloud_firestore.dart';

class StudentService {
  final _db = FirebaseFirestore.instance;

  /// Adiciona um novo aluno vinculado ao CPF do responsável
  Future<void> addStudent({
    required String studentName,
    required String studentBirthDate,
    required String responsibleName,
    required String responsibleCpf,
  }) async {
    await _db.collection('students').add({
      'name': studentName,
      'birthDate': studentBirthDate,
      'responsibleName': responsibleName,
      'responsibleCpf': responsibleCpf,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Busca alunos vinculados a um responsável pelo CPF
  Stream<List<DocumentSnapshot>> getStudentsForResponsibleByCpf(String cpf) {
    return _db
        .collection('students')
        .where('responsibleCpf', isEqualTo: cpf)
        .snapshots()
        .map((snapshot) => snapshot.docs);
  }

  /// Atualiza dados de um aluno
  Future<void> updateStudent(String studentId, Map<String, dynamic> data) async {
    await _db.collection('students').doc(studentId).update(data);
  }

  /// Remove um aluno
  Future<void> deleteStudent(String studentId) async {
    await _db.collection('students').doc(studentId).delete();
  }
}
