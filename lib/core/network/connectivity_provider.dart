import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Stream temps réel de l'état de la connectivité.
final connectivityStreamProvider = StreamProvider<List<ConnectivityResult>>((ref) {
  return Connectivity().onConnectivityChanged;
});

/// `true` si au moins une interface réseau est disponible (Wi-Fi, mobile, ethernet…).
final isConnectedProvider = Provider<bool>((ref) {
  final result = ref.watch(connectivityStreamProvider).valueOrNull;
  if (result == null) return true; // On suppose connecté jusqu'à preuve du contraire
  return result.any((r) => r != ConnectivityResult.none);
});
