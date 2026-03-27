/// Validatori condivisi tra le schermate auth
class BwValidators {
  BwValidators._();

  /// Email RFC 5322 semplificato
  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Inserisci la tua email';
    }
    final regex = RegExp(r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$');
    if (!regex.hasMatch(value.trim())) {
      return 'Inserisci un\'email valida';
    }
    return null;
  }

  /// Password solo per login (min 1 char)
  static String? loginPassword(String? value) {
    if (value == null || value.isEmpty) return 'Inserisci la password';
    return null;
  }

  /// Password per registrazione (min 8 char)
  static String? registerPassword(String? value) {
    if (value == null || value.isEmpty) return 'Inserisci una password';
    if (value.length < 8) return 'Minimo 8 caratteri';
    return null;
  }

  /// Conferma password
  static String? Function(String?) confirmPassword(String password) {
    return (String? value) {
      if (value == null || value.isEmpty) return 'Conferma la password';
      if (value != password) return 'Le password non coincidono';
      return null;
    };
  }

  /// Nome utente
  static String? name(String? value) {
    if (value == null || value.trim().isEmpty) return 'Inserisci il tuo nome';
    if (value.trim().length < 2) return 'Minimo 2 caratteri';
    return null;
  }
}

/// Calcola la forza della password (0-4)
class PasswordStrength {
  final int score; // 0=vuota, 1=debole, 2=media, 3=forte, 4=molto forte
  const PasswordStrength(this.score);

  static PasswordStrength of(String password) {
    if (password.isEmpty) return const PasswordStrength(0);
    int score = 0;
    if (password.length >= 8) score++;
    if (password.contains(RegExp(r'[A-Z]'))) score++;
    if (password.contains(RegExp(r'[0-9]'))) score++;
    if (password.length >= 12 && password.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>]'))) score++;
    return PasswordStrength(score.clamp(1, 4));
  }

  String get label {
    switch (score) {
      case 0: return '';
      case 1: return 'Debole';
      case 2: return 'Media';
      case 3: return 'Forte';
      default: return 'Molto forte';
    }
  }

  // Colori da spec: #D95F3B → #E8A838 → #2A7F6F → #4A8AB8
  int get colorHex {
    switch (score) {
      case 1: return 0xFFD95F3B;
      case 2: return 0xFFE8A838;
      case 3: return 0xFF2A7F6F;
      default: return 0xFF4A8AB8;
    }
  }
}
