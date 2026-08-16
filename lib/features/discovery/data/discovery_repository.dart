import 'package:lolango_v2/core/errors/failures.dart';
import 'package:lolango_v2/core/models/detailed_profile_model.dart';
import 'package:lolango_v2/core/utils/logger.dart';
import 'package:lolango_v2/features/discovery/presentation/widgets/filter_modal.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DiscoveryRepository {
  final SupabaseClient client;

  DiscoveryRepository(this.client);

  Future<List<DetailedProfileModel>> fetchProfiles({
    int page = 0,
    int limit = 20,
    DiscoveryFilter? filter,
    Set<String>? excludeIds,
  }) async {
    try {
      final currentUserId = client.auth.currentUser?.id;

      // Build filtered query
      var query = client.from('profiles').select();

      // Filter by age range (server-side using birth_date)
      if (filter != null) {
        final minAge = filter.ageRange.start.round();
        final maxAge = filter.ageRange.end.round();
        final now = DateTime.now();
        final maxBirthDate = DateTime(now.year - minAge, now.month, now.day);
        final minBirthDate = DateTime(now.year - maxAge - 1, now.month, now.day + 1);

        final minBirthDateStr = minBirthDate.toIso8601String().split('T').first;
        final maxBirthDateStr = maxBirthDate.toIso8601String().split('T').first;

        query = query
            .gte('birth_date', minBirthDateStr)
            .lte('birth_date', maxBirthDateStr);

        // Filter by gender (server-side)
        if (filter.gender != null) {
          final genderVal = filter.gender!.toLowerCase();
          if (genderVal == 'female') {
            query = query.ilike('gender', '%fem%');
          } else if (genderVal == 'male') {
            query = query.or(
              'gender.ilike.%homme%,gender.ilike.%male%,gender.ilike.%hom%',
            );
          }
        }

        // Filter by city (server-side)
        if (filter.city != null && filter.city!.isNotEmpty) {
          query = query.ilike('location_label', '%${filter.city}%');
        }
      }

      // Apply pagination
      final profilesRes = await query.range(
        page * limit,
        (page + 1) * limit - 1,
      );

      final list = profilesRes as List<dynamic>?;
      if (list == null || list.isEmpty) return <DetailedProfileModel>[];

      final allExcluded = <String?>{
        currentUserId,
        ...?excludeIds,
      }.whereType<String>().toSet();

      final ids = list
          .map((e) => e['id']?.toString())
          .where((id) => id != null && !allExcluded.contains(id))
          .cast<String>()
          .toList();

      if (ids.isEmpty) return <DetailedProfileModel>[];

      // Fetch photos, socials, and interests in parallel
      final results = await Future.wait([
        client
            .from('profile_photos')
            .select()
            .inFilter('user_id', ids)
            .order('position', ascending: true),
        client.from('profile_socials').select().inFilter('user_id', ids),
        client
            .from('profile_interests')
            .select('user_id, interests(name)')
            .inFilter('user_id', ids),
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
      final profiles = list.where((e) => ids.contains(e['id']?.toString())).map(
        (e) {
          final m = Map<String, dynamic>.from(e as Map);
          final id = m['id']?.toString() ?? '';
          final result = DetailedProfileModel.fromMap(
            m,
            socialsOverride: socialsByUser[id],
            photoUrlsOverride: photosByUser[id],
            interestsOverride: interestsByUser[id],
          );
          return result;
        },
      ).toList();

      // Post-filter socials (requires joined data, must be done client-side)
      if (filter != null && filter.socials.isNotEmpty) {
        return profiles.where((p) {
          return filter.socials.any(
            (s) => p.socials.keys.map((k) => k.toLowerCase()).contains(s),
          );
        }).toList();
      }

      return profiles;
    } catch (e, st) {
      AppLogger.e('DiscoveryRepository.fetchProfiles', e, st);
      throw Failure.from(e);
    }
  }
}
