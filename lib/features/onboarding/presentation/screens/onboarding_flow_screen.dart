import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lolango_v2/core/constants/app_colors.dart';
import 'package:lolango_v2/features/onboarding/data/location_service.dart';
import 'package:lolango_v2/features/onboarding/domain/onboarding_models.dart';
import 'package:lolango_v2/features/onboarding/presentation/viewmodels/onboarding_viewmodel.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class OnboardingFlowScreen extends ConsumerStatefulWidget {
  final String? initialFirstName;

  const OnboardingFlowScreen({super.key, this.initialFirstName});

  @override
  ConsumerState<OnboardingFlowScreen> createState() =>
      _OnboardingFlowScreenState();
}

class _OnboardingFlowScreenState extends ConsumerState<OnboardingFlowScreen> {
  final PageController _pageController = PageController();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final List<TextEditingController> _socialControllers = [
    TextEditingController(),
    TextEditingController(),
    TextEditingController(),
  ];

  int _currentStep = 0;
  final List<OnboardingInterestCategory> _categories =
      onboardingInterestCategories;
  final Set<String> _selectedInterests = <String>{};
  final Set<String> _discoveryPreferences = <String>{};
  final List<XFile> _pickedPhotos = <XFile>[];
  String? _gender;
  DateTime? _birthDate;
  String? _locationLabel;
  double? _locationLatitude;
  double? _locationLongitude;
  bool _locationAttempted = false;
  bool _isLocationLoading = false;
  String? _locationError;
  bool _isCheckingUsername = false;
  bool _usernameAvailable = false;
  bool _isSubmitting = false;

  // ============================================================
  // DATE DE NAISSANCE — roues défilantes (façon capture de référence)
  // ============================================================
  static const List<String> _months = [
    'janvier',
    'février',
    'mars',
    'avril',
    'mai',
    'juin',
    'juillet',
    'août',
    'septembre',
    'octobre',
    'novembre',
    'décembre',
  ];
  static const int _minBirthYear = 1940;
  late int _selectedDay;
  late int _selectedMonthIndex;
  late int _selectedYear;
  late final FixedExtentScrollController _dayController;
  late final FixedExtentScrollController _monthController;
  late final FixedExtentScrollController _yearController;
  late final List<int> _birthYears;

