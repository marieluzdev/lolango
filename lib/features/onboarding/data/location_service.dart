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

  Future<String?> reverseGeocodeExact(double latitude, double longitude) async {
    final uri = Uri.parse(
      'https://nominatim.openstreetmap.org/reverse?format=jsonv2&lat=$latitude&lon=$longitude&accept-language=fr',
    );
    final response = await http.get(
      uri,
      headers: {'User-Agent': 'lolango_v2/1.0 (https://lolango-v2)'},
    );

    if (response.statusCode != 200) {
      throw StateError(
        'Impossible de récupérer l’adresse exacte depuis OpenStreetMap.',
      );
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;

    // display_name contient l'adresse complète et lisible (rue, quartier, ville, pays...)
    final displayName = body['display_name'] as String?;
    if (displayName != null && displayName.isNotEmpty) {
      return displayName;
    }

    final address = body['address'] as Map<String, dynamic>?;
    if (address == null || address.isEmpty) {
      throw StateError('Aucune adresse exacte trouvée pour cette position.');
    }

    final parts = <String>[
      if (address['house_number'] != null) address['house_number'] as String,
      if (address['road'] != null) address['road'] as String,
      if (address['suburb'] != null) address['suburb'] as String,
      if (address['city'] != null)
        address['city'] as String
      else if (address['town'] != null)
        address['town'] as String
      else if (address['village'] != null)
        address['village'] as String,
      if (address['country'] != null) address['country'] as String,
    ];

    if (parts.isEmpty) {
      throw StateError('Impossible de déterminer une adresse exacte.');
    }

    return parts.join(', ');
  }
}
