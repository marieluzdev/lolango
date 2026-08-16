import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

final locationServiceProvider = Provider<LocationService>((ref) {
  return LocationService();
});

class LocationService {
  Future<Position> determinePosition() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw StateError(
        'Service de localisation désactivé. Active la localisation dans les paramètres et réessaie.',
      );
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      throw StateError('Autorisation de localisation refusée.');
    }

    if (permission == LocationPermission.deniedForever) {
      throw StateError(
        'Autorisation de localisation refusée définitivement. Active-la dans les paramètres.',
      );
    }

    return Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.best,
    );
  }

  Future<String?> reverseGeocode(double latitude, double longitude) async {
    final uri = Uri.parse(
      'https://nominatim.openstreetmap.org/reverse?format=jsonv2&lat=$latitude&lon=$longitude&accept-language=fr',
    );
    final response = await http.get(
      uri,
      headers: {'User-Agent': 'lolango_v2/1.0 (https://lolango-v2)'},
    );

    if (response.statusCode != 200) {
      throw StateError(
        'Impossible de récupérer la localisation depuis OpenStreetMap.',
      );
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final address = body['address'] as Map<String, dynamic>?;
    if (address == null || address.isEmpty) {
      throw StateError('Aucune adresse trouvée pour cette position.');
    }

    final locality =
        address['city'] ??
        address['town'] ??
        address['village'] ??
        address['hamlet'] ??
        address['municipality'];
    final region = address['state'] ?? address['county'] ?? address['region'];
    final country = address['country'];

    if (locality != null && country != null) {
      return '$locality, $country';
    }
    if (region != null && country != null) {
      return '$region, $country';
    }
    if (country != null) {
      return country as String;
    }

    throw StateError(
      'Impossible de déterminer une localisation approximative.',
    );
  }
}