  @override
  void initState() {
    super.initState();

    final initialFirstName = (widget.initialFirstName ?? '').trim();
    if (initialFirstName.isNotEmpty) {
      _firstNameController.text = initialFirstName;
    }

    // Valeur par défaut de la roue : 20 février, il y a 18 ans.
    final now = DateTime.now();
    _selectedDay = 20;
    _selectedMonthIndex = 1; // février
    _selectedYear = now.year - 18;
    _birthDate = DateTime(_selectedYear, _selectedMonthIndex + 1, _selectedDay);
    _birthYears = [for (var y = _minBirthYear; y <= now.year; y++) y];

    _dayController = FixedExtentScrollController(initialItem: _selectedDay - 1);
    _monthController = FixedExtentScrollController(
      initialItem: _selectedMonthIndex,
    );
    _yearController = FixedExtentScrollController(
      initialItem: _birthYears.indexOf(_selectedYear),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _firstNameController.dispose();
    _usernameController.dispose();
    _bioController.dispose();
    _locationController.dispose();
    for (final controller in _socialControllers) {
      controller.dispose();
    }
    _dayController.dispose();
    _monthController.dispose();
    _yearController.dispose();
    super.dispose();
  }

  int get _daysInSelectedBirthMonth {
    final month = _selectedMonthIndex + 1;
    final nextMonth = month == 12
        ? DateTime(_selectedYear + 1, 1, 1)
        : DateTime(_selectedYear, month + 1, 1);
    return nextMonth.subtract(const Duration(days: 1)).day;
  }

  int get _birthAge {
    final now = DateTime.now();
    final birthDate = DateTime(
      _selectedYear,
      _selectedMonthIndex + 1,
      _selectedDay,
    );
    var age = now.year - birthDate.year;
    if (now.month < birthDate.month ||
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age -= 1;
    }
    return age;
  }

  void _updateBirthDate() {
    _birthDate = DateTime(_selectedYear, _selectedMonthIndex + 1, _selectedDay);
  }

  void _showAccessDeniedDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final textPrimary = isDark
        ? AppColors.textPrimaryDark
        : AppColors.textPrimaryLight;
    final textSecondary = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;
    final primary = isDark ? AppColors.primaryDark : AppColors.primaryLight;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;

    showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Accès refusé',
                style: TextStyle(
                  color: textPrimary,
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Tu dois avoir au moins 18 ans pour utiliser Lolango.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: textSecondary,
                  fontSize: 14.5,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              Divider(color: border),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: Text(
                    'OK',
                    style: TextStyle(
                      color: primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBirthWheel({
    required FixedExtentScrollController controller,
    required int itemCount,
    required String Function(int index) labelBuilder,
    required int selectedIndex,
    required ValueChanged<int> onChanged,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark
        ? AppColors.textPrimaryDark
        : AppColors.textPrimaryLight;
    final textTertiary = isDark
        ? AppColors.textTertiaryDark
        : AppColors.textTertiaryLight;

    return ListWheelScrollView.useDelegate(
      controller: controller,
      itemExtent: 44,
      perspective: 0.003,
      diameterRatio: 1.4,
      physics: const FixedExtentScrollPhysics(),
      onSelectedItemChanged: onChanged,
      childDelegate: ListWheelChildBuilderDelegate(
        childCount: itemCount,
        builder: (context, index) {
          final isSelected = index == selectedIndex;
          return Center(
            child: Text(
              labelBuilder(index),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: isSelected ? 22 : 18,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                color: isSelected ? textPrimary : textTertiary,
              ),
            ),
          );
        },
      ),
    );
  }

  void _nextPage() {
    final total = 10;
    if (_currentStep < total - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
      );
      setState(() => _currentStep++);
    }
  }

  void _previousPage() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
      );
      setState(() => _currentStep--);
    }
  }

  /// Gère l'appui sur "Continuer" : intercepte l'étape "date de naissance"
  /// pour bloquer les moins de 18 ans avant de laisser passer à l'étape
  /// suivante (comme dans la capture de référence).
  void _handleContinuePressed() {
    if (_currentStep == 2) {
      _updateBirthDate();
      if (_birthAge < 18) {
        _showAccessDeniedDialog();
        return;
      }
    }
    if (_currentStep == 9) {
      _finishOnboarding();
    } else {
      _nextPage();
    }
  }

  Future<void> _checkUsername(String value) async {
    final cleanValue = value.trim();
    if (cleanValue.isEmpty || cleanValue.length < 3) {
      setState(() => _usernameAvailable = false);
      return;
    }

    setState(() => _isCheckingUsername = true);
    final available = await ref
        .read(onboardingViewModelProvider.notifier)
        .checkUsernameAvailability(cleanValue);
    if (!mounted) return;
    setState(() {
      _isCheckingUsername = false;
      _usernameAvailable = available;
    });
  }

  bool get _isUsernameValid {
    final value = _usernameController.text.trim();
    return value.isNotEmpty &&
        value.length >= 3 &&
        value.contains(RegExp(r'^[a-zA-Z0-9._]+$')) &&
        _usernameAvailable;
  }

  bool get _canContinue {
    switch (_currentStep) {
      case 0:
        return _firstNameController.text.trim().isNotEmpty;
      case 1:
        return _isUsernameValid;
      case 2:
        // La validation de l'âge (18+) se fait au clic sur "Continuer".
        return true;
      case 3:
        return _gender != null;
      case 4:
        return _discoveryPreferences.isNotEmpty;
      case 5:
        return _locationLabel != null &&
            _locationLabel!.isNotEmpty &&
            !_isLocationLoading;
      case 6:
        return _selectedInterests.isNotEmpty;
      case 7:
        return _pickedPhotos.isNotEmpty;
      case 8:
        return _socialControllers.any(
          (controller) => controller.text.trim().isNotEmpty,
        );
      case 9:
        return _bioController.text.trim().length <= 150 &&
            _bioController.text.trim().isNotEmpty;
      default:
        return true;
    }
  }

