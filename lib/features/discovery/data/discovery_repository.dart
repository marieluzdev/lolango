import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/profile_model.dart';

class DiscoveryRepository {
  final SupabaseClient client;

  DiscoveryRepository(this.client);

  Future<List<ProfileModel>> fetchProfiles() async {
    try {
      print('=== DISCOVERY REPOSITORY FETCH ===');
      // 1. Récupérer tous les profils.
      final profilesRes = await client.from('profiles').select();
      final list = profilesRes as List<dynamic>?;
      if (list == null || list.isEmpty) {
        print('Aucun profil trouvé dans la table profiles.');
        return <ProfileModel>[];
      }
      print('Profils récupérés: ${list.length}');

      final currentUserId = client.auth.currentUser?.id;
      final ids = list
          .map((e) => e['id']?.toString())
          .where((id) => id != null && id != currentUserId)
          .cast<String>()
          .toList();
      print('IDs des profils: $ids');

      // 2. Photos : toutes les photos triées par position.
      final Map<String, List<String>> photosByUser = {};
      try {
        final photosRes = await client
            .from('profile_photos')
            .select()
            .inFilter('user_id', ids)
            .order('position', ascending: true);
        print('Photos récupérées brutes: ${photosRes.length}');
        for (final row in photosRes) {
          final userId = row['user_id']?.toString();
          final url = row['url']?.toString();
          if (userId != null && url != null && url.isNotEmpty) {
            photosByUser.putIfAbsent(userId, () => []).add(url);
          }
        }
        print('Photos par user: $photosByUser');
      } catch (e) {
        print('Erreur lors de la récupération des photos: $e');
      }

      // 3. Réseaux sociaux.
      final Map<String, Map<String, String>> socialsByUser = {};
      try {
        final socialsRes = await client
            .from('profile_socials')
            .select()
            .inFilter('user_id', ids);
        for (final row in socialsRes) {
          final userId = row['user_id']?.toString();
          final platform = row['platform']?.toString();
          final username = row['username']?.toString();
          if (userId != null && platform != null && username != null) {
            socialsByUser.putIfAbsent(userId, () => {})[platform] = username;
          }
        }
      } catch (e) {
        print('Erreur lors de la récupération des réseaux sociaux: $e');
      }

      // 4. Intérêts (identique à fetchDetailedProfile dans Profil).
      final Map<String, List<String>> interestsByUser = {};
      try {
        final interestsRes = await client
            .from('profile_interests')
            .select('user_id, interests(name)')
            .inFilter('user_id', ids);
        for (final row in interestsRes) {
          final userId = row['user_id']?.toString();
          final interest = row['interests'];
          if (userId != null && interest is Map<String, dynamic>) {
            final name = interest['name']?.toString();
            if (name != null && name.trim().isNotEmpty) {
              interestsByUser.putIfAbsent(userId, () => []).add(name.trim());
            }
          }
        }
      } catch (e) {
        print('Erreur lors de la récupération des intérêts: $e');
      }

      // 5. Mapper chaque profil vers ProfileModel.
      return list.where((e) => ids.contains(e['id']?.toString())).map((e) {
        final m = Map<String, dynamic>.from(e as Map);
        final id = m['id']?.toString() ?? '';
        final model = ProfileModel.fromMap(
          m,
          socialsOverride: socialsByUser[id],
          photoUrlsOverride: photosByUser[id],
          interestsOverride: interestsByUser[id],
        );
        print('Mapped profile $id: photos=${model.photoUrls}, socials=${model.socials}');
        return model;
      }).toList();
    } catch (e) {
      print('Erreur générale dans fetchProfiles: $e');
      return <ProfileModel>[];
    }
  }
}
