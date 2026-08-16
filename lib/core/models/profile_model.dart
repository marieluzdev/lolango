class ProfileModel {
  final String id;
  final String name;
  final String username;
  final int? age;
  final String? city;
  final String? country;
  final String? gender;
  final String? bio;
  final List<String> photoUrls;
  final Map<String, String> socials;
  final List<String> interests;
  final List<String> discoveryPreferences;

  ProfileModel({
    required this.id,
    required this.name,
    this.username = '',
    this.age,
    this.city,
    this.country,
    this.gender,
    this.bio,
    List<String>? photoUrls,
    Map<String, String>? socials,
    List<String>? interests,
    List<String>? discoveryPreferences,
  })  : photoUrls = photoUrls ?? [],
        socials = socials ?? {},
        interests = interests ?? [],
        discoveryPreferences = discoveryPreferences ?? [];

  /// Getter de compatibilité — retourne la première photo ou null.
  String? get photoUrl => photoUrls.isNotEmpty ? photoUrls.first : null;

  factory ProfileModel.fromMap(
    Map<String, dynamic> m, {
    Map<String, String>? socialsOverride,
    List<String>? photoUrlsOverride,
    List<String>? interestsOverride,
  }) {
    // Calcul de l'âge depuis birth_date (comme dans Profil).
    int? age;
    final ageRaw = m['age'];
    if (ageRaw is int) {
      age = ageRaw;
    } else if (ageRaw is String) {
      age = int.tryParse(ageRaw);
    }
    if (age == null) {
      final birthDateRaw = m['birth_date'];
      if (birthDateRaw is String && birthDateRaw.isNotEmpty) {
        try {
          final birthDate = DateTime.parse(birthDateRaw);
          final now = DateTime.now();
          age = now.year - birthDate.year;
          if (now.month < birthDate.month ||
              (now.month == birthDate.month && now.day < birthDate.day)) {
            age -= 1;
          }
        } catch (_) {}
      }
    }

    // discovery_preferences
    List<String> prefs = [];
    final rawPrefs = m['discovery_preferences'];
    if (rawPrefs is List) {
      prefs = rawPrefs.map((e) => e.toString()).toList();
    }

    // Photos : depuis l'override injecté par le repository, sinon depuis la map.
    List<String> photoUrls = photoUrlsOverride ?? [];
    if (photoUrls.isEmpty) {
      final rawPhotos = m['photos'];
      if (rawPhotos is List) {
        for (final p in rawPhotos) {
          if (p is Map<String, dynamic>) {
            final url = p['url']?.toString();
            if (url != null && url.isNotEmpty) photoUrls.add(url);
          } else if (p is String && p.isNotEmpty) {
            photoUrls.add(p);
          }
        }
      }
      // Fallback sur photo_url / avatar_url unique.
      if (photoUrls.isEmpty) {
        final single = m['photo_url']?.toString() ?? m['avatar_url']?.toString();
        if (single != null && single.isNotEmpty) photoUrls.add(single);
      }
    }

    // Réseaux sociaux.
    Map<String, String> socials = socialsOverride ?? {};
    if (socials.isEmpty) {
      final rawSocials = m['socials'];
      if (rawSocials is Map<String, dynamic>) {
        socials = Map<String, String>.from(rawSocials);
      }
    }

    // Intérêts.
    List<String> interests = interestsOverride ?? [];
    if (interests.isEmpty) {
      final rawInterests = m['interests'];
      if (rawInterests is List) {
        for (final i in rawInterests) {
          final s = i?.toString();
          if (s != null && s.isNotEmpty) interests.add(s);
        }
      }
    }

    return ProfileModel(
      id: m['id']?.toString() ?? '',
      name: m['first_name']?.toString() ??
          m['display_name']?.toString() ??
          m['name']?.toString() ??
          'Nom',
      username: m['username']?.toString() ?? '',
      age: age,
      city: m['location_label']?.toString() ?? m['city']?.toString(),
      country: m['country']?.toString(),
      gender: m['gender']?.toString(),
      bio: m['bio']?.toString(),
      photoUrls: photoUrls,
      socials: socials,
      interests: interests,
      discoveryPreferences: prefs,
    );
  }
}