  Future<void> _pickPhotos() async {
    final picker = ImagePicker();
    final result = await picker.pickMultiImage(
      maxWidth: 1600,
      imageQuality: 85,
    );
    if (result.isEmpty) return;

    setState(
      () => _pickedPhotos
        ..clear()
        ..addAll(result),
    );
  }

  Future<void> _fetchLocation() async {
    setState(() {
      _isLocationLoading = true;
      _locationError = null;
      _locationAttempted = true;
    });

    try {
      final service = ref.read(locationServiceProvider);
      final position = await service.determinePosition();
      final label = await service.reverseGeocode(
        position.latitude,
        position.longitude,
      );

      setState(() {
        _locationLatitude = position.latitude;
        _locationLongitude = position.longitude;
        _locationLabel = label;
        _locationController.text = label ?? '';
      });
    } catch (error) {
      setState(() {
        _locationError = error is StateError
            ? error.message
            : 'Impossible de récupérer la localisation.';
      });
    } finally {
      setState(() {
        _isLocationLoading = false;
      });
    }
  }

  Future<List<String>> _uploadPhotos() async {
    if (_pickedPhotos.isEmpty) return const [];
    final repo = ref.read(onboardingRepositoryProvider);
    return repo.uploadProfileImages(_pickedPhotos);
  }

  Future<void> _finishOnboarding() async {
    if (!_canContinue) return;
    setState(() => _isSubmitting = true);

    final socialMap = <String, String>{};
    final socialPlatforms = ['Instagram', 'Snapchat', 'TikTok'];
    for (var index = 0; index < _socialControllers.length; index++) {
      final value = _socialControllers[index].text.trim();
      if (value.isEmpty) continue;
      socialMap[socialPlatforms[index]] = value;
    }

    try {
      final photoUrls = await _uploadPhotos();

      final payload = {
        'first_name': _firstNameController.text.trim(),
        'username': _usernameController.text.trim().startsWith('@')
            ? _usernameController.text.trim()
            : '@${_usernameController.text.trim()}',
        'birth_date': _birthDate?.toIso8601String(),
        'gender': _gender,
        'discovery_preferences': _discoveryPreferences.toList(),
        'location_label': _locationLabel,
        'latitude': _locationLatitude,
        'longitude': _locationLongitude,
        'bio': _bioController.text.trim(),
        'photos': photoUrls,
        'social_links': socialMap,
        'profile_completed': true,
        'created_at': DateTime.now().toUtc().toIso8601String(),
      };

      await ref.read(onboardingViewModelProvider.notifier).saveProfile(payload);
      if (mounted) context.go('/home');
    } catch (error) {
      if (mounted) {
        final message = error is StateError
            ? error.message
            : 'Impossible d’enregistrer l’onboarding.';

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final background = isDark
        ? AppColors.backgroundDark
        : AppColors.backgroundLight;
    final surface = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;
    final textPrimary = isDark
        ? AppColors.textPrimaryDark
        : AppColors.textPrimaryLight;
    final textSecondary = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;
    final textTertiary = isDark
        ? AppColors.textTertiaryDark
        : AppColors.textTertiaryLight;
    final primary = isDark ? AppColors.primaryDark : AppColors.primaryLight;
    final secondary = isDark
        ? AppColors.secondaryDark
        : AppColors.secondaryLight;
    final success = isDark ? AppColors.successDark : AppColors.successLight;
    final error = isDark ? AppColors.errorDark : AppColors.errorLight;

    // Recadrage du jour si le mois sélectionné en compte moins.
    if (_selectedDay > _daysInSelectedBirthMonth) {
      _selectedDay = _daysInSelectedBirthMonth;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_dayController.hasClients)
          _dayController.jumpToItem(_selectedDay - 1);
      });
    }

