import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:eco_tisb/models/user_profile.dart';
import 'package:eco_tisb/models/item.dart';
import 'dart:io';
import 'package:path/path.dart' as p;

class SupabaseService {
  final SupabaseClient _client = Supabase.instance.client;

  User? get currentUser => _client.auth.currentUser;

  // Impact mapping based on your schema logic
  final Map<String, Map<String, double>> categoryImpact = {
    'BOOK': {'co2': 10.0, 'points': 100},
    'UNIFORM': {'co2': 25.0, 'points': 150},
    'ELECTRONICS': {'co2': 80.0, 'points': 300},
    'OTHER': {'co2': 5.0, 'points': 50},
  };

  // --- Authentication ---

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String startFullName
  }) async {
    final response = await _client.auth.signUp(
      email: email,
      password: password,
      data: {'full_name': startFullName},
    );

    if (response.user != null && response.session != null) {
      await createProfile(email, startFullName);
    }
    return response;
  }

  Future<AuthResponse> signIn({required String email, required String password}) async {
    final response = await _client.auth.signInWithPassword(email: email, password: password);
    if (response.user != null) {
      final profile = await getUserProfile(email);
      if (profile == null) {
        await createProfile(email, response.user!.userMetadata?['full_name'] ?? 'User');
      }
    }
    return response;
  }

  Future<void> signOut() async => await _client.auth.signOut();

  Future<void> createProfile(String email, String fullName) async {
    await _client.from('profiles').upsert({
      'email': email,
      'full_name': fullName,
      'points': 0,
      'co2_saved': 0.0,
      'items_recycled': 0,
      'trees_saved': 0.0,
    });
  }

  // --- Storage (Unified to handle item_images bucket) ---

  Future<String?> _uploadFile(File file, String folder) async {
    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}${p.extension(file.path)}';
      final path = '$folder/$fileName';

      // Ensure your bucket 'item_images' has an INSERT policy for authenticated users
      await _client.storage.from('item_images').upload(path, file);
      return _client.storage.from('item_images').getPublicUrl(path);
    } catch (e) {
      debugPrint('Storage Error: $e');
      return null;
    }
  }

  Future<String?> uploadItemImage(File file) => _uploadFile(file, 'marketplace');
  Future<String?> uploadLostFoundImage(File file) => _uploadFile(file, 'lost_found');

  // --- Conversations & Messaging ---

  /// Handles creating a chat for both Marketplace (items) and Lost & Found (lost_found)
  Future<String> getOrCreateConversation(String itemId, String recipientEmail) async {
    final myEmail = currentUser!.email!;

    // 1. Check if a conversation already exists for this item involving the current user
    final existingParticipants = await _client
        .from('conversation_participants')
        .select('conversation_id')
        .eq('user_email', myEmail);

    if (existingParticipants.isNotEmpty) {
      final List<String> convIds = (existingParticipants as List)
          .map((p) => p['conversation_id'] as String)
          .toList();

      final existingConv = await _client
          .from('conversations')
          .select('id')
          .inFilter('id', convIds)
          .eq('item_id', itemId)
          .maybeSingle();

      if (existingConv != null) return existingConv['id'];
    }

    // 2. Create new conversation if none exists
    // Note: Ensure your 'conversations' table item_id is not strictly tied
    // to 'items.id' via a Foreign Key if using for Lost & Found too.
    final newConv = await _client.from('conversations').insert({
      'item_id': itemId,
    }).select().single();

    final String newId = newConv['id'];

    // 3. Add both participants
    await _client.from('conversation_participants').insert([
      {'conversation_id': newId, 'user_email': myEmail},
      {'conversation_id': newId, 'user_email': recipientEmail},
    ]);

    return newId;
  }

  Stream<List<Map<String, dynamic>>> getConversationsStream() {
    final myEmail = currentUser?.email;
    if (myEmail == null) return Stream.value([]);

    return _client
        .from('conversation_participants')
        .stream(primaryKey: ['conversation_id', 'user_email'])
        .eq('user_email', myEmail)
        .asyncMap((participations) async {
      List<Map<String, dynamic>> fullConversations = [];

      for (var part in participations) {
        final convId = part['conversation_id'];

        final convData = await _client.from('conversations').select().eq('id', convId).single();

        // Check Marketplace first, then Lost & Found for item details
        var itemDetails = await _client.from('items').select().eq('id', convData['item_id']).maybeSingle();
        itemDetails ??= await _client.from('lost_found').select().eq('id', convData['item_id']).maybeSingle();

        final otherPart = await _client
            .from('conversation_participants')
            .select('user_email')
            .eq('conversation_id', convId)
            .neq('user_email', myEmail)
            .maybeSingle();

        fullConversations.add({
          'id': convId,
          'items': itemDetails ?? {'title': 'General Inquiry', 'image_url': null},
          'other_user': otherPart?['user_email'] ?? 'TISB User',
          'created_at': convData['created_at'],
        });
      }
      fullConversations.sort((a, b) => b['created_at'].compareTo(a['created_at']));
      return fullConversations;
    });
  }

  Future<void> sendMessage(String conversationId, String content) async {
    await _client.from('messages').insert({
      'conversation_id': conversationId,
      'sender_email': currentUser!.email!,
      'content': content,
    });
  }

  Stream<List<Map<String, dynamic>>> getMessageStream(String conversationId) {
    return _client
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('conversation_id', conversationId)
        .order('created_at', ascending: false);
  }

  // --- Marketplace Logic ---

  Future<List<Item>> getAvailableItems() async {
    final response = await _client
        .from('items')
        .select()
        .eq('is_swapped', false)
        .order('created_at', ascending: false);
    return (response as List).map((item) => Item.fromJson(item)).toList();
  }

  Future<Item?> createItem(Item item) async {
    try {
      final data = item.toJson();
      data.remove('id');
      data.remove('created_at');

      final response = await _client.from('items').insert(data).select().maybeSingle();
      if (response == null) return null;
      return Item.fromJson(response);
    } on PostgrestException catch (e) {
      if (e.message.contains('Monthly limit')) {
        throw Exception('Monthly limit reached: You can only post 5 items per month.');
      } else if (e.message.contains('Spam detected')) {
        throw Exception('Spam detected: Please remove restricted keywords (e.g., gift cards, crypto).');
      } else if (e.message.contains('banned')) {
        throw Exception('Access Denied: Your account has been banned due to security violations.');
      }
      rethrow;
    }
  }

  Future<void> reportUser({
    required String reportedUserEmail,
    required String reason,
    String? details,
    String? listingId,
  }) async {
    await _client.from('reports').insert({
      'reporter_email': currentUser!.email!,
      'reported_user_email': reportedUserEmail,
      'reason': reason,
      'details': details,
      'listing_id': listingId,
    });
  }

  // --- Lost & Found Logic ---

  Future<List<Map<String, dynamic>>> getLostFoundItems(String type) async {
    final response = await _client
        .from('lost_found')
        .select()
        .eq('type', type)
        .eq('is_resolved', false)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> reportLostFoundItem(Map<String, dynamic> itemData) async {
    await _client.from('lost_found').insert(itemData);
  }

  // --- Profile & Gamification ---

  Future<UserProfile?> getUserProfile(String email) async {
    final response = await _client.from('profiles').select().eq('email', email).maybeSingle();
    return response != null ? UserProfile.fromJson(response) : null;
  }
  Future<void> completeTransaction({
    required String itemId,
    required String sellerEmail,
    required String buyerEmail, // New parameter
    required String category
  }) async {
    final impact = categoryImpact[category.toUpperCase()] ?? categoryImpact['OTHER']!;
    final double co2 = impact['co2']!;
    final int pts = impact['points']!.toInt();
    final double trees = co2 / 22.0;

    // 1. Mark item as swapped
    final response = await _client
        .from('items')
        .update({'is_swapped': true})
        .eq('id', itemId)
        .select();

    if (response.isEmpty) {
      throw Exception("Update failed: Permission denied or item not found.");
    }

    // 2. Award points to SELLER
    await _client.rpc('increment_user_stats', params: {
      'p_email': sellerEmail,
      'p_co2': co2,
      'p_points': pts,
      'p_items': 1,
      'p_trees': trees,
    });

    // 3. Award points to BUYER (Both get the impact!)
    await _client.rpc('increment_user_stats', params: {
      'p_email': buyerEmail,
      'p_co2': co2,
      'p_points': pts,
      'p_items': 1,
      'p_trees': trees,
    });

    // 4. Update Global Stats
    await _client.rpc('increment_global_stats', params: {
      'p_co2': co2,
      'p_points': pts,
      'p_items': 1,
      'p_trees': trees,
    });
  }

  /// Updated to reward both Finder and Owner
  Future<void> completeLostFoundRecovery({
    required String itemId,
    required String reporterEmail, // The person who found/posted it
    required String ownerEmail     // The person who lost it
  }) async {
    // 1. Mark item as resolved
    final response = await _client
        .from('lost_found')
        .update({'is_resolved': true})
        .eq('id', itemId)
        .select();

    if (response.isEmpty) {
      throw Exception("Update failed: Permission denied or item not found.");
    }

    // 2. Award points to REPORTER (200 pts for helping)
    await _client.rpc('increment_user_stats', params: {
      'p_email': reporterEmail,
      'p_co2': 0.0,
      'p_points': 200,
      'p_items': 1,
      'p_trees': 0.0,
    });

    // 3. Award points to OWNER (100 pts for using the system to find it)
    await _client.rpc('increment_user_stats', params: {
      'p_email': ownerEmail,
      'p_co2': 0.0,
      'p_points': 100,
      'p_items': 1,
      'p_trees': 0.0,
    });
  }
  // --- User Specific Items ---
  Future<List<Item>> getUserListings(String email) async {
    try {
      final response = await _client
          .from('items')
          .select()
          .eq('seller_email', email)
          .order('created_at', ascending: false);

      return (response as List).map((item) => Item.fromJson(item)).toList();
    } catch (e) {
      debugPrint('Error fetching user listings: $e');
      return [];
    }
  }

  // --- Global Stats (Live Counter) ---

  Stream<Map<String, dynamic>> getGlobalStatsStream() {
    return _client
        .from('global_stats')
        .stream(primaryKey: ['id'])
        .eq('id', 1) // Assuming single row with ID 1
        .map((event) => event.isNotEmpty ? event.first : {
          'total_co2_saved': 0.0,
          'total_points': 0,
          'total_swaps': 0,
          'total_trees': 0.0,
        });
  }
}