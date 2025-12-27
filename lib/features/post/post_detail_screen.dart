import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../post/create/post_model.dart';
import '../engagement/engagement_controller.dart';
import '../post/widgets/post_options_menu.dart';
import '.././common/widgets/badges_widgets.dart';

/// ============================================================================
/// POST DETAIL SCREEN
/// ============================================================================
/// Full view of a post with:
/// - ✅ Full-size image carousel
/// - ✅ Author info with badges
/// - ✅ Caption
/// - ✅ Engagement actions
/// - ✅ Replies section
/// - ✅ Add reply input
/// ============================================================================
class PostDetailScreen extends StatefulWidget {
  final String postId;
  final PostModel? initialPost; // Optional: pass post to avoid refetch

  const PostDetailScreen({super.key, required this.postId, this.initialPost});

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  final _replyController = TextEditingController();
  final _scrollController = ScrollController();

  PostModel? _post;
  List<Map<String, dynamic>> _replies = [];
  bool _isLoading = true;
  bool _isSendingReply = false;
  int _currentImageIndex = 0;

  @override
  void initState() {
    super.initState();
    _post = widget.initialPost;
    _loadPost();
  }

  @override
  void dispose() {
    _replyController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadPost() async {
    try {
      if (_post == null) {
        final doc = await _firestore
            .collection('posts')
            .doc(widget.postId)
            .get();
        if (doc.exists) {
          _post = PostModel.fromFirestore(doc);
        }
      }

      // Load replies
      final repliesSnap = await _firestore
          .collection('posts')
          .doc(widget.postId)
          .collection('replies')
          .orderBy('createdAt', descending: false)
          .limit(50)
          .get();

      _replies = repliesSnap.docs
          .map((d) => {'id': d.id, ...d.data()})
          .toList();
    } catch (e) {
      debugPrint('❌ Error loading post: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _sendReply() async {
    final text = _replyController.text.trim();
    if (text.isEmpty) return;

    final user = _auth.currentUser;
    if (user == null) return;

    setState(() => _isSendingReply = true);

    try {
      // Get user data
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final userData = userDoc.data() ?? {};

      // Add reply
      final replyRef = await _firestore
          .collection('posts')
          .doc(widget.postId)
          .collection('replies')
          .add({
            'text': text,
            'authorId': user.uid,
            'authorName': userData['displayName'] ?? user.displayName ?? 'User',
            'authorHandle': userData['handle'] ?? userData['username'],
            'authorAvatarUrl':
                userData['profileImageUrl'] ?? userData['photoUrl'],
            'authorIsVerified': userData['isVerified'] ?? false,
            'createdAt': FieldValue.serverTimestamp(),
          });

      // Increment reply count
      await _firestore.collection('posts').doc(widget.postId).update({
        'replyCount': FieldValue.increment(1),
      });

      // Add to local list
      _replies.add({
        'id': replyRef.id,
        'text': text,
        'authorId': user.uid,
        'authorName': userData['displayName'] ?? user.displayName ?? 'User',
        'authorHandle': userData['handle'] ?? userData['username'],
        'authorAvatarUrl': userData['profileImageUrl'] ?? userData['photoUrl'],
        'authorIsVerified': userData['isVerified'] ?? false,
        'createdAt': Timestamp.now(),
      });

      _replyController.clear();

      // Scroll to bottom
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      debugPrint('❌ Error sending reply: $e');
      _showError('Failed to send reply');
    } finally {
      setState(() => _isSendingReply = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_post == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: scheme.error),
              const SizedBox(height: 16),
              const Text('Post not found'),
            ],
          ),
        ),
      );
    }

