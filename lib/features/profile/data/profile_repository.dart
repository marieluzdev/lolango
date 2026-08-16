import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:lolango_v2/core/models/detailed_profile_model.dart';
import 'package:lolango_v2/core/errors/failures.dart';
import 'package:lolango_v2/core/supabase/supabase_client.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(ref.watch(supabaseProvider));
});

class ProfileRepository {
  final SupabaseClient supabase;

  ProfileRepository(this.supabase);

  Future<bool> hasCompletedProfile() async {
    final user = supabase.auth.currentUser;
    if (user == null) return false;

    try {
      final response = await supabase
          .from('profiles')
          .select('profile_completed')
          .eq('id', user.id)
          .maybeSingle();

      if (response == null) return false;
      return response['profile_completed'] == true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> hasSeenPrivacyModal() async {
    final user = supabase.auth.currentUser;
    if (user == null) return false;

    try {
      final response = await supabase
          .from('profiles')
          .select('has_seen_privacy_modal')
          .eq('id', user.id)
          .maybeSingle();

      if (response == null) return false;
      return response['has_seen_privacy_modal'] == true;
    } catch (_) {
      return false;
    }
  }

  Future<void> markPrivacyModalSeen() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;
    await supabase.from('profiles').update({'has_seen_privacy_modal': true}).eq('id', user.id);
  }

  Future<String?> fetchSocialVisibility() async {
    final user = supabase.auth.currentUser;
    if (user == null) return null;
    try {
      final response = await supabase.from('profiles').select('social_visibility').eq('id', user.id).maybeSingle();
      if (response == null) return null;
      return response['social_visibility'] as String?;
    } catch (_) {
      return null;
    }
  }

  Future<void> updateSocialVisibility(String mode, List<String>? visiblePlatforms) async {
    final user = supabase.auth.currentUser;
    if (user == null) return;
    await supabase.from('profiles').update({
      'social_visibility': mode,
      'visible_socials': visiblePlatforms,
    }).eq('id', user.id);
  }

  Future<Map<String, dynamic>?> fetchProfile() async {
    final user = supabase.auth.currentUser;
    if (user == null) return null;

    try {
      final response = await supabase
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      return response;
    } catch (_) {
      return null;
    }
  }

  Future<DetailedProfileModel?> fetchDetailedProfileById(String userId) async {
    try {
      final results = await Future.wait([
        supabase.from('profiles').select().eq('id', userId).maybeSingle(),
        supabase
            .from('profile_photos')
            .select()
            .eq('user_id', userId)
            .order('position', ascending: true),
        supabase.from('profile_socials').select().eq('user_id', userId),
        supabase
            .from('profile_interests')
            .select('interest_id, interests(name)')
            .eq('user_id', userId),
      ]);

      final profile = results[0] as Map<String, dynamic>?;
      if (profile == null) return null;

      final photos = results[1] as List<dynamic>? ?? [];
      final socials = results[2] as List<dynamic>? ?? [];
      final interestRecords = results[3] as List<dynamic>? ?? [];

      return DetailedProfileModel.fromMap({
        ...profile,
        'photos': photos,
        'socials': socials,
        'interests': interestRecords,
      });
    } catch (e) {
      throw Failure.from(e);
    }
  }

  Future<DetailedProfileModel?> fetchDetailedProfile() async {
    final user = supabase.auth.currentUser;
    if (user == null) return null;
    return fetchDetailedProfileById(user.id);
  }

  Future<void> upsertProfile(Map<String, dynamic> data) async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    await supabase.from('profiles').upsert({
      'id': user.id,
      ...data,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }, onConflict: 'id');
  }

  Future<void> upsertSocials(Map<String, String> socials) async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    final rows = socials.entries
        .where((entry) => entry.value.trim().isNotEmpty)
        .map(
          (entry) => {
            'user_id': user.id,
            'platform': entry.key,
            'username': entry.value.trim(),
          },
        )
        .toList();

