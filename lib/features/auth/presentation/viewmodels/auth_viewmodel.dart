import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:lolango_v2/features/auth/data/auth_repository.dart';

class AuthViewModel extends StateNotifier<AsyncValue<User?>> {
  final AuthRepository _authRepository;
  late final StreamSubscription<AuthState> _authStateSubscription;

  AuthViewModel(this._authRepository)
    : super(AsyncData(_authRepository.currentUser)) {
    _authStateSubscription = _authRepository.authStateChanges.listen((data) {
      state = AsyncData(data.session?.user);
    });
  }

  @override
  void dispose() {
    _authStateSubscription.cancel();
    super.dispose();
  }

  /// Étape 1 : ouvre le sélecteur de compte Google, sans créer de session.
  Future<GoogleSignInAccount?> authenticateWithGoogle() async {
    try {
      return await _authRepository.authenticateWithGoogle();
    } catch (e, st) {
      state = AsyncError(e, st);
      return null;
    }
  }

  /// Étape 2 : finalise la connexion après confirmation dans le bottom modal.
  String getGoogleFirstName(GoogleSignInAccount googleUser) {
    return _authRepository.resolveFirstNameFromGoogle(googleUser);
  }

  Future<void> completeSignInWithGoogle(GoogleSignInAccount googleUser) async {
    try {
      await _authRepository.completeSignInWithGoogle(googleUser);
      // Le stream onAuthStateChange met à jour le state automatiquement.
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> signOut() async {
    try {
      await _authRepository.signOut();
      // Le stream onAuthStateChange met à jour le state automatiquement.
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}

final authViewModelProvider =
    StateNotifierProvider<AuthViewModel, AsyncValue<User?>>((ref) {
      return AuthViewModel(ref.watch(authRepositoryProvider));
    });