    final post = _post!;
    final images = post.imageUrls;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Post'),
        centerTitle: true,
        actions: [
          PostOptionsMenu(post: post, onDeleted: () => Navigator.pop(context)),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              controller: _scrollController,
              children: [
                // ═══════════════════════════════════════════════════════════════
                // AUTHOR HEADER
                // ═══════════════════════════════════════════════════════════════
                _AuthorHeader(post: post),

                // ═══════════════════════════════════════════════════════════════
                // IMAGE CAROUSEL
                // ═══════════════════════════════════════════════════════════════
                if (images.isNotEmpty) ...[
                  AspectRatio(
                    aspectRatio: 1,
                    child: PageView.builder(
                      itemCount: images.length,
                      onPageChanged: (i) =>
                          setState(() => _currentImageIndex = i),
                      itemBuilder: (context, index) {
                        return GestureDetector(
                          onTap: () => _showFullImage(context, images, index),
                          child: CachedNetworkImage(
                            imageUrl: images[index],
                            fit: BoxFit.cover,
                            placeholder: (_, __) => Container(
                              color: scheme.surfaceContainerHighest,
                              child: const Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            ),
                            errorWidget: (_, __, ___) => Container(
                              color: scheme.surfaceContainerHighest,
                              child: const Icon(Icons.broken_image, size: 48),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  // Page indicator
                  if (images.length > 1)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(images.length, (i) {
                          return Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: i == _currentImageIndex
                                  ? scheme.primary
                                  : scheme.outlineVariant,
                            ),
                          );
                        }),
                      ),
                    ),
                ],

                // ═══════════════════════════════════════════════════════════════
                // CAPTION
                // ═══════════════════════════════════════════════════════════════
                if (post.caption.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      post.caption,
                      style: const TextStyle(fontSize: 15),
                    ),
                  ),

                // ═══════════════════════════════════════════════════════════════
                // ENGAGEMENT BAR
                // ═══════════════════════════════════════════════════════════════
                _EngagementBar(post: post),

                const Divider(),

                // ═══════════════════════════════════════════════════════════════
                // REPLIES
                // ═══════════════════════════════════════════════════════════════
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Text(
                    'Replies (${_replies.length})',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),

                if (_replies.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(32),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.chat_bubble_outline,
                            size: 48,
                            color: scheme.onSurfaceVariant.withValues(
                              alpha: 0.3,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'No replies yet',
                            style: TextStyle(color: scheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ...List.generate(_replies.length, (i) {
                    return _ReplyTile(reply: _replies[i]);
                  }),

                const SizedBox(height: 80), // Space for input
              ],
            ),
          ),

          // ═══════════════════════════════════════════════════════════════════
          // REPLY INPUT
          // ═══════════════════════════════════════════════════════════════════
          Container(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 8,
              bottom: MediaQuery.of(context).padding.bottom + 8,
            ),
            decoration: BoxDecoration(
              color: scheme.surface,
              border: Border(
                top: BorderSide(
                  color: scheme.outlineVariant.withValues(alpha: 0.3),
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _replyController,
                    decoration: InputDecoration(
                      hintText: 'Add a reply...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: scheme.surfaceContainerHighest,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    maxLines: null,
                    textCapitalization: TextCapitalization.sentences,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: _isSendingReply ? null : _sendReply,
                  icon: _isSendingReply
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showFullImage(BuildContext context, List<String> images, int index) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _FullImageViewer(images: images, initialIndex: index),
      ),
    );
  }
}

/// ============================================================================
/// AUTHOR HEADER
/// ============================================================================
class _AuthorHeader extends StatelessWidget {
  final PostModel post;

  const _AuthorHeader({required this.post});

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inMinutes < 1) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundImage: post.authorAvatarUrl != null
                ? CachedNetworkImageProvider(post.authorAvatarUrl!)
                : null,
            child: post.authorAvatarUrl == null
                ? const Icon(Icons.person)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      post.authorName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    if (post.authorIsVerified) ...[
                      const SizedBox(width: 4),
                      const Icon(Icons.verified, size: 16, color: Colors.blue),
                    ],
                  ],
                ),
                Text(
                  '@${post.authorHandle ?? 'user'} · ${_formatTime(post.createdAt)}',
                  style: TextStyle(
                    fontSize: 13,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// ============================================================================
/// ENGAGEMENT BAR
/// ============================================================================
class _EngagementBar extends StatelessWidget {
  final PostModel post;

  const _EngagementBar({required this.post});

  String _formatCount(int count) {
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}K';
    return count.toString();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatButton(
            icon: post.hasLiked ? Icons.favorite : Icons.favorite_border,
            color: post.hasLiked ? Colors.red : scheme.onSurfaceVariant,
            label: _formatCount(post.likeCount),
            onTap: () {},
          ),
          _StatButton(
            icon: Icons.chat_bubble_outline,
            color: scheme.onSurfaceVariant,
            label: _formatCount(post.replyCount),
            onTap: () {},
          ),
          _StatButton(
            icon: Icons.repeat,
            color: post.hasRepicced ? Colors.green : scheme.onSurfaceVariant,
            label: _formatCount(post.repicCount),
            onTap: () {},
          ),
          _StatButton(
            icon: post.hasSaved ? Icons.bookmark : Icons.bookmark_border,
            color: post.hasSaved ? Colors.amber : scheme.onSurfaceVariant,
            label: _formatCount(post.saveCount),
            onTap: () {},
          ),
          _StatButton(
            icon: Icons.share_outlined,
            color: scheme.onSurfaceVariant,
            label: '',
            onTap: () {},
          ),
        ],
      ),
    );
  }
}

class _StatButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;

  const _StatButton({
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Icon(icon, size: 22, color: color),
            if (label.isNotEmpty) ...[
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(color: color, fontWeight: FontWeight.w600),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// ============================================================================
/// REPLY TILE
/// ============================================================================
class _ReplyTile extends StatelessWidget {
  final Map<String, dynamic> reply;

  const _ReplyTile({required this.reply});

  String _formatTime(dynamic timestamp) {
    if (timestamp == null) return '';
    final dt = timestamp is Timestamp ? timestamp.toDate() : DateTime.now();
    final diff = DateTime.now().difference(dt);

    if (diff.inMinutes < 1) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${diff.inDays}d';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundImage: reply['authorAvatarUrl'] != null
                ? NetworkImage(reply['authorAvatarUrl'])
                : null,
            child: reply['authorAvatarUrl'] == null
                ? const Icon(Icons.person, size: 16)
                : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      reply['authorName'] ?? 'User',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    if (reply['authorIsVerified'] == true) ...[
                      const SizedBox(width: 4),
                      const Icon(Icons.verified, size: 12, color: Colors.blue),
                    ],
                    const SizedBox(width: 4),
                    Text(
                      '· ${_formatTime(reply['createdAt'])}',
                      style: TextStyle(
                        fontSize: 12,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(reply['text'] ?? '', style: const TextStyle(fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// ============================================================================
/// FULL IMAGE VIEWER
/// ============================================================================
class _FullImageViewer extends StatefulWidget {
  final List<String> images;
  final int initialIndex;

  const _FullImageViewer({required this.images, required this.initialIndex});

  @override
  State<_FullImageViewer> createState() => _FullImageViewerState();
}

class _FullImageViewerState extends State<_FullImageViewer> {
  late PageController _controller;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _controller = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: widget.images.length > 1
            ? Text('${_currentIndex + 1} / ${widget.images.length}')
            : null,
      ),
      body: PageView.builder(
        controller: _controller,
        itemCount: widget.images.length,
        onPageChanged: (i) => setState(() => _currentIndex = i),
        itemBuilder: (context, index) {
          return InteractiveViewer(
            child: Center(
              child: CachedNetworkImage(
                imageUrl: widget.images[index],
                fit: BoxFit.contain,
                placeholder: (_, __) => const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
