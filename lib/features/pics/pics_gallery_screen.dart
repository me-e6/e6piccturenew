// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';

import '../post/create/post_model.dart';
import '../post/create/post_delete_service.dart';
import '../feed/day_album_viewer_screen.dart';

class PicsGalleryScreen extends StatefulWidget {
  const PicsGalleryScreen({super.key});

  @override
  State<PicsGalleryScreen> createState() => _PicsGalleryScreenState();
}

class _PicsGalleryScreenState extends State<PicsGalleryScreen> {
  List<PostModel> _posts = [];
  bool _isLoading = true;
  String? _error;

  _GalleryFilter _currentFilter = _GalleryFilter.all;
  _GallerySortOrder _sortOrder = _GallerySortOrder.newest;

  bool _isSelectionMode = false;
  final Set<String> _selectedPostIds = {};

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  Future<void> _loadPosts() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      setState(() {
        _error = 'Not logged in';
        _isLoading = false;
      });
      return;
    }

    setState(() => _isLoading = true);

    try {
      Query<Map<String, dynamic>> query = FirebaseFirestore.instance
          .collection('posts')
          .where('authorId', isEqualTo: uid);

      switch (_currentFilter) {
        case _GalleryFilter.photos:
          query = query.where('isQuote', isEqualTo: false);
          break;
        case _GalleryFilter.quotes:
          query = query.where('isQuote', isEqualTo: true);
          break;
        case _GalleryFilter.all:
          break;
      }

      query = query.orderBy(
        'createdAt',
        descending: _sortOrder == _GallerySortOrder.newest,
      );

      final snapshot = await query.limit(100).get();
      final posts = snapshot.docs
          .map((doc) => PostModel.fromFirestore(doc))
          .toList();

      setState(() {
        _posts = posts;
        _isLoading = false;
        _error = null;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _enterSelectionMode(String postId) {
    HapticFeedback.mediumImpact();
    setState(() {
      _isSelectionMode = true;
      _selectedPostIds.add(postId);
    });
  }

  void _exitSelectionMode() {
    setState(() {
      _isSelectionMode = false;
      _selectedPostIds.clear();
    });
  }

  void _toggleSelection(String postId) {
    HapticFeedback.selectionClick();
    setState(() {
      if (_selectedPostIds.contains(postId)) {
        _selectedPostIds.remove(postId);
        if (_selectedPostIds.isEmpty) {
          _isSelectionMode = false;
        }
      } else {
        _selectedPostIds.add(postId);
      }
    });
  }

  void _selectAll() {
    setState(() {
      _selectedPostIds.addAll(_posts.map((p) => p.postId));
    });
  }

  void _deselectAll() {
    setState(() {
      _selectedPostIds.clear();
    });
  }

  Future<void> _bulkDelete() async {
    if (_selectedPostIds.isEmpty) return;

    final count = _selectedPostIds.length;
    final confirmed = await _showBulkDeleteConfirmation(count);
    if (confirmed != true) return;

    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);

    messenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 12),
            Text('Deleting $count posts...'),
          ],
        ),
        duration: const Duration(seconds: 60),
        behavior: SnackBarBehavior.floating,
      ),
    );

    try {
      final deleteService = PostDeleteService();
      final deleted = await deleteService.batchDelete(
        _selectedPostIds.toList(),
      );

      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          content: Text('Deleted $deleted of $count posts'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: deleted == count ? Colors.green : Colors.orange,
        ),
      );

      _exitSelectionMode();
      _loadPosts();
    } catch (e) {
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<bool?> _showBulkDeleteConfirmation(int count) {
    final scheme = Theme.of(context).colorScheme;

    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Delete $count Posts?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('This action cannot be undone.'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: scheme.errorContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber, color: scheme.error, size: 20),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'All engagements will be permanently deleted.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Cancel',
              style: TextStyle(color: scheme.onSurfaceVariant),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Delete All',
              style: TextStyle(
                color: scheme.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showUnderConstruction(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature feature coming soon'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: _isSelectionMode
          ? _buildSelectionAppBar(scheme)
          : _buildNormalAppBar(scheme),
      body: _buildBody(scheme),
    );
  }

  PreferredSizeWidget _buildNormalAppBar(ColorScheme scheme) {
    return AppBar(
      title: const Text('My Pics'),
      centerTitle: true,
      actions: [
        PopupMenuButton<_GalleryFilter>(
          icon: const Icon(Icons.filter_list),
          onSelected: (filter) {
            setState(() => _currentFilter = filter);
            _loadPosts();
          },
          itemBuilder: (context) => [
            _buildFilterItem(_GalleryFilter.all, 'All', Icons.photo_library),
            _buildFilterItem(_GalleryFilter.photos, 'Photos Only', Icons.photo),
            _buildFilterItem(
              _GalleryFilter.quotes,
              'Quotes Only',
              Icons.format_quote,
            ),
          ],
        ),
        PopupMenuButton<_GallerySortOrder>(
          icon: const Icon(Icons.sort),
          onSelected: (order) {
            setState(() => _sortOrder = order);
            _loadPosts();
          },
          itemBuilder: (context) => [
            CheckedPopupMenuItem(
              value: _GallerySortOrder.newest,
              checked: _sortOrder == _GallerySortOrder.newest,
              child: const Text('Newest First'),
            ),
            CheckedPopupMenuItem(
              value: _GallerySortOrder.oldest,
              checked: _sortOrder == _GallerySortOrder.oldest,
              child: const Text('Oldest First'),
            ),
          ],
        ),
      ],
    );
  }

  PopupMenuItem<_GalleryFilter> _buildFilterItem(
    _GalleryFilter filter,
    String label,
    IconData icon,
  ) {
    final isSelected = _currentFilter == filter;
    final scheme = Theme.of(context).colorScheme;

    return PopupMenuItem(
      value: filter,
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: isSelected ? scheme.primary : scheme.onSurfaceVariant,
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? scheme.primary : scheme.onSurface,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
          const Spacer(),
          if (isSelected) Icon(Icons.check, size: 18, color: scheme.primary),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildSelectionAppBar(ColorScheme scheme) {
    final allSelected = _selectedPostIds.length == _posts.length;

    return AppBar(
      backgroundColor: scheme.primaryContainer,
      leading: IconButton(
        icon: const Icon(Icons.close),
        onPressed: _exitSelectionMode,
      ),
      title: Text('${_selectedPostIds.length} selected'),
      actions: [
        TextButton(
          onPressed: allSelected ? _deselectAll : _selectAll,
          child: Text(allSelected ? 'Deselect All' : 'Select All'),
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          enabled: _selectedPostIds.isNotEmpty,
          onSelected: (value) {
            if (value == 'delete')
              _bulkDelete();
            else
              _showUnderConstruction(
                value == 'archive' ? 'Archive' : 'Make Private',
              );
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete_outline, color: scheme.error, size: 20),
                  const SizedBox(width: 12),
                  Text('Delete', style: TextStyle(color: scheme.error)),
                ],
              ),
            ),
            const PopupMenuDivider(),
            const PopupMenuItem(
              value: 'archive',
              child: Row(
                children: [
                  Icon(Icons.archive_outlined, size: 20),
                  SizedBox(width: 12),
                  Text('Archive'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'private',
              child: Row(
                children: [
                  Icon(Icons.lock_outline, size: 20),
                  SizedBox(width: 12),
                  Text('Make Private'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBody(ColorScheme scheme) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: scheme.error),
            const SizedBox(height: 16),
            Text(_error!, style: TextStyle(color: scheme.onSurfaceVariant)),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: _loadPosts,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_posts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.photo_library_outlined,
              size: 80,
              color: scheme.onSurfaceVariant.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              _getEmptyMessage(),
              style: TextStyle(fontSize: 18, color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 8),
            Text(
              'Start posting to see your pics here!',
              style: TextStyle(
                color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadPosts,
      child: GridView.builder(
        padding: const EdgeInsets.all(2),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 2,
          crossAxisSpacing: 2,
        ),
        itemCount: _posts.length,
        itemBuilder: (context, index) {
          final post = _posts[index];
          return _GalleryItem(
            post: post,
            isSelectionMode: _isSelectionMode,
            isSelected: _selectedPostIds.contains(post.postId),
            onTap: () {
              if (_isSelectionMode) {
                _toggleSelection(post.postId);
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DayAlbumViewerScreen(
                      posts: _posts,
                      sessionStartedAt: DateTime.now(),
                      initialIndex: index,
                    ),
                  ),
                );
              }
            },
            onLongPress: () => _enterSelectionMode(post.postId),
          );
        },
      ),
    );
  }

  String _getEmptyMessage() {
    switch (_currentFilter) {
      case _GalleryFilter.quotes:
        return 'No quotes yet';
      case _GalleryFilter.photos:
        return 'No photos yet';
      case _GalleryFilter.all:
        return 'No posts yet';
    }
  }
}

enum _GalleryFilter { all, photos, quotes }

enum _GallerySortOrder { newest, oldest }

class _GalleryItem extends StatelessWidget {
  final PostModel post;
  final bool isSelectionMode;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _GalleryItem({
    required this.post,
    required this.isSelectionMode,
    required this.isSelected,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final imageUrl = post.imageUrls.isNotEmpty ? post.imageUrls.first : null;
    final hasMultiple = post.imageUrls.length > 1;
    final String? displayUrl =
        imageUrl ??
        (post.isQuote
            ? (post.quotedPreview?['thumbnailUrl'] as String?)
            : null);

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (displayUrl != null)
            Image.network(
              displayUrl,
              fit: BoxFit.cover,
              cacheWidth: 300,
              errorBuilder: (_, __, ___) => Container(
                color: scheme.surfaceContainerHighest,
                child: Icon(
                  Icons.broken_image,
                  color: scheme.onSurfaceVariant.withValues(alpha: 0.5),
                ),
              ),
            )
          else
            Container(
              color: scheme.surfaceContainerHighest,
              child: Icon(
                post.isQuote ? Icons.format_quote : Icons.image_not_supported,
                color: scheme.onSurfaceVariant.withValues(alpha: 0.5),
              ),
            ),

          if (hasMultiple)
            Positioned(
              top: 6,
              right: 6,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Icon(
                  Icons.collections,
                  color: Colors.white,
                  size: 14,
                ),
              ),
            ),

          if (post.isQuote)
            Positioned(
              top: 6,
              left: 6,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Icon(
                  Icons.format_quote,
                  color: Colors.white,
                  size: 14,
                ),
              ),
            ),

          if (isSelectionMode)
            Container(
              color: isSelected
                  ? scheme.primary.withValues(alpha: 0.3)
                  : Colors.black.withValues(alpha: 0.1),
            ),

          if (isSelectionMode)
            Positioned(
              top: 6,
              right: 6,
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected
                      ? scheme.primary
                      : Colors.white.withValues(alpha: 0.8),
                  border: Border.all(
                    color: isSelected ? scheme.primary : scheme.outline,
                    width: 2,
                  ),
                ),
                child: isSelected
                    ? const Icon(Icons.check, size: 16, color: Colors.white)
                    : null,
              ),
            ),
        ],
      ),
    );
  }
}