    final stepWidgets = [
      _buildStep(
        title: 'Comment veux-tu qu’on t’appelle ?',
        subtitle:
            'Nous avons récupéré ton prénom depuis ton compte Google. Tu peux le modifier si tu veux.',
        child: TextField(
          controller: _firstNameController,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: 'Prénom',
            filled: true,
            fillColor: surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: border),
            ),
          ),
        ),
      ),

      // ==================================================
      // ÉTAPE 2 — PSEUDO (façon capture : coche verte / croix rouge live)
      // ==================================================
      _buildStep(
        title: 'Comment vous appelez-vous ?',
        subtitle:
            'Ces informations nous aident à personnaliser votre expérience sur Lolango.',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pseudo / Alias',
              style: TextStyle(fontSize: 14, color: textTertiary),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _usernameController.text.trim().isEmpty
                      ? border
                      : (_isUsernameValid ? success : error),
                ),
              ),
              child: Row(
                children: [
                  Text(
                    '@',
                    style: TextStyle(fontSize: 17, color: textTertiary),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _usernameController,
                      style: TextStyle(fontSize: 17, color: textPrimary),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 16),
                      ),
                      onChanged: (value) {
                        setState(() {});
                        if (value.trim().length >= 3) _checkUsername(value);
                      },
                    ),
                  ),
                  if (_isCheckingUsername)
                    SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(primary),
                      ),
                    )
                  else if (_usernameController.text.trim().isNotEmpty)
                    Icon(
                      _isUsernameValid
                          ? LucideIcons.checkCircle2
                          : LucideIcons.xCircle,
                      color: _isUsernameValid ? success : error,
                      size: 22,
                    ),
                ],
              ),
            ),
            if (_usernameController.text.trim().isNotEmpty &&
                !_isCheckingUsername &&
                !_isUsernameValid) ...[
              const SizedBox(height: 8),
              Text(
                _usernameController.text.trim().length < 3
                    ? 'Le pseudo doit contenir au moins 3 caractères.'
                    : 'Ce nom d’utilisateur est déjà pris.',
                style: TextStyle(color: error, fontSize: 13),
              ),
            ],
          ],
        ),
      ),

      // ==================================================
      // ÉTAPE 3 — DATE DE NAISSANCE (roues + âge + blocage 18 ans)
      // ==================================================
      _buildStep(
        title: 'Indiquez votre date de naissance',
        subtitle:
            'Cette application est réservée aux personnes de 18 ans et plus. '
            'Indique ta date de naissance pour continuer.',
        child: Column(
          children: [
            Text(
              '$_birthAge ans',
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.w800,
                color: textPrimary,
                letterSpacing: -1,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 220,
              child: Stack(
                children: [
                  Center(
                    child: Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: surface,
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: _buildBirthWheel(
                          controller: _dayController,
                          itemCount: _daysInSelectedBirthMonth,
                          selectedIndex: _selectedDay - 1,
                          labelBuilder: (index) => '${index + 1}',
                          onChanged: (index) => setState(() {
                            _selectedDay = index + 1;
                            _updateBirthDate();
                          }),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: _buildBirthWheel(
                          controller: _monthController,
                          itemCount: _months.length,
                          selectedIndex: _selectedMonthIndex,
                          labelBuilder: (index) => _months[index],
                          onChanged: (index) => setState(() {
                            _selectedMonthIndex = index;
                            _updateBirthDate();
                          }),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: _buildBirthWheel(
                          controller: _yearController,
                          itemCount: _birthYears.length,
                          selectedIndex: _birthYears.indexOf(_selectedYear),
                          labelBuilder: (index) => '${_birthYears[index]}',
                          onChanged: (index) => setState(() {
                            _selectedYear = _birthYears[index];
                            _updateBirthDate();
                          }),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),

      // ==================================================
      // ÉTAPE 4 — GENRE (cartes sélectionnables façon capture)
      // ==================================================
      _buildStep(
        title: 'Quel est votre genre ?',
        subtitle: "Choisissez l'option qui vous représente.",
        child: Column(
          children: onboardingGenderOptions.map((option) {
            final isSelected = _gender == option;
            return GestureDetector(
              onTap: () => setState(() => _gender = option),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 20,
                ),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: isSelected
                      ? primary.withValues(alpha: isDark ? 0.18 : 0.16)
                      : surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isSelected ? primary : border,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        option,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: textPrimary,
                        ),
                      ),
                    ),
                    Icon(
                      isSelected ? Icons.check_circle : Icons.circle_outlined,
                      color: isSelected ? primary : border,
                      size: 22,
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),

      _buildStep(
        title: 'Qui souhaites-tu découvrir ?',
        subtitle:
            'Choisis les personnes que tu aimerais voir dans tes découvertes.',
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          children: onboardingDiscoveryOptions.map((option) {
            final selected = _discoveryPreferences.contains(option);
            return FilterChip(
              label: Text(option),
              selected: selected,
              onSelected: (_) {
                setState(() {
                  if (selected) {
                    _discoveryPreferences.remove(option);
                  } else {
                    _discoveryPreferences.add(option);
                  }
                });
              },
              selectedColor: primary,
              labelStyle: TextStyle(
                color: selected ? Colors.black : textPrimary,
                fontWeight: FontWeight.w600,
              ),
            );
          }).toList(),
        ),
      ),
      _buildStep(
        title: 'Où es-tu ?',
        subtitle:
            'Nous affichons uniquement une zone approximative, jamais ton adresse exacte.',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _locationController,
              onChanged: (value) =>
                  setState(() => _locationLabel = value.trim()),
              decoration: InputDecoration(
                hintText: 'Dakar, Sénégal',
                helperText:
                    'Tu peux modifier la localisation approximative si nécessaire.',
                filled: true,
                fillColor: surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: border),
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (_isLocationLoading)
              Row(
                children: [
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Récupération de la localisation…',
                    style: TextStyle(color: textSecondary),
                  ),
                ],
              )
            else if (_locationError != null)
              Text(
                _locationError!,
                style: TextStyle(color: error, fontWeight: FontWeight.w600),
              )
            else if (!_locationAttempted)
              Text(
                'Appuie sur le bouton pour récupérer ta localisation approximative.',
                style: TextStyle(color: textSecondary),
              )
            else if (_locationLabel != null && _locationLabel!.isNotEmpty)
              Text(
                'Localisation approximative trouvée',
                style: TextStyle(
                  color: textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _isLocationLoading ? null : _fetchLocation,
              icon: const Icon(LucideIcons.mapPin),
              label: const Text('Récupérer ma localisation'),
              style: FilledButton.styleFrom(
                backgroundColor: primary,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ],
        ),
      ),
      _buildStep(
        title: 'Qu’est-ce que tu aimes ?',
        subtitle:
            'Choisis les activités, passions et sujets qui te ressemblent.',
        child: SizedBox(
          height: 420,
          child: ListView.builder(
            itemCount: _categories.length,
            itemBuilder: (context, categoryIndex) {
              final category = _categories[categoryIndex];
              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${category.emoji} ${category.name}',
                      style: TextStyle(
                        color: textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: category.interests.map((interest) {
                        final checked = _selectedInterests.contains(interest);
                        return ChoiceChip(
                          label: Text(interest),
                          selected: checked,
                          onSelected: (_) {
                            setState(() {
                              if (checked) {
                                _selectedInterests.remove(interest);
                              } else {
                                _selectedInterests.add(interest);
                              }
                            });
                          },
                          selectedColor: primary,
                          labelStyle: TextStyle(
                            color: checked ? Colors.black : textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
      _buildStep(
        title: 'Ajoute une photo qui te représente 📸',
        subtitle: 'Sélectionne au moins une photo pour compléter ton profil.',
        child: Column(
          children: [
            InkWell(
              onTap: _pickPhotos,
              borderRadius: BorderRadius.circular(18),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: border, width: 1.2),
                ),
                child: Column(
                  children: [
                    Icon(LucideIcons.imagePlus, size: 30, color: primary),
                    const SizedBox(height: 12),
                    Text(
                      'Choisir des photos',
                      style: TextStyle(
                        color: textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Jusqu’à 4 photos pour ton profil',
                      style: TextStyle(color: textSecondary, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 4,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.82,
              ),
              itemBuilder: (context, index) {
                final photo = index < _pickedPhotos.length
                    ? _pickedPhotos[index]
                    : null;
                final isPrimary = index == 0;

                return GestureDetector(
                  onTap: () {
                    if (photo == null) {
                      _pickPhotos();
                    }
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: surface,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: border, width: 1.2),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: photo == null
                        ? Center(
                            child: Icon(
                              LucideIcons.plus,
                              size: 32,
                              color: textSecondary,
                            ),
                          )
                        : Stack(
                            children: [
                              Image.file(
                                File(photo.path),
                                width: double.infinity,
                                height: double.infinity,
                                fit: BoxFit.cover,
                              ),
                              if (isPrimary)
                                Positioned(
                                  left: 8,
                                  bottom: 8,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryLight.withOpacity(
                                        0.95,
                                      ),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: const Text(
                                      'Photo principale',
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontSize: 9,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
      _buildStep(
        title: 'Sur quels réseaux peut-on te retrouver ?',
        subtitle: 'Ajoute tes comptes si tu veux les partager avec les autres.',
        child: Column(
          children: [
            for (int index = 0; index < _socialControllers.length; index++)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: TextField(
                  controller: _socialControllers[index],
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: _getSocialHint(index),
                    filled: true,
                    fillColor: surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: border),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
      _buildStep(
        title: 'Parle un peu de toi',
        subtitle:
            'Présente-toi en quelques mots et donne envie de découvrir ton univers.',
        child: Column(
          children: [
            TextField(
              controller: _bioController,
              onChanged: (_) => setState(() {}),
              maxLength: 150,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: 'Passionné de musique, football et voyages 🌍',
                filled: true,
                fillColor: surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: border),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                '${_bioController.text.length}/150',
                style: TextStyle(color: textSecondary),
              ),
            ),
          ],
        ),
      ),
    ];

    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Row(
                children: [
                  if (_currentStep > 0)
                    IconButton(
                      onPressed: _previousPage,
                      icon: const Icon(LucideIcons.arrowLeft),
                    ),
                  const Spacer(),
                  Text(
                    '${_currentStep + 1}/10',
                    style: TextStyle(color: textSecondary),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: LinearProgressIndicator(
                value: (_currentStep + 1) / 10,
                backgroundColor: border,
                valueColor: AlwaysStoppedAnimation<Color>(primary),
                minHeight: 6,
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: stepWidgets,
              ),
            ),
            // ==================================================
            // BOUTON CONTINUER — pilule sombre pleine largeur (façon capture)
            // ==================================================
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton(
                  onPressed: _canContinue && !_isSubmitting
                      ? _handleContinuePressed
                      : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: secondary,
                    foregroundColor: isDark ? Colors.black : Colors.white,
                    disabledBackgroundColor: secondary.withValues(alpha: 0.4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  child: _isSubmitting
                      ? SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              isDark ? Colors.black : Colors.white,
                            ),
                          ),
                        )
                      : Text(
                          _currentStep == 9
                              ? 'Valider mon profil'
                              : 'Continuer',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getSocialHint(int index) {
    const platforms = ['Instagram', 'Snapchat', 'TikTok'];
    return '@${platforms[index].toLowerCase()}';
  }

  Widget _buildStep({
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark
        ? AppColors.textPrimaryDark
        : AppColors.textPrimaryLight;
    final textSecondary = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                color: textPrimary,
                fontSize: 30,
                fontWeight: FontWeight.w800,
                height: 1.1,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              subtitle,
              style: TextStyle(color: textSecondary, fontSize: 15, height: 1.5),
            ),
            const SizedBox(height: 24),
            child,
          ],
        ),
      ),
    );
  }
}
