import 'profile_model.dart';

class DetailedProfileModel {
  final ProfileModel profile;
  final List<String> photoUrls;
  final Map<String, String> _socials;
  final List<String> interests;

  String? get city => profile.city;
  String? get country => profile.country;
  String? get bio => profile.bio;
  Map<String, String> get socials => _socials;
  String? get socialVisibility => profile.socialVisibility;
  List<String>? get visibleSocials => profile.visibleSocials;

  Map<String, String> filteredSocials(bool isMatched) {
    if (socialVisibility == 'always') {
      return socials;
    }
    
    if (socialVisibility == 'after_match') {
      return isMatched ? socials : {};
    }
    
    if (socialVisibility == 'selective') {
      if (visibleSocials == null || visibleSocials!.isEmpty) return {};
      return Map.fromEntries(
        socials.entries.where((e) => visibleSocials!.contains(e.key))
      );
    }
    
    // Default to after_match logic if not set
    return isMatched ? socials : {};
  }

  DetailedProfileModel({
    required this.profile,
    this.photoUrls = const [],
    Map<String, String> socials = const {},
    this.interests = const [],
  }) : _socials = socials;

  /// The main photo URL (usually the first one in the gallery).
  String? get primaryPhotoUrl =>
      photoUrls.isNotEmpty ? photoUrls.first : profile.photoUrl;

  /// Creates a DetailedProfileModel from a Map and optional overrides.
  factory DetailedProfileModel.fromMap(
    Map<String, dynamic> m, {
    Map<String, String>? socialsOverride,
    List<String>? photoUrlsOverride,
    List<String>? interestsOverride,
  }) {
    // Basic profile initialization
    final profile = ProfileModel.fromMap(
      m,
      socialsOverride: socialsOverride,
      photoUrlsOverride: photoUrlsOverride,
      interestsOverride: interestsOverride,
    );

    // Photos
    List<String> photos = photoUrlsOverride ?? [];
    if (photos.isEmpty) {
      final rawPhotos = m['photos'];
      if (rawPhotos is List) {
        for (final p in rawPhotos) {
          if (p is Map<String, dynamic>) {
            final url = p['url']?.toString();
            if (url != null && url.isNotEmpty) photos.add(url);
          } else if (p is String && p.isNotEmpty) {
            photos.add(p);
          }
        }
      }
    }

    // Fallback on basic profile photos if still empty
    if (photos.isEmpty) {
      photos = profile.photoUrls;
    }

    // Socials
    Map<String, String> socials = socialsOverride ?? {};
    if (socials.isEmpty) {
      final rawSocials = m['socials'];
      if (rawSocials is Map<String, dynamic>) {
        socials = Map<String, String>.from(rawSocials);
      } else if (rawSocials is List) {
        // Handling case where socials come as a list of records (e.g., from DB join)
        for (final s in rawSocials) {
          if (s is Map<String, dynamic>) {
            final platform = s['platform']?.toString();
            final username = s['username']?.toString();
            if (platform != null && username != null) {
              socials[platform] = username;
            }
          }
        }
      }
    }
    if (socials.isEmpty) socials = profile.socials;

    // Interests
    List<String> interests = interestsOverride ?? [];
    if (interests.isEmpty) {
      final rawInterests = m['interests'];
      if (rawInterests is List) {
        for (final i in rawInterests) {
          if (i is Map<String, dynamic>) {
            // Nested structure like { interests: { name: '...' } }
            final interestMap = i['interests'];
            if (interestMap is Map<String, dynamic>) {
              final name = interestMap['name']?.toString();
              if (name != null && name.isNotEmpty) interests.add(name);
            }
          } else {
            final s = i?.toString();
            if (s != null && s.isNotEmpty && s != 'null') interests.add(s);
          }
        }
      }
    }
    if (interests.isEmpty) interests = profile.interests;

    return DetailedProfileModel(
      profile: profile,
      photoUrls: photos,
      socials: socials,
      interests: interests,
    );
  }
}
