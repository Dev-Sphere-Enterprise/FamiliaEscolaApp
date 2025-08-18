import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:FamiliaEscolaApp/services/auth_service.dart';

class StudentService {
  final _db = FirebaseFirestore.instance;
  final AuthService _authService = AuthService();

  Future<void> addStudent({
    required String studentName,
    required String studentBirthDate,
    required String responsibleName,
    required String responsibleCpf,
  }) async {
    // 1. Criar o documento do aluno
    final studentRef = await _db.collection('students').add({
      'name': studentName,
      'birthDate': studentBirthDate,
      'responsibleName': responsibleName,
      'responsibleCpf': responsibleCpf,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // 2. Procurar pelo responsável com o CPF fornecido
    final responsibleQuery = await _db
        .collection('users')
        .where('cpf', isEqualTo: responsibleCpf)
        .limit(1)
        .get();

    if (responsibleQuery.docs.isNotEmpty) {
      final responsibleDoc = responsibleQuery.docs.first;
      final responsibleId = responsibleDoc.id;

      // 3. Vincular o aluno ao responsável
      await _db.collection('users').doc(responsibleId).update({
        'alunosVinculados': FieldValue.arrayUnion([studentRef.id])
      });
    } else {
      // Opcional: Lidar com o caso de não encontrar um responsável
      print('Nenhum responsável encontrado com o CPF: $responsibleCpf');
    }
  }

  // Novo método para buscar os alunos de um responsável
  Stream<List<DocumentSnapshot>> getStudentsForResponsible(String responsibleId) {
    return _db
        .collection('users')
        .doc(responsibleId)
        .snapshots()
        .asyncMap((userDoc) async {
      final studentIds = List<String>.from(userDoc.data()?['alunosVinculados'] ?? []);
      if (studentIds.isEmpty) {
        return [];
      }
      final studentDocs = await _db
          .collection('students')
          .where(FieldPath.documentId, whereIn: studentIds)
          .get();
      return studentDocs.docs;
    });
  }
}