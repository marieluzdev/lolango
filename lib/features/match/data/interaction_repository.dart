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
      final res = await _client
          .from('interactions')
          .select('target_id')
          .eq('user_id', _currentUserId);
      return (res as List).map((row) => row['target_id'] as String).toList();
    } catch (e) {
      return [];
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
      print("Erreur passProfile: $e");
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
        return true;
      }
      return false;
    } catch (e) {
      print("Erreur likeProfile: $e");
      return false;
    }
  }

  Future<List<ProfileModel>> getPendingLikes() async {
    try {
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
      print("Erreur getPendingLikes: $e");
      return [];
    }
  }
  
  Future<List<ProfileModel>> getMatches() async {
    try {
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
      print("Erreur getMatches: $e");
      return [];
    }
  }
}