    if (rows.isEmpty) {
      await supabase.from('profile_socials').delete().eq('user_id', user.id);
      return;
    }

    await supabase
        .from('profile_socials')
        .upsert(rows, onConflict: 'user_id,platform');
  }

  Future<void> upsertInterests(List<String> interests) async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    await supabase.from('profile_interests').delete().eq('user_id', user.id);

    if (interests.isNotEmpty) {
      final tagsData = await supabase
          .from('interests')
          .select('id, name')
          .inFilter('name', interests);

      if (tagsData.isNotEmpty) {
        final records = tagsData
            .map((tag) => {'user_id': user.id, 'interest_id': tag['id']})
            .toList();
        await supabase.from('profile_interests').insert(records);
      }
    }
  }

  Future<void> upsertPhotos(List<String> urls) async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    if (urls.isEmpty) {
      await supabase.from('profile_photos').delete().eq('user_id', user.id);
      return;
    }

    final rows = List.generate(
      urls.length,
      (index) => {
        'user_id': user.id,
        'url': urls[index],
        'position': index,
        'is_primary': index == 0,
      },
    );

    await supabase
        .from('profile_photos')
        .upsert(rows, onConflict: 'user_id,position');
  }

  Future<String?> uploadPhoto(List<int> imageBytes, String extension) async {
    final user = supabase.auth.currentUser;
    if (user == null) return null;

    final fileName = '${DateTime.now().millisecondsSinceEpoch}.$extension';
    final path = '${user.id}/$fileName';

    await supabase.storage
        .from('profile-photos')
        .uploadBinary(
          path,
          Uint8List.fromList(imageBytes),
          fileOptions: FileOptions(
            contentType: 'image/$extension',
            upsert: true,
          ),
        );

    return supabase.storage.from('profile-photos').getPublicUrl(path);
  }

  Future<void> deletePhotoStorage(String photoUrl) async {
    try {
      final uri = Uri.parse(photoUrl);
      final pathSegments = uri.pathSegments;
      final bucketIndex = pathSegments.indexOf('profile-photos');
      if (bucketIndex != -1 && bucketIndex + 1 < pathSegments.length) {
        final path = pathSegments.sublist(bucketIndex + 1).join('/');
        await supabase.storage.from('profile-photos').remove([path]);
      }
    } catch (_) {
      // Ignorer les erreurs si l'URL est mal formée ou si le fichier n'existe pas
    }
  }

  Future<void> deleteAccount() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      await supabase.from('profiles').delete().eq('id', user.id);
      await supabase.from('profile_photos').delete().eq('user_id', user.id);
      await supabase.from('profile_socials').delete().eq('user_id', user.id);
      await supabase.from('profile_interests').delete().eq('user_id', user.id);
      await supabase
          .from('discovery_preferences')
          .delete()
          .eq('user_id', user.id);
    } catch (_) {
      // graceful no-op: the app still signs out and the user can retry.
    }

    await supabase.auth.signOut();
  }

  Future<void> sendTestNotification({
    String title = 'Test push Lolango',
    String body = 'Notification de test envoyée depuis l\'app',
  }) async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      throw Exception('Aucun utilisateur connecté.');
    }

    final response = await supabase.rpc(
      'send_test_notification',
      params: {'title': title, 'body': body},
    );

    if (response is String) {
      if (response != 'ok') {
        throw Exception('Réponse RPC inattendue : $response');
      }

      return;
    }

    if (response is Map<String, dynamic>) {
      if (response['error'] != null) {
        throw Exception(response['error'].toString());
      }
    }
  }

  Future<String?> fetchStoredFcmToken() async {
    final user = supabase.auth.currentUser;
    if (user == null) return null;

    final response = await supabase
        .from('profiles')
        .select('fcm_token')
        .eq('id', user.id)
        .maybeSingle();

    if (response is Map<String, dynamic>) {
      return response['fcm_token'] as String?;
    }

    return null;
  }
}
