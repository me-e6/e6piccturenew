import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../post/create/post_model.dart';

/// ============================================================================
/// SHARE SERVICE
/// ============================================================================
/// Handles all sharing functionality:
/// - ✅ Native share (system sheet)
/// - ✅ Copy link to clipboard
/// - ✅ Share to specific mutuals (DM-style)
/// - ✅ Deep link generation
/// ============================================================================
class ShareService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  ShareService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance;

  // --------------------------------------------------------------------------
  // DEEP LINK GENERATION
  // --------------------------------------------------------------------------
  
  /// Generate deep link for a post
  String getPostLink(String postId) {
    return 'https://piccture.app/post/$postId';
  }

  /// Generate deep link for a user profile
  String getProfileLink(String userId) {
    return 'https://piccture.app/user/$userId';
  }

  /// Generate deep link for a user by handle
  String getProfileLinkByHandle(String handle) {
    return 'https://piccture.app/@$handle';
  }

  // --------------------------------------------------------------------------
  // NATIVE SHARE
  // --------------------------------------------------------------------------
  
  /// Share post via system share sheet
  Future<void> sharePost(PostModel post) async {
    final link = getPostLink(post.postId);
    final text = post.caption.isNotEmpty
        ? '${post.caption}\n\n$link'
        : 'Check out this post on Piccture!\n$link';

    await Share.share(text, subject: 'Piccture Post');
  }

  /// Share profile via system share sheet
  Future<void> shareProfile({
    required String userId,
    required String displayName,
    String? handle,
  }) async {
    final link = handle != null 
        ? getProfileLinkByHandle(handle)
        : getProfileLink(userId);
    
    final text = 'Check out $displayName on Piccture!\n$link';
    await Share.share(text, subject: 'Piccture Profile');
  }

  /// Share image URL directly
  Future<void> shareImage(String imageUrl) async {
    await Share.share(
      'Check out this image on Piccture!\n$imageUrl',
      subject: 'Piccture Image',
    );
  }

  // --------------------------------------------------------------------------
  // COPY TO CLIPBOARD
  // --------------------------------------------------------------------------
  
  /// Copy post link to clipboard
  Future<void> copyPostLink(String postId) async {
    final link = getPostLink(postId);
    await Clipboard.setData(ClipboardData(text: link));
  }

  /// Copy profile link to clipboard
  Future<void> copyProfileLink(String userId, {String? handle}) async {
    final link = handle != null 
        ? getProfileLinkByHandle(handle)
        : getProfileLink(userId);
    await Clipboard.setData(ClipboardData(text: link));
  }

  // --------------------------------------------------------------------------
  // SHARE TO MUTUALS (Internal sharing)
  // --------------------------------------------------------------------------
  
  /// Get list of mutuals for sharing
  Future<List<MutualUser>> getMutualsForSharing() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return [];

    try {
      // Get followers
      final followersSnap = await _firestore
          .collection('users')
          .doc(uid)
          .collection('followers')
          .get();

      // Get following
      final followingSnap = await _firestore
          .collection('users')
          .doc(uid)
          .collection('following')
          .get();

      final followers = followersSnap.docs.map((d) => d.id).toSet();
      final following = followingSnap.docs.map((d) => d.id).toSet();

      // Mutuals = intersection
      final mutualIds = followers.intersection(following).toList();

      if (mutualIds.isEmpty) return [];

      // Fetch user details (batch of 10)
      final List<MutualUser> mutuals = [];
      
      for (var i = 0; i < mutualIds.length; i += 10) {
        final batch = mutualIds.skip(i).take(10).toList();
        final usersSnap = await _firestore
            .collection('users')
            .where(FieldPath.documentId, whereIn: batch)
            .get();

        for (final doc in usersSnap.docs) {
          final data = doc.data();
          mutuals.add(MutualUser(
            uid: doc.id,
            displayName: data['displayName'] ?? 'User',
            handle: data['handle'] ?? data['username'],
            avatarUrl: data['profileImageUrl'] ?? data['photoUrl'],
            isVerified: data['isVerified'] ?? false,
          ));
        }
      }

      return mutuals;
    } catch (e) {
      debugPrint('❌ Error fetching mutuals: $e');
      return [];
    }
  }

  /// Send post to a mutual (creates a share record)
  Future<bool> sendToMutual({
    required String postId,
    required String recipientId,
    String? message,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return false;

    try {
      // Create share record
      await _firestore.collection('shares').add({
        'postId': postId,
        'senderId': uid,
        'recipientId': recipientId,
        'message': message,
        'createdAt': FieldValue.serverTimestamp(),
        'isRead': false,
      });

      // TODO: Send notification to recipient

      debugPrint('✅ Shared post $postId to $recipientId');
      return true;
    } catch (e) {
      debugPrint('❌ Error sharing to mutual: $e');
      return false;
    }
  }

  /// Send post to multiple mutuals
  Future<int> sendToMultipleMutuals({
    required String postId,
    required List<String> recipientIds,
    String? message,
  }) async {
    int successCount = 0;

    for (final recipientId in recipientIds) {
      final success = await sendToMutual(
        postId: postId,
        recipientId: recipientId,
        message: message,
      );
      if (success) successCount++;
    }

    return successCount;
  }
}

