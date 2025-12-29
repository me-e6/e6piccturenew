// ============================================================================
// GAZETTEER BADGE & VERIFICATION SYSTEM - COMPLETE
// ============================================================================
// 
// File: lib/features/verification/gazetteer_widgets.dart
//
// INCLUDES:
// ✅ GazetteerBadge widget (blue checkmark)
// ✅ VerifiedBadge widget (standard verified)
// ✅ BadgeRow widget (name + badges together)
// ✅ VerificationRequestDialog
// ✅ VerificationService
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// ============================================================================
// GAZETTEER BADGE (Blue checkmark with tooltip)
// ============================================================================

class GazetteerBadge extends StatelessWidget {
  final double size;
  final bool showTooltip;

  const GazetteerBadge({
    super.key,
    this.size = 16,
    this.showTooltip = true,
  });

  @override
  Widget build(BuildContext context) {
    final badge = Icon(
      Icons.verified,
      size: size,
      color: Colors.blue.shade400,
    );

    if (!showTooltip) return badge;

    return Tooltip(
      message: 'Verified Gazetteer',
      child: badge,
    );
  }
}

// ============================================================================
// VERIFIED BADGE (Generic verified - can use same as Gazetteer)
// ============================================================================

class VerifiedBadge extends StatelessWidget {
  final double size;
  final Color? color;

  const VerifiedBadge({
    super.key,
    this.size = 16,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Icon(
      Icons.verified,
      size: size,
      color: color ?? Colors.blue.shade400,
    );
  }
}

// ============================================================================
// BADGE ROW - Name with badges inline
// ============================================================================
// Usage: BadgeRow(name: 'John Doe', isVerified: true, isGazetteer: true)

class BadgeRow extends StatelessWidget {
  final String name;
  final bool isVerified;
  final bool isGazetteer;
  final TextStyle? nameStyle;
  final double badgeSize;
  final double spacing;
  final MainAxisAlignment alignment;

  const BadgeRow({
    super.key,
    required this.name,
    this.isVerified = false,
    this.isGazetteer = false,
    this.nameStyle,
    this.badgeSize = 16,
    this.spacing = 4,
    this.alignment = MainAxisAlignment.start,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final defaultStyle = TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: scheme.onSurface,
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: alignment,
      children: [
        Flexible(
          child: Text(
            name,
            style: nameStyle ?? defaultStyle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        // Show badge if verified OR gazetteer (same badge style)
        if (isVerified || isGazetteer) ...[
          SizedBox(width: spacing),
          GazetteerBadge(size: badgeSize, showTooltip: true),
        ],
      ],
    );
  }
}

// ============================================================================
// POST AUTHOR HEADER WITH BADGE
// ============================================================================
// Use this in your post cards to show author name with badge

class PostAuthorHeader extends StatelessWidget {
  final String authorName;
  final String? authorHandle;
  final String? authorAvatarUrl;
  final bool isVerified;
  final DateTime? createdAt;
  final VoidCallback? onTap;
  final VoidCallback? onMoreTap;

  const PostAuthorHeader({
    super.key,
    required this.authorName,
    this.authorHandle,
    this.authorAvatarUrl,
    this.isVerified = false,
    this.createdAt,
    this.onTap,
    this.onMoreTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 18,
              backgroundColor: scheme.surfaceContainerHighest,
              backgroundImage: authorAvatarUrl != null
                  ? NetworkImage(authorAvatarUrl!)
                  : null,
              child: authorAvatarUrl == null
                  ? Icon(Icons.person, size: 18, color: scheme.onSurfaceVariant)
                  : null,
            ),

            const SizedBox(width: 10),

            // Name, Handle, Badge
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name + Badge
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          authorName,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: scheme.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isVerified) ...[
                        const SizedBox(width: 4),
                        GazetteerBadge(size: 14),
                      ],
                    ],
                  ),

