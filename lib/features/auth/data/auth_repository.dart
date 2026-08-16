import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:lolango_v2/core/supabase/supabase_client.dart';
import 'package:lolango_v2/core/config/env.dart';
import 'package:lolango_v2/core/errors/app_exception.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(supabaseProvider));
});

class AuthRepository {
  final SupabaseClient _supabase;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  bool _isGoogleSignInInitialized = false;

  static const List<String> _googleScopes = ['email', 'profile'];

  AuthRepository(this._supabase);

  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;
  User? get currentUser => _supabase.auth.currentUser;

  /// Initialise le SDK Google Sign-In. À appeler une seule fois avant tout
  /// autre appel (authenticate, signOut, etc.) — bonne pratique : le faire
  /// une fois au démarrage de l'app plutôt qu'à chaque tentative de connexion.
  Future<void> ensureGoogleSignInInitialized() async {
    if (_isGoogleSignInInitialized) return;
    await _googleSignIn.initialize(serverClientId: Env.googleWebClientId);
    _isGoogleSignInInitialized = true;
  }

  /// Étape 1 — Authentification Google uniquement.
  /// Ouvre le sélecteur de compte natif et retourne le compte choisi,
  /// SANS encore créer de session Supabase. Permet d'afficher le bottom
  /// modal de confirmation avant de finaliser la connexion.
  Future<GoogleSignInAccount> authenticateWithGoogle() async {
    await ensureGoogleSignInInitialized();

    if (!_googleSignIn.supportsAuthenticate()) {
      throw AppException(
        "La connexion Google n'est pas supportée sur cette plateforme.",
      );
    }

    try {
      return await _googleSignIn.authenticate();
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        throw AppException('Connexion annulée par l\'utilisateur.');
      }
      throw AppException('Échec de la connexion Google : ${e.description}');
    }
  }

  String resolveFirstNameFromGoogle(GoogleSignInAccount account) {
    final raw = (account.displayName ?? account.email).trim();
    if (raw.isEmpty) {
      return '';
    }

    final normalized = raw.replaceAll(RegExp(r'\s+'), ' ').trim();
    final name = normalized
        .split(RegExp(r'\s+'))
        .firstWhere((part) => part.trim().isNotEmpty, orElse: () => '');

    return name;
  }

  /// Étape 2 — Autorisation + finalisation de la session Supabase,
  /// une fois que l'utilisateur a confirmé le compte dans le bottom modal.
  Future<AuthResponse> completeSignInWithGoogle(
    GoogleSignInAccount googleUser,
  ) async {
    final idToken = googleUser.authentication.idToken;
    if (idToken == null) {
      throw AppException('Aucun ID Token trouvé.');
    }

    // Autorisation (accessToken) séparée de l'authentification depuis v7.
    final authorization =
        await googleUser.authorizationClient.authorizationForScopes(
          _googleScopes,
        ) ??
        await googleUser.authorizationClient.authorizeScopes(_googleScopes);

    return _supabase.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
      accessToken: authorization.accessToken,
    );
  }

  Future<void> signOut() async {
    await ensureGoogleSignInInitialized();
    await _googleSignIn.signOut();
    await _supabase.auth.signOut();
  }
}
