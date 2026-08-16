import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:lolango_v2/core/models/detailed_profile_model.dart';
import 'package:lolango_v2/core/errors/failures.dart';
import 'package:lolango_v2/core/supabase/supabase_client.dart';

class DiscoveryRepository {
  final SupabaseClient client;

  DiscoveryRepository(this.client);

  Future<List<DetailedProfileModel>> fetchProfiles({int page = 0, int limit = 20}) async {
    try {
      final profilesRes = await client
          .from('profiles')
          .select()
          .range(page * limit, (page + 1) * limit - 1);
          
      final list = profilesRes as List<dynamic>?;
      if (list == null || list.isEmpty) {
        return <DetailedProfileModel>[];
      }

      final currentUserId = client.auth.currentUser?.id;
      final ids = list
          .map((e) => e['id']?.toString())
          .where((id) => id != null && id != currentUserId)
          .cast<String>()
          .toList();
          
      if (ids.isEmpty) return <DetailedProfileModel>[];

      // Fetch photos, socials, and interests in parallel
      final results = await Future.wait([
        client.from('profile_photos').select().inFilter('user_id', ids).order('position', ascending: true),
        client.from('profile_socials').select().inFilter('user_id', ids),
        client.from('profile_interests').select('user_id, interests(name)').inFilter('user_id', ids),
      ]);

      final photosRes = results[0] as List<dynamic>;
      final socialsRes = results[1] as List<dynamic>;
      final interestsRes = results[2] as List<dynamic>;

      // Map photos
      final Map<String, List<String>> photosByUser = {};
      for (final row in photosRes) {
        final userId = row['user_id']?.toString();
        final url = row['url']?.toString();
        if (userId != null && url != null && url.isNotEmpty) {
          photosByUser.putIfAbsent(userId, () => []).add(url);
        }
      }

      // Map socials
      final Map<String, Map<String, String>> socialsByUser = {};
      for (final row in socialsRes) {
        final userId = row['user_id']?.toString();
        final platform = row['platform']?.toString();
        final username = row['username']?.toString();
        if (userId != null && platform != null && username != null) {
          socialsByUser.putIfAbsent(userId, () => {})[platform] = username;
        }
      }

      // Map interests
      final Map<String, List<String>> interestsByUser = {};
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

      // Map each profile to DetailedProfileModel
      return list.where((e) => ids.contains(e['id']?.toString())).map((e) {
        final m = Map<String, dynamic>.from(e as Map);
        final id = m['id']?.toString() ?? '';
        return DetailedProfileModel.fromMap(
          m,
          socialsOverride: socialsByUser[id],
          photoUrlsOverride: photosByUser[id],
          interestsOverride: interestsByUser[id],
        );
      }).toList();
    } catch (e) {
      throw Failure.from(e);
    }
  }
}
