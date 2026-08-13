import 'dart:convert';

import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class OnboardingRepository {
  final SupabaseClient supabase;

  OnboardingRepository(this.supabase);

  Future<bool> checkUsernameAvailability(String username) async {
    final normalized = username.replaceFirst('@', '').trim();
    if (normalized.length < 3) return false;

    try {
      final result = await supabase
          .from('profiles')
          .select('username')
          .ilike('username', '@$normalized')
          .limit(1);

      return (result as List).isEmpty;
    } catch (_) {
      return true;
    }
  }

  Future<List<String>> uploadProfileImages(List<XFile> files) async {
    final user = supabase.auth.currentUser;
    if (user == null) return [];

    const bucketName = 'profile-photos';
    final storage = supabase.storage.from(bucketName);
    final urls = <String>[];

    try {
      for (var index = 0; index < files.length; index++) {
        final file = files[index];
        final bytes = await file.readAsBytes();
        final fileName = file.name.isNotEmpty
            ? file.name
            : 'profile-${DateTime.now().millisecondsSinceEpoch}-$index.jpg';
        final path = '${user.id}/$fileName';

        await storage.uploadBinary(
          path,
          bytes,
          fileOptions: const FileOptions(
            upsert: true,
            contentType: 'image/jpeg',
          ),
        );

        urls.add(storage.getPublicUrl(path));
      }

      return urls;
    } on StorageException catch (error) {
      if (error.statusCode == 404 || error.message.toLowerCase().contains('bucket not found')) {
        throw StateError(
          "Le bucket Supabase Storage 'profile-photos' est introuvable. Créez-le dans Supabase > Storage > New bucket, puis réessayez.",
        );
      }
      rethrow;
    }
  }

  Future<void> saveProfile(Map<String, dynamic> payload) async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      print('DEBUG onboarding repo: no authenticated user');
      throw StateError('Aucun utilisateur connecté.');
    }

    final profilePayload = {
      'id': user.id,
      'first_name': payload['first_name'] ?? '',
      'username': payload['username'] ?? '',
      'birth_date': payload['birth_date'],
      'gender': payload['gender'],
      'discovery_preferences': payload['discovery_preferences'] ?? const [],
      'location_label': payload['location_label'],
      'latitude': payload['latitude'],
      'longitude': payload['longitude'],
      'bio': payload['bio'] ?? '',
      'profile_completed': true,
      'created_at': payload['created_at'] ?? DateTime.now().toUtc().toIso8601String(),
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };

    print('DEBUG onboarding repo: userId=${user.id}');
    print('DEBUG onboarding repo: profilePayload=${profilePayload}');

    try {
      print('DEBUG onboarding repo: start profiles upsert');
      await supabase.from('profiles').upsert(profilePayload, onConflict: 'id');
      print('DEBUG onboarding repo: profiles upsert done');

      final photos = payload['photos'] as List<dynamic>? ?? const [];
      print('DEBUG onboarding repo: photosCount=${photos.length}');
      await supabase.from('profile_photos').delete().eq('user_id', user.id);
      if (photos.isNotEmpty) {
        final photoRows = List.generate(photos.length, (index) {
          final url = photos[index] as String;
          return {
            'user_id': user.id,
            'url': url,
            'is_primary': index == 0,
            'position': index,
          };
        });

        print('DEBUG onboarding repo: inserting photoRows=${photoRows.length}');
        await supabase.from('profile_photos').insert(photoRows);
        print('DEBUG onboarding repo: photo insert done');
      }

      final socials = payload['social_links'] as Map<String, dynamic>? ?? const {};
      print('DEBUG onboarding repo: socialsCount=${socials.length}');
      await supabase.from('profile_socials').delete().eq('user_id', user.id);
      if (socials.isNotEmpty) {
        final socialRows = socials.entries
            .where((entry) => (entry.value as String).trim().isNotEmpty)
            .map((entry) => {
                  'user_id': user.id,
                  'platform': entry.key,
                  'username': (entry.value as String).trim(),
                })
            .toList();

        print('DEBUG onboarding repo: inserting socialRows=${socialRows.length}');
        if (socialRows.isNotEmpty) {
          await supabase.from('profile_socials').insert(socialRows);
          print('DEBUG onboarding repo: social insert done');
        }
      }

      final selectedInterests = payload['selected_interests'] as List<dynamic>? ?? const [];
      print('DEBUG onboarding repo: selectedInterestsCount=${selectedInterests.length}');
      await supabase.from('profile_interests').delete().eq('user_id', user.id);
      if (selectedInterests.isNotEmpty) {
        final names = selectedInterests.map((item) => item.toString()).toSet();
        final allInterestRows = await supabase.from('interests').select('id, name');

        final interestIds = (allInterestRows as List<dynamic>)
            .where((entry) => entry['name'] is String && names.contains(entry['name'] as String))
            .map((entry) => entry['id'] as String)
            .toList();

        print('DEBUG onboarding repo: matchedInterestIds=${interestIds.length}');

        if (interestIds.isNotEmpty) {
          final profileInterestRows = interestIds
              .map((interestId) => {
                    'user_id': user.id,
                    'interest_id': interestId,
                  })
              .toList();

          print('DEBUG onboarding repo: inserting profileInterestRows=${profileInterestRows.length}');
          await supabase.from('profile_interests').insert(profileInterestRows);
          print('DEBUG onboarding repo: profile_interests insert done');
        }
      }

      print('DEBUG onboarding repo: saveProfile success');
    } catch (error, stackTrace) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('draft_onboarding', jsonEncode(profilePayload));
      print('DEBUG onboarding repo: saveProfile failed');
      print('DEBUG onboarding repo: error=$error');
      print('DEBUG onboarding repo: stackTrace=$stackTrace');
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> getProfileDraft() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('draft_onboarding');
    if (raw == null || raw.isEmpty) return null;
    try {
      return Map<String, dynamic>.from(jsonDecode(raw));
    } catch (_) {
      return null;
    }
  }
}
