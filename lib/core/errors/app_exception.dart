class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;

  AppException(this.message, {this.code, this.originalError});

  factory AppException.from(dynamic e) {
    // Basic mapping, can be expanded based on specific exceptions (e.g. SocketException, PostgrestException)
    final errorStr = e.toString().toLowerCase();
    if (errorStr.contains('socketexception') ||
        errorStr.contains('failed host lookup')) {
      return AppException(
        'Pas de connexion internet. Veuillez vérifier votre réseau.',
        originalError: e,
      );
    }
    if (errorStr.contains('postgrestexception')) {
      return AppException(
        'Impossible de charger les données pour le moment.',
        originalError: e,
      );
    }
    if (errorStr.contains('timeout')) {
      return AppException('La requête a pris trop de temps.', originalError: e);
    }
    if (errorStr.contains('authexception') ||
        errorStr.contains('invalid login credentials')) {
      return AppException(
        'Erreur d\'authentification. Veuillez vérifier vos identifiants.',
        originalError: e,
      );
    }
    if (errorStr.contains('not found')) {
      return AppException('Ressource introuvable.', originalError: e);
    }
    return AppException(
      'Une erreur inattendue est survenue.',
      originalError: e,
    );
  }

  @override
  String toString() => message;
}