                  // Handle + Time
                  if (authorHandle != null || createdAt != null)
                    Row(
                      children: [
                        if (authorHandle != null)
                          Text(
                            '@$authorHandle',
                            style: TextStyle(
                              fontSize: 12,
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        if (authorHandle != null && createdAt != null)
                          Text(
                            ' · ',
                            style: TextStyle(
                              fontSize: 12,
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        if (createdAt != null)
                          Text(
                            _formatTime(createdAt!),
                            style: TextStyle(
                              fontSize: 12,
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                ],
              ),
            ),

            // More button
            if (onMoreTap != null)
              IconButton(
                icon: Icon(Icons.more_horiz, color: scheme.onSurfaceVariant),
                onPressed: onMoreTap,
                iconSize: 20,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays > 7) {
      return '${date.day}/${date.month}';
    } else if (diff.inDays > 0) {
      return '${diff.inDays}d';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}h';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes}m';
    } else {
      return 'now';
    }
  }
}

// ============================================================================
// VERIFICATION REQUEST DIALOG
// ============================================================================

class VerificationRequestDialog extends StatefulWidget {
  final String userId;
  final String userName;
  final String? userHandle;

  const VerificationRequestDialog({
    super.key,
    required this.userId,
    required this.userName,
    this.userHandle,
  });

  /// Show the dialog
  static Future<bool?> show(BuildContext context, {
    required String userId,
    required String userName,
    String? userHandle,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (_) => VerificationRequestDialog(
        userId: userId,
        userName: userName,
        userHandle: userHandle,
      ),
    );
  }

  @override
  State<VerificationRequestDialog> createState() => _VerificationRequestDialogState();
}

class _VerificationRequestDialogState extends State<VerificationRequestDialog> {
  final _reasonController = TextEditingController();
  bool _isSubmitting = false;
  String? _existingStatus;

  @override
  void initState() {
    super.initState();
    _checkExistingRequest();
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _checkExistingRequest() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('verification_requests')
        .where('userId', isEqualTo: widget.userId)
        .orderBy('requestedAt', descending: true)
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty && mounted) {
      setState(() {
        _existingStatus = snapshot.docs.first.data()['status'] as String?;
      });
    }
  }

  Future<void> _submitRequest() async {
    if (_reasonController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please provide a reason')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    HapticFeedback.mediumImpact();

    try {
      await FirebaseFirestore.instance.collection('verification_requests').add({
        'userId': widget.userId,
        'userName': widget.userName,
        'userHandle': widget.userHandle,
        'reason': _reasonController.text.trim(),
        'type': 'gazetteer',
        'status': 'pending',
        'requestedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Verification request submitted!'),
              ],
            ),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    // Show status if already requested
    if (_existingStatus != null) {
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              _existingStatus == 'approved'
                  ? Icons.verified
                  : _existingStatus == 'rejected'
                      ? Icons.cancel
                      : Icons.hourglass_top,
              color: _existingStatus == 'approved'
                  ? Colors.blue
                  : _existingStatus == 'rejected'
                      ? Colors.red
                      : Colors.orange,
            ),
            const SizedBox(width: 8),
            const Expanded(child: Text('Verification Status')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _existingStatus == 'approved'
                    ? Colors.blue.withValues(alpha: 0.1)
                    : _existingStatus == 'rejected'
                        ? Colors.red.withValues(alpha: 0.1)
                        : Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    _existingStatus == 'approved'
                        ? '🎉 Congratulations!'
                        : _existingStatus == 'rejected'
                            ? '❌ Request Rejected'
                            : '⏳ Pending Review',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _existingStatus == 'approved'
                        ? 'You are now a verified Gazetteer!'
                        : _existingStatus == 'rejected'
                            ? 'Your request was not approved. You can try again later.'
                            : 'Your request is being reviewed. This usually takes 2-3 days.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: scheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          if (_existingStatus == 'rejected')
            ElevatedButton(
              onPressed: () {
                setState(() => _existingStatus = null);
              },
              child: const Text('Try Again'),
            ),
        ],
      );
    }

    // Show request form
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(Icons.verified, color: Colors.blue.shade400),
          const SizedBox(width: 8),
          const Expanded(child: Text('Gazetteer Verification')),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Requirements
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Requirements',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: scheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _requirement('📸 10+ original posts'),
                  _requirement('👥 100+ followers'),
                  _requirement('📅 Account age 30+ days'),
                  _requirement('✨ Active community member'),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Reason field
            Text(
              'Why should you be verified?',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _reasonController,
              maxLines: 3,
              maxLength: 200,
              decoration: InputDecoration(
                hintText: 'Tell us about yourself and your content...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.3),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton.icon(
          onPressed: _isSubmitting ? null : _submitRequest,
          icon: _isSubmitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.send, size: 18),
          label: Text(_isSubmitting ? 'Submitting...' : 'Submit'),
        ),
      ],
    );
  }

  Widget _requirement(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

// ============================================================================
// VERIFICATION SERVICE
// ============================================================================

class VerificationService {
  static final _firestore = FirebaseFirestore.instance;

  /// Check if user is verified
  static Future<bool> isUserVerified(String userId) async {
    final doc = await _firestore.collection('users').doc(userId).get();
    return doc.data()?['isVerified'] == true;
  }

  /// Check if user has pending request
  static Future<String?> getRequestStatus(String userId) async {
    final snapshot = await _firestore
        .collection('verification_requests')
        .where('userId', isEqualTo: userId)
        .orderBy('requestedAt', descending: true)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;
    return snapshot.docs.first.data()['status'] as String?;
  }

  /// Submit verification request
  static Future<void> submitRequest({
    required String userId,
    required String userName,
    String? userHandle,
    required String reason,
  }) async {
    await _firestore.collection('verification_requests').add({
      'userId': userId,
      'userName': userName,
      'userHandle': userHandle,
      'reason': reason,
      'type': 'gazetteer',
      'status': 'pending',
      'requestedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Approve request (admin only)
  static Future<void> approveRequest(String requestId, String adminId) async {
    final batch = _firestore.batch();

    // Update request
    final requestRef = _firestore.collection('verification_requests').doc(requestId);
    batch.update(requestRef, {
      'status': 'approved',
      'reviewedAt': FieldValue.serverTimestamp(),
      'reviewedBy': adminId,
    });

    // Get userId from request
    final requestDoc = await requestRef.get();
    final userId = requestDoc.data()?['userId'] as String?;

    if (userId != null) {
      // Update user's verified status
      final userRef = _firestore.collection('users').doc(userId);
      batch.update(userRef, {
        'isVerified': true,
        'verifiedAt': FieldValue.serverTimestamp(),
        'type': 'gazetteer',
      });
    }

    await batch.commit();
  }

  /// Reject request (admin only)
  static Future<void> rejectRequest(
    String requestId,
    String adminId, {
    String? reason,
  }) async {
    await _firestore.collection('verification_requests').doc(requestId).update({
      'status': 'rejected',
      'reviewedAt': FieldValue.serverTimestamp(),
      'reviewedBy': adminId,
      'rejectionReason': reason,
    });
  }
}