/// ============================================================================
/// MUTUAL USER MODEL (for share picker)
/// ============================================================================
class MutualUser {
  final String uid;
  final String displayName;
  final String? handle;
  final String? avatarUrl;
  final bool isVerified;

  MutualUser({
    required this.uid,
    required this.displayName,
    this.handle,
    this.avatarUrl,
    this.isVerified = false,
  });
}

/// ============================================================================
/// SHARE TO MUTUALS BOTTOM SHEET
/// ============================================================================
/// Shows a list of mutuals to share a post with
/// ============================================================================
class ShareToMutualsSheet extends StatefulWidget {
  final String postId;
  final String? postCaption;

  const ShareToMutualsSheet({
    super.key,
    required this.postId,
    this.postCaption,
  });

  /// Show the sheet
  static Future<void> show(BuildContext context, {
    required String postId,
    String? postCaption,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => ShareToMutualsSheet(
        postId: postId,
        postCaption: postCaption,
      ),
    );
  }

  @override
  State<ShareToMutualsSheet> createState() => _ShareToMutualsSheetState();
}

class _ShareToMutualsSheetState extends State<ShareToMutualsSheet> {
  final ShareService _shareService = ShareService();
  List<MutualUser> _mutuals = [];
  final Set<String> _selectedIds = {};
  bool _isLoading = true;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _loadMutuals();
  }

  Future<void> _loadMutuals() async {
    final mutuals = await _shareService.getMutualsForSharing();
    setState(() {
      _mutuals = mutuals;
      _isLoading = false;
    });
  }

  void _toggleSelection(String uid) {
    setState(() {
      if (_selectedIds.contains(uid)) {
        _selectedIds.remove(uid);
      } else {
        _selectedIds.add(uid);
      }
    });
  }

  Future<void> _sendToSelected() async {
    if (_selectedIds.isEmpty) return;

    setState(() => _isSending = true);

    final count = await _shareService.sendToMultipleMutuals(
      postId: widget.postId,
      recipientIds: _selectedIds.toList(),
    );

    if (!mounted) return;

    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Shared with $count mutual${count != 1 ? 's' : ''}'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) => Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: scheme.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Text(
                  'Share to Mutuals',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: scheme.onSurface,
                  ),
                ),
                const Spacer(),
                if (_selectedIds.isNotEmpty)
                  TextButton(
                    onPressed: _isSending ? null : _sendToSelected,
                    child: _isSending
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text('Send (${_selectedIds.length})'),
                  ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _mutuals.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.people_outline,
                              size: 64,
                              color: scheme.onSurfaceVariant.withValues(alpha: 0.3),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No mutuals yet',
                              style: TextStyle(
                                fontSize: 16,
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Follow people who follow you back!',
                              style: TextStyle(
                                color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: scrollController,
                        itemCount: _mutuals.length,
                        itemBuilder: (context, index) {
                          final mutual = _mutuals[index];
                          final isSelected = _selectedIds.contains(mutual.uid);

                          return ListTile(
                            onTap: () => _toggleSelection(mutual.uid),
                            leading: Stack(
                              children: [
                                CircleAvatar(
                                  radius: 24,
                                  backgroundImage: mutual.avatarUrl != null
                                      ? NetworkImage(mutual.avatarUrl!)
                                      : null,
                                  child: mutual.avatarUrl == null
                                      ? const Icon(Icons.person)
                                      : null,
                                ),
                                if (isSelected)
                                  Positioned(
                                    right: 0,
                                    bottom: 0,
                                    child: Container(
                                      width: 20,
                                      height: 20,
                                      decoration: BoxDecoration(
                                        color: scheme.primary,
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.white, width: 2),
                                      ),
                                      child: const Icon(
                                        Icons.check,
                                        size: 12,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            title: Row(
                              children: [
                                Text(
                                  mutual.displayName,
                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                ),
                                if (mutual.isVerified) ...[
                                  const SizedBox(width: 4),
                                  const Icon(Icons.verified, size: 16, color: Colors.blue),
                                ],
                              ],
                            ),
                            subtitle: mutual.handle != null
                                ? Text('@${mutual.handle}')
                                : null,
                            trailing: isSelected
                                ? Icon(Icons.check_circle, color: scheme.primary)
                                : Icon(Icons.circle_outlined, color: scheme.outlineVariant),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
