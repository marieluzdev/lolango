import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:lolango_v2/features/discovery/domain/profile_model.dart';
import 'package:lolango_v2/features/discovery/data/discovery_repository.dart';

class InteractionRepository {
  final SupabaseClient _client;
  
  InteractionRepository(this._client);

  String get _currentUserId {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception("User not logged in");
    return user.id;
  }

  Future<List<String>> getInteractedProfileIds() async {
    try {
      debugPrint('[INTERACTION] Fetching interacted profile IDs for $_currentUserId');
      final res = await _client
          .from('interactions')
          .select('target_id')
          .eq('user_id', _currentUserId);
      final ids = (res as List).map((row) => row['target_id'] as String).toList();
      debugPrint('[INTERACTION] Interacted IDs: $ids');
      return ids;
    } catch (e) {
      debugPrint('[INTERACTION] Erreur getInteractedProfileIds: $e');
      return [];
    }
  }

  Future<void> passProfile(String targetId) async {
    try {
      debugPrint('[PASS] Passing profile: $targetId');
      await _client.from('interactions').upsert({
        'user_id': _currentUserId,
        'target_id': targetId,
        'status': 'pass',
        'created_at': DateTime.now().toIso8601String(),
      });
      debugPrint('[PASS] Successfully passed profile $targetId');
    } catch (e) {
      debugPrint('[PASS] Erreur passProfile: $e');
    }
  }

  Future<bool> likeProfile(String targetId) async {
    try {
      debugPrint('[LIKE] Liking profile: $targetId');
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
        debugPrint('[MATCH] Match found with $targetId ! Creating match record.');
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
          }
        ]);
        
        return true;
      } else {
        // Notification for the liked user
        debugPrint('[LIKE] No match yet. Sending notification to $targetId.');
        await _client.from('notifications').insert({
          'user_id': targetId,
          'title': "Quelqu'un s'intéresse à toi",
          'body': 'Ouvre l\'application pour découvrir qui a liké ton profil !',
        });
      }
      return false;
    } catch (e) {
      debugPrint('[LIKE] Erreur likeProfile: $e');
      return false;
    }
  }

  Future<List<ProfileModel>> getPendingLikes() async {
    try {
      debugPrint('[INTERACTION] Fetching pending likes for $_currentUserId');
      final likesRes = await _client
          .from('interactions')
          .select('user_id')
          .eq('target_id', _currentUserId)
          .eq('status', 'like');
          
      final likerIds = (likesRes as List).map((row) => row['user_id'] as String).toList();
      
      if (likerIds.isEmpty) return [];

      final matchesRes = await _client
          .from('matches')
          .select('user1_id, user2_id')
          .or('user1_id.eq.$_currentUserId,user2_id.eq.$_currentUserId');
          
      final matchedIds = (matchesRes as List).map((row) {
        return row['user1_id'] == _currentUserId ? row['user2_id'] : row['user1_id'];
      }).toSet();
      
      final pendingLikerIds = likerIds.where((id) => !matchedIds.contains(id)).toList();
      
      if (pendingLikerIds.isEmpty) return [];
      
      final DiscoveryRepository discRepo = DiscoveryRepository(_client);
      final allProfiles = await discRepo.fetchProfiles();
      
      return allProfiles.where((p) => pendingLikerIds.contains(p.id)).toList();
    } catch (e) {
      debugPrint('[INTERACTION] Erreur getPendingLikes: $e');
      return [];
    }
  }
  
  Future<List<ProfileModel>> getMatches() async {
    try {
      debugPrint('[INTERACTION] Fetching matches for $_currentUserId');
      final matchesRes = await _client
          .from('matches')
          .select('user1_id, user2_id')
          .or('user1_id.eq.$_currentUserId,user2_id.eq.$_currentUserId');
          
      final matchedIds = (matchesRes as List).map((row) {
        return row['user1_id'] == _currentUserId ? row['user2_id'] : row['user1_id'];
      }).toSet().toList();
      
      if (matchedIds.isEmpty) return [];
      
      final DiscoveryRepository discRepo = DiscoveryRepository(_client);
      final allProfiles = await discRepo.fetchProfiles();
      
      return allProfiles.where((p) => matchedIds.contains(p.id)).toList();
    } catch (e) {
      debugPrint('[INTERACTION] Erreur getMatches: $e');
      return [];
    }
  }
}
