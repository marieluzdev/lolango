sealed class Failure {
  final String message;
  final dynamic originalError;

  const Failure(this.message, {this.originalError});

  factory Failure.from(dynamic e) {
    if (e is Failure) return e;

    final errorStr = e.toString().toLowerCase();

    if (errorStr.contains('socketexception') ||
        errorStr.contains('failed host lookup') ||
        errorStr.contains('network')) {
      return NetworkFailure(
        'Pas de connexion internet. Veuillez vérifier votre réseau.',
        originalError: e,
      );
    }
    if (errorStr.contains('postgrestexception') ||
        errorStr.contains('server')) {
      return ServerFailure(
        'Impossible de charger les données pour le moment.',
        originalError: e,
      );
    }
    if (errorStr.contains('timeout')) {
      return NetworkFailure(
        'La requête a pris trop de temps.',
        originalError: e,
      );
    }
    if (errorStr.contains('authexception') ||
        errorStr.contains('invalid login credentials')) {
      return AuthFailure(
        'Erreur d\'authentification. Veuillez vérifier vos identifiants.',
        originalError: e,
      );
    }
    return UnexpectedFailure(
      'Une erreur inattendue est survenue.',
      originalError: e,
    );
  }
}

class NetworkFailure extends Failure {
  const NetworkFailure(super.message, {super.originalError});
}

class ServerFailure extends Failure {
  const ServerFailure(super.message, {super.originalError});
}

class AuthFailure extends Failure {
  const AuthFailure(super.message, {super.originalError});
}

class CacheFailure extends Failure {
  const CacheFailure(super.message, {super.originalError});
}

class UnexpectedFailure extends Failure {
  const UnexpectedFailure(super.message, {super.originalError});
}
