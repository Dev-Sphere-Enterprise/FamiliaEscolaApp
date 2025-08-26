import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});
  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();
  final _cpfCtrl = TextEditingController();
  final _birthDateCtrl = TextEditingController();

  bool _obscurePass = true;
  bool _obscureConfirm = true;
  bool _loading = false;
  bool _acceptTerms = false;
  String _role = "responsavel"; // padrão

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmPassCtrl.dispose();
    _cpfCtrl.dispose();
    _birthDateCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_acceptTerms) {
      _showSnack("Você deve aceitar os termos para continuar.", isError: true);
      return;
    }

    setState(() => _loading = true);
    User? userToDelete;

    try {
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text,
      );
      userToDelete = cred.user;
      final uid = cred.user!.uid;

      if (_role == "responsavel") {
        // ETAPA 1: Cria o documento do usuário sem a escolaId para satisfazer as regras
        await FirebaseFirestore.instance.collection("users").doc(uid).set({
          "nome": _nameCtrl.text.trim(),
          "email": _emailCtrl.text.trim(),
          "cpf": _cpfCtrl.text.trim(),
          "dataNascimento": _birthDateCtrl.text.trim(),
          "role": "responsavel",
          "escolaId": null,
          "createdAt": FieldValue.serverTimestamp(),
        });

        // ETAPA 2: Agora, a consulta aos alunos será permitida pelas novas regras
        final alunoSnap = await FirebaseFirestore.instance
            .collection("students")
            .where("responsibleCpf", isEqualTo: _cpfCtrl.text.trim())
            .limit(1)
            .get();

        if (alunoSnap.docs.isEmpty) {
          throw Exception("Nenhum aluno vinculado a esse CPF. Peça para a escola cadastrar o aluno primeiro.");
        }

        final escolaId = alunoSnap.docs.first["escolaId"];

        // ETAPA 3: Atualiza o documento do usuário com a escolaId correta
        await FirebaseFirestore.instance.collection("users").doc(uid).update({
          "escolaId": escolaId,
        });

      } else { // GESTOR
        final auth = AuthService();
        await auth.criarGestorEEscola(
          uid: uid,
          nomeGestor: _nameCtrl.text.trim(),
          email: _emailCtrl.text.trim(),
          cpf: _cpfCtrl.text.trim(),
          dataNascimento: _birthDateCtrl.text.trim(),
          nomeEscola: "Escola de ${_nameCtrl.text.trim()}",
        );
      }

      if (mounted) {
        Navigator.pop(context);
        _showSnack("Cadastro realizado com sucesso!", isError: false);
      }
    } on FirebaseAuthException catch (e) {
      _showSnack(_mapFirebaseError(e), isError: true);
    } catch (e) {
      if (userToDelete != null) {
        await userToDelete.delete();
      }
      _showSnack(e.toString().replaceFirst("Exception: ", ""), isError: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _mapFirebaseError(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'Este e-mail já está cadastrado.';
      case 'invalid-email':
        return 'E-mail inválido.';
      case 'weak-password':
        return 'A senha é muito fraca.';
      default:
        return 'Erro de autenticação: ${e.code}';
    }
  }

  void _showSnack(String msg, {bool isError = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? Colors.red : Colors.green,
    ));
  }

  @override
  Widget build(BuildContext context) {
    // O seu widget build continua o mesmo
    final maxWidth = 420.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F3F7),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Card(
                elevation: 0,
                color: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 28, 20, 28),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Column(
                            children: [
                              SizedBox(
                                height: 96,
                                child: Image.asset('assets/logo.png', fit: BoxFit.contain),
                              ),
                              const SizedBox(height: 8),
                              Text('Crie sua conta',
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),

                        TextFormField(
                          controller: _nameCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Nome', hintText: 'ex: Rian Wilker',
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) => v!.trim().isEmpty ? 'Informe o nome' : null,
                        ),
                        const SizedBox(height: 12),

                        TextFormField(
                          controller: _emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: 'Email', hintText: 'ex: jon.smith@email.com',
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) {
                            if (v!.trim().isEmpty) return 'Informe o e-mail';
                            if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v)) return 'E-mail inválido';
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),

                        TextFormField(
                          controller: _passCtrl,
                          obscureText: _obscurePass,
                          decoration: InputDecoration(
                            labelText: 'Senha',
                            border: const OutlineInputBorder(),
                            suffixIcon: IconButton(
                              icon: Icon(_obscurePass ? Icons.visibility_off : Icons.visibility),
                              onPressed: () => setState(() => _obscurePass = !_obscurePass),
                            ),
                          ),
                          validator: (v) {
                            if (v!.isEmpty) return 'Informe a senha';
                            if (v.length < 6) return 'Mínimo de 6 caracteres';
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),

                        TextFormField(
                          controller: _confirmPassCtrl,
                          obscureText: _obscureConfirm,
                          decoration: InputDecoration(
                            labelText: 'Confirme sua senha',
                            border: const OutlineInputBorder(),
                            suffixIcon: IconButton(
                              icon: Icon(_obscureConfirm ? Icons.visibility_off : Icons.visibility),
                              onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                            ),
                          ),
                          validator: (v) {
                            if (v!.isEmpty) return 'Confirme a senha';
                            if (v != _passCtrl.text) return 'As senhas não coincidem';
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),

                        TextFormField(
                          controller: _cpfCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'CPF', hintText: '123.456.789-10',
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) => v!.trim().isEmpty ? 'Informe o CPF' : null,
                        ),
                        const SizedBox(height: 12),

                        TextFormField(
                          controller: _birthDateCtrl,
                          keyboardType: TextInputType.datetime,
                          decoration: const InputDecoration(
                            labelText: 'Data de Nascimento', hintText: 'dd/mm/aaaa',
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) => v!.trim().isEmpty ? 'Informe a data de nascimento' : null,
                        ),
                        const SizedBox(height: 12),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ChoiceChip(
                              label: const Text("RESPONSÁVEL"),
                              selected: _role == "responsavel",
                              onSelected: (_) => setState(() => _role = "responsavel"),
                            ),
                            const SizedBox(width: 8),
                            ChoiceChip(
                              label: const Text("GESTOR"),
                              selected: _role == "gestao",
                              onSelected: (_) => setState(() => _role = "gestao"),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        Row(
                          children: [
                            Checkbox(
                              value: _acceptTerms,
                              onChanged: (v) => setState(() => _acceptTerms = v ?? false),
                            ),
                            const Expanded(child: Text("Eu aceito os termos")),
                          ],
                        ),
                        const SizedBox(height: 16),

                        FilledButton(
                          onPressed: _loading ? null : _register,
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            backgroundColor: const Color(0xFF19A75E),
                          ),
                          child: _loading
                              ? const SizedBox(
                            height: 20, width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                              : const Text('Cadastrar-se'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}