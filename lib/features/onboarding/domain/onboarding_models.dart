class ProfilePhoto {
  final String url;
  final bool isPrimary;

  const ProfilePhoto({required this.url, this.isPrimary = false});

  ProfilePhoto copyWith({String? url, bool? isPrimary}) {
    return ProfilePhoto(
      url: url ?? this.url,
      isPrimary: isPrimary ?? this.isPrimary,
    );
  }

  Map<String, dynamic> toJson() => {
        'url': url,
        'is_primary': isPrimary,
      };
}

class OnboardingProfile {
  final String firstName;
  final String username;
  final DateTime? birthDate;
  final String? gender;
  final List<String> discoveryPreferences;
  final String? locationLabel;
  final double? latitude;
  final double? longitude;
  final List<String> selectedInterests;
  final List<ProfilePhoto> photos;
  final Map<String, String> socials;
  final String bio;
  final bool usernameCheckPending;
  final bool usernameAvailable;

  const OnboardingProfile({
    this.firstName = '',
    this.username = '',
    this.birthDate,
    this.gender,
    this.discoveryPreferences = const [],
    this.locationLabel,
    this.latitude,
    this.longitude,
    this.selectedInterests = const [],
    this.photos = const [],
    this.socials = const {},
    this.bio = '',
    this.usernameCheckPending = false,
    this.usernameAvailable = false,
  });

  OnboardingProfile.initial()
      : this(
          firstName: '',
          username: '',
          gender: null,
          discoveryPreferences: const [],
          locationLabel: null,
          latitude: null,
          longitude: null,
          selectedInterests: const [],
          photos: const [],
          socials: const {},
          bio: '',
          usernameCheckPending: false,
          usernameAvailable: false,
        );

  String get normalizedUsername {
    return username.replaceFirst('@', '').trim();
  }

  bool get usernameIsValid {
    final normalized = normalizedUsername;
    return normalized.isNotEmpty &&
        normalized.length >= 3 &&
        normalized.contains(RegExp(r'^[a-zA-Z0-9._]+$')) &&
        usernameAvailable;
  }

  bool get isProfileReady {
    return firstName.trim().isNotEmpty &&
        usernameIsValid &&
        birthDate != null &&
        gender != null &&
        discoveryPreferences.isNotEmpty &&
        locationLabel != null &&
        selectedInterests.isNotEmpty &&
        photos.isNotEmpty &&
        bio.trim().isNotEmpty;
  }

  OnboardingProfile copyWith({
    String? firstName,
    String? username,
    DateTime? birthDate,
    String? gender,
    List<String>? discoveryPreferences,
    String? locationLabel,
    double? latitude,
    double? longitude,
    List<String>? selectedInterests,
    List<ProfilePhoto>? photos,
    Map<String, String>? socials,
    String? bio,
    bool? usernameCheckPending,
    bool? usernameAvailable,
  }) {
    return OnboardingProfile(
      firstName: firstName ?? this.firstName,
      username: username ?? this.username,
      birthDate: birthDate ?? this.birthDate,
      gender: gender ?? this.gender,
      discoveryPreferences: discoveryPreferences ?? this.discoveryPreferences,
      locationLabel: locationLabel ?? this.locationLabel,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      selectedInterests: selectedInterests ?? this.selectedInterests,
      photos: photos ?? this.photos,
      socials: socials ?? this.socials,
      bio: bio ?? this.bio,
      usernameCheckPending: usernameCheckPending ?? this.usernameCheckPending,
      usernameAvailable: usernameAvailable ?? this.usernameAvailable,
    );
  }

  Map<String, dynamic> toSupabasePayload(String userId) {
    final usernameValue = username.startsWith('@') ? username : '@$username';
    final normalizedFirstName = firstName.trim();
    final normalizedBio = bio.trim();

    return {
      'id': userId,
      'first_name': normalizedFirstName,
      'username': usernameValue,
      'birth_date': birthDate?.toIso8601String(),
      'gender': gender,
      'discovery_preferences': discoveryPreferences,
      'location_label': locationLabel,
      'latitude': latitude,
      'longitude': longitude,
      'selected_interests': selectedInterests,
      'profile_photos': photos.map((photo) => photo.toJson()).toList(),
      'social_links': socials,
      'bio': normalizedBio,
      'profile_completed': true,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
      'created_at': DateTime.now().toUtc().toIso8601String(),
    };
  }
}

const List<String> onboardingGenderOptions = ['Homme', 'Femme'];

const List<String> onboardingDiscoveryOptions = ['Hommes', 'Femmes'];

const List<OnboardingInterestCategory> onboardingInterestCategories = [
  OnboardingInterestCategory(
    emoji: '🎨',
    name: 'Arts & Culture',
    interests: [
      'Musique',
      'Chant',
      'Danse',
      'Cinéma',
      'Séries',
      'Théâtre',
      'Photographie',
      'Dessin',
      'Peinture',
      'Écriture',
      'Poésie',
    ],
  ),
  OnboardingInterestCategory(
    emoji: '💻',
    name: 'Tech',
    interests: [
      'Programmation',
      'Flutter',
      'Développement Web',
      'Intelligence artificielle',
      'Cybersécurité',
      'Design UI/UX',
      'Jeux vidéo',
      'Robotique',
    ],
  ),
  OnboardingInterestCategory(
    emoji: '📚',
    name: 'Études',
    interests: [
      'Lecture',
      'Mathématiques',
      'Sciences',
      'Économie',
      'Finance',
      'Marketing',
      'Entrepreneuriat',
      'Langues étrangères',
    ],
  ),
  OnboardingInterestCategory(
    emoji: '⚽',
    name: 'Sport',
    interests: [
      'Football',
      'Basketball',
      'Volleyball',
      'Tennis',
      'Natation',
      'Running',
      'Salle de sport',
      'Arts martiaux',
      'Randonnée',
      'Cyclisme',
    ],
  ),
  OnboardingInterestCategory(
    emoji: '✈️',
    name: 'Voyage & Lifestyle',
    interests: [
      'Voyage',
      'Road trips',
      'Découverte de restaurants',
      'Café',
      'Cuisine',
      'Pâtisserie',
      'Mode',
      'Shopping',
      'Décoration',
    ],
  ),
  OnboardingInterestCategory(
    emoji: '🎮',
    name: 'Divertissement',
    interests: [
      'Gaming',
      'Anime & Manga',
      'Échecs',
      'Jeux de société',
      'Quiz',
      'Streaming',
    ],
  ),
  OnboardingInterestCategory(
    emoji: '🤝',
    name: 'Vie sociale',
    interests: [
      'Faire de nouvelles rencontres',
      'Sorties entre amis',
      'Soirées',
      'Bénévolat',
      'Networking',
      'Débats',
    ],
  ),
  OnboardingInterestCategory(
    emoji: '🔥',
    name: 'Ambition',
    interests: [
      'Startups',
      'Freelance',
      'Création de contenu',
      'Investissement',
      'Trading',
      'Développement personnel',
      'Productivité',
    ],
  ),
  OnboardingInterestCategory(
    emoji: '🌿',
    name: 'Nature',
    interests: [
      'Jardinage',
      'Animaux',
      'Écologie',
      'Camping',
      'Pêche',
    ],
  ),
  OnboardingInterestCategory(
    emoji: '🧘',
    name: 'Bien-être',
    interests: [
      'Méditation',
      'Yoga',
      'Spiritualité',
      'Nutrition',
    ],
  ),
];

class OnboardingInterestCategory {
  final String emoji;
  final String name;
  final List<String> interests;

  const OnboardingInterestCategory({
    required this.emoji,
    required this.name,
    required this.interests,
  });
}
