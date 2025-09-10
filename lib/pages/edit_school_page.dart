import 'package:flutter/material.dart';
import '../services/school_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditSchoolPage extends StatefulWidget {
  final DocumentSnapshot schoolDocument;

  const EditSchoolPage({super.key, required this.schoolDocument});

  @override
  State<EditSchoolPage> createState() => _EditSchoolPageState();
}

class _EditSchoolPageState extends State<EditSchoolPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _schoolNameCtrl;
  late TextEditingController _schoolTypeCtrl;
  late TextEditingController _otherDataCtrl;
  late TextEditingController _addressCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _emailCtrl;

  bool _loading = false;
  final SchoolService _schoolService = SchoolService();

  @override
  void initState() {
    super.initState();
    final schoolData = widget.schoolDocument.data() as Map<String, dynamic>;
    _schoolNameCtrl = TextEditingController(text: schoolData['nome'] ?? '');
    _schoolTypeCtrl = TextEditingController(text: schoolData['tipo'] ?? '');
    _otherDataCtrl = TextEditingController(text: schoolData['outros_dados'] ?? '');
    _addressCtrl = TextEditingController(text: schoolData['endereco'] ?? '');
    _phoneCtrl = TextEditingController(text: schoolData['telefone'] ?? '');
    _emailCtrl = TextEditingController(text: schoolData['email'] ?? '');
  }

  @override
  void dispose() {
    _schoolNameCtrl.dispose();
    _schoolTypeCtrl.dispose();
    _otherDataCtrl.dispose();
    _addressCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _updateSchool() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      await _schoolService.updateSchool(
        schoolId: widget.schoolDocument.id,
        schoolName: _schoolNameCtrl.text.trim(),
        schoolType: _schoolTypeCtrl.text.trim(),
        otherData: _otherDataCtrl.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Escola atualizada com sucesso!'),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
        Navigator.pop(context); // Volta para tela anterior
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao atualizar escola: $e'),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Editar Escola',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 20,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF00A74F),
        foregroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _loading
          ? const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00A74F)),
        ),
      )
          : SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: const Color(0xFF00A74F).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.school,
                        size: 26,
                        color: Color(0xFF00A74F),
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Text(
                        'Editar informações da escola',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2D3748),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // Nome da Escola
              _buildFormField(
                controller: _schoolNameCtrl,
                label: 'Nome da Escola',
                icon: Icons.business,
                validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null,
                isRequired: true,
              ),

              const SizedBox(height: 20),

              // Tipo de Escola
              _buildFormField(
                controller: _schoolTypeCtrl,
                label: 'Tipo de Escola',
                icon: Icons.category,
                hint: 'Ex: Pública, Particular, Municipal',
                validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null,
                isRequired: true,
              ),

              const SizedBox(height: 20),

              const SizedBox(height: 20),

              // Outras Informações
              _buildFormField(
                controller: _otherDataCtrl,
                label: 'Outras Informações',
                icon: Icons.info_outline,
                hint: 'Informações adicionais sobre a escola',
                maxLines: 4,
              ),

              const SizedBox(height: 32),

              // Botão Salvar
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _updateSchool,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00A74F),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Salvar Alterações',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Botão Cancelar
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    side: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  child: const Text(
                    'Cancelar',
                    style: TextStyle(
                      color: Color(0xFF4A5568),
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    int maxLines = 1,
    bool isRequired = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: const Color(0xFF00A74F)),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xFF2D3748),
              ),
            ),
            if (isRequired)
              const Text(
                ' *',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF00A74F), width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
          validator: validator,
          keyboardType: keyboardType,
          maxLines: maxLines,
          textInputAction: maxLines > 1 ? TextInputAction.newline : TextInputAction.next,
        ),
      ],
    );
  }
}