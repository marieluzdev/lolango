import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:lolango_v2/core/models/detailed_profile_model.dart';
import 'package:lolango_v2/core/errors/failures.dart';

class InteractionRepository {
  final SupabaseClient _client;

  InteractionRepository(this._client);

  String get _currentUserId {
    final user = _client.auth.currentUser;
    if (user == null) throw const AuthFailure("User not logged in");
    return user.id;
  }

  Future<List<String>> getInteractedProfileIds() async {
    try {
      final res = await _client
          .from('interactions')
          .select('target_id')
          .eq('user_id', _currentUserId);
      return (res as List).map((row) => row['target_id'] as String).toList();
    } catch (e) {
      throw Failure.from(e);
    }
  }

  Future<void> passProfile(String targetId) async {
    try {
      await _client.from('interactions').upsert({
        'user_id': _currentUserId,
        'target_id': targetId,
        'status': 'pass',
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Failure.from(e);
    }
  }

  Future<bool> likeProfile(String targetId) async {
    try {
      await _client.from('interactions').upsert({
        'user_id': _currentUserId,
        'target_id': targetId,
        'status': 'like',
        'created_at': DateTime.now().toIso8601String(),
      });

      final checkRes = await _client
          .from('interactions')
          .select('id')
          .eq('user_id', targetId)
          .eq('target_id', _currentUserId)
          .eq('status', 'like')
          .maybeSingle();

      if (checkRes != null) {
        await _client.from('matches').insert({
          'user1_id': _currentUserId,
          'user2_id': targetId,
          'created_at': DateTime.now().toIso8601String(),
        });

        // Notifications for both users
        await _client.from('notifications').insert([
          {
            'user_id': _currentUserId,
            'title': 'Nouveau match !',
            'body': 'Tu as un nouveau match. Découvre-le vite !',
          },
          {
            'user_id': targetId,
            'title': 'Nouveau match !',
            'body': 'Tu as un nouveau match. Découvre-le vite !',
          },
        ]);

        return true;
      } else {
        // Notification for the liked user
        await _client.from('notifications').insert({
          'user_id': targetId,
          'title': "Quelqu'un s'intéresse à toi",
          'body': 'Ouvre l\'application pour découvrir qui a liké ton profil !',
        });
      }
      return false;
    } catch (e) {
      throw Failure.from(e);
    }
  }

  Future<List<DetailedProfileModel>> _fetchDetailedProfilesByIds(
    List<String> ids,
  ) async {
    if (ids.isEmpty) return [];
    final results = await Future.wait([
      _client.from('profiles').select().inFilter('id', ids),
      _client
          .from('profile_photos')
          .select()
          .inFilter('user_id', ids)
          .order('position', ascending: true),
      _client.from('profile_socials').select().inFilter('user_id', ids),
      _client
          .from('profile_interests')
          .select('user_id, interests(name)')
          .inFilter('user_id', ids),
    ]);

    final profilesRes = results[0] as List<dynamic>;
    final photosRes = results[1] as List<dynamic>;
    final socialsRes = results[2] as List<dynamic>;
    final interestsRes = results[3] as List<dynamic>;

    final Map<String, List<String>> photosByUser = {};
    for (final row in photosRes) {
      final userId = row['user_id']?.toString();
      final url = row['url']?.toString();
      if (userId != null && url != null && url.isNotEmpty) {
        photosByUser.putIfAbsent(userId, () => []).add(url);
      }
    }

    final Map<String, Map<String, String>> socialsByUser = {};
    for (final row in socialsRes) {
      final userId = row['user_id']?.toString();
      final platform = row['platform']?.toString();
      final username = row['username']?.toString();
      if (userId != null && platform != null && username != null) {
        socialsByUser.putIfAbsent(userId, () => {})[platform] = username;
      }
    }

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

    return profilesRes.map((e) {
      final m = Map<String, dynamic>.from(e as Map);
      final id = m['id']?.toString() ?? '';
      return DetailedProfileModel.fromMap(
        m,
        socialsOverride: socialsByUser[id],
        photoUrlsOverride: photosByUser[id],
        interestsOverride: interestsByUser[id],
      );
    }).toList();
  }

  Future<List<DetailedProfileModel>> getPendingLikes() async {
    try {
      final likesRes = await _client
          .from('interactions')
          .select('user_id')
          .eq('target_id', _currentUserId)
          .eq('status', 'like');

      final likerIds = (likesRes as List)
          .map((row) => row['user_id'] as String)
          .toList();

      if (likerIds.isEmpty) return [];

      final matchesRes = await _client
          .from('matches')
          .select('user1_id, user2_id')
          .or('user1_id.eq.$_currentUserId,user2_id.eq.$_currentUserId');

      final matchedIds = (matchesRes as List).map((row) {
        return row['user1_id'] == _currentUserId
            ? row['user2_id']
            : row['user1_id'];
      }).toSet();

      final pendingLikerIds = likerIds
          .where((id) => !matchedIds.contains(id))
          .toList();

      if (pendingLikerIds.isEmpty) return [];

      return await _fetchDetailedProfilesByIds(pendingLikerIds);
    } catch (e) {
      throw Failure.from(e);
    }
  }

  Future<List<DetailedProfileModel>> getMatches() async {
    try {
      final matchesRes = await _client
          .from('matches')
          .select('user1_id, user2_id')
          .or('user1_id.eq.$_currentUserId,user2_id.eq.$_currentUserId');

      final matchedIds = (matchesRes as List)
          .map((row) {
            return row['user1_id'] == _currentUserId
                ? row['user2_id']
                : row['user1_id'];
          })
          .toSet()
          .toList();

      if (matchedIds.isEmpty) return [];

      return await _fetchDetailedProfilesByIds(matchedIds.cast<String>());
    } catch (e) {
      throw Failure.from(e);
    }
  }
}
