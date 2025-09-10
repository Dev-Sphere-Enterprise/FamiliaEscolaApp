class CpfUtils {
  /// Mantém apenas números no CPF
  static String normalize(String cpf) {
    return cpf.replaceAll(RegExp(r'[^0-9]'), '');
  }

  /// Formata para o padrão 000.000.000-00
  static String format(String cpf) {
    final onlyNumbers = normalize(cpf);
    if (onlyNumbers.length != 11) return cpf;
    return "${onlyNumbers.substring(0, 3)}."
        "${onlyNumbers.substring(3, 6)}."
        "${onlyNumbers.substring(6, 9)}-"
        "${onlyNumbers.substring(9)}";
  }
}
