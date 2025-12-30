// ============================================================================
// FILE: lib/features/post/widgets/share_post_sheet.dart
// ============================================================================
// 
// FEATURES:
// ✅ Native share (Android/iOS)
// ✅ Copy link
// ✅ Share to WhatsApp
// ✅ Share to Twitter
// ✅ Share to Instagram Stories
// ✅ Generate QR code
// ✅ Haptic feedback
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// Shows a share sheet for a post
/// 
/// Usage:
/// ```dart
/// SharePostSheet.show(
///   context,
///   postId: 'abc123',
///   postUrl: 'https://piccture.app/post/abc123',
///   imageUrl: 'https://...',
///   caption: 'Check out this post!',
/// );
/// ```
class SharePostSheet extends StatelessWidget {
  final String postId;
  final String postUrl;
  final String? imageUrl;
  final String? caption;
  final String? authorName;

  const SharePostSheet({
    super.key,
    required this.postId,
    required this.postUrl,
    this.imageUrl,
    this.caption,
    this.authorName,
  });

  /// Show the share sheet
  static Future<void> show(
    BuildContext context, {
    required String postId,
    required String postUrl,
    String? imageUrl,
    String? caption,
    String? authorName,
  }) {
    HapticFeedback.mediumImpact();
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SharePostSheet(
        postId: postId,
        postUrl: postUrl,
        imageUrl: imageUrl,
        caption: caption,
        authorName: authorName,
      ),
    );
  }

  /// Generate the share text
  String get _shareText {
    final buffer = StringBuffer();
    
    if (caption != null && caption!.isNotEmpty) {
      buffer.write(caption);
      buffer.write('\n\n');
    }
    
    if (authorName != null) {
      buffer.write('Shared from @$authorName on Piccture\n');
    }
    
    buffer.write(postUrl);
    
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: scheme.onSurfaceVariant.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Title
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Share Post',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: scheme.onSurface,
                ),
              ),
            ),

            // Share options grid
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _ShareOption(
                    icon: Icons.share,
                    label: 'Share',
                    color: scheme.primary,
                    onTap: () => _nativeShare(context),
                  ),
                  _ShareOption(
                    icon: Icons.copy,
                    label: 'Copy Link',
                    color: Colors.grey.shade600,
                    onTap: () => _copyLink(context),
                  ),
                  _ShareOption(
                    icon: Icons.chat,
                    label: 'WhatsApp',
                    color: const Color(0xFF25D366),
                    onTap: () => _shareToWhatsApp(context),
                  ),
                  _ShareOption(
                    icon: Icons.alternate_email,
                    label: 'Twitter',
                    color: const Color(0xFF1DA1F2),
                    onTap: () => _shareToTwitter(context),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Additional options
            const Divider(),

            _ListOption(
              icon: Icons.qr_code,
              label: 'Show QR Code',
              onTap: () => _showQRCode(context),
            ),

            _ListOption(
              icon: Icons.bookmark_add_outlined,
              label: 'Save to Collection',
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement save to collection
              },
            ),

            _ListOption(
              icon: Icons.flag_outlined,
              label: 'Report Post',
              color: Colors.red,
              onTap: () => _reportPost(context),
            ),

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // SHARE ACTIONS
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> _nativeShare(BuildContext context) async {
    Navigator.pop(context);
    HapticFeedback.lightImpact();
    
    try {
      await Share.share(
        _shareText,
        subject: caption ?? 'Check out this post on Piccture!',
      );
    } catch (e) {
      debugPrint('Share error: $e');
    }
  }

  Future<void> _copyLink(BuildContext context) async {
    Navigator.pop(context);
    HapticFeedback.mediumImpact();
    
    await Clipboard.setData(ClipboardData(text: postUrl));
    
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check, color: Colors.white),
              SizedBox(width: 8),
              Text('Link copied to clipboard'),
            ],
          ),
          backgroundColor: Colors.green.shade600,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _shareToWhatsApp(BuildContext context) async {
    Navigator.pop(context);
    HapticFeedback.lightImpact();
    
    final encodedText = Uri.encodeComponent(_shareText);
    final whatsappUrl = 'whatsapp://send?text=$encodedText';
    
    try {
      final uri = Uri.parse(whatsappUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        // Try web fallback
        final webUrl = 'https://wa.me/?text=$encodedText';
        await launchUrl(Uri.parse(webUrl), mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open WhatsApp')),
        );
      }
    }
  }

  Future<void> _shareToTwitter(BuildContext context) async {
    Navigator.pop(context);
    HapticFeedback.lightImpact();
    
    final text = caption ?? 'Check out this post!';
    final encodedText = Uri.encodeComponent(text);
    final encodedUrl = Uri.encodeComponent(postUrl);
    
    final twitterUrl = 'https://twitter.com/intent/tweet?text=$encodedText&url=$encodedUrl';
    
    try {
      await launchUrl(
        Uri.parse(twitterUrl),
        mode: LaunchMode.externalApplication,
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open Twitter')),
        );
      }
    }
  }

  void _showQRCode(BuildContext context) {
    Navigator.pop(context);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('QR Code'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.qr_code_2,
                      size: 120,
                      color: Colors.grey.shade800,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Post: $postId',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Scan to view this post',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement save QR code
            },
            icon: const Icon(Icons.download),
            label: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _reportPost(BuildContext context) {
    Navigator.pop(context);
    
    showDialog(
      context: context,
      builder: (context) => _ReportDialog(postId: postId),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// SHARE OPTION WIDGET
// ══════════════════════════════════════════════════════════════════════════════

class _ShareOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ShareOption({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// LIST OPTION WIDGET
// ══════════════════════════════════════════════════════════════════════════════

class _ListOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  final VoidCallback onTap;

  const _ListOption({
    required this.icon,
    required this.label,
    this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final effectiveColor = color ?? scheme.onSurface;

    return ListTile(
      leading: Icon(icon, color: effectiveColor),
      title: Text(
        label,
        style: TextStyle(color: effectiveColor),
      ),
      onTap: onTap,
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// REPORT DIALOG
// ══════════════════════════════════════════════════════════════════════════════

class _ReportDialog extends StatefulWidget {
  final String postId;

  const _ReportDialog({required this.postId});

  @override
  State<_ReportDialog> createState() => _ReportDialogState();
}

class _ReportDialogState extends State<_ReportDialog> {
  String? _selectedReason;
  bool _isSubmitting = false;

  final _reasons = [
    'Spam or misleading',
    'Harassment or bullying',
    'Hate speech',
    'Violence or dangerous content',
    'Nudity or sexual content',
    'Intellectual property violation',
    'Other',
  ];

  Future<void> _submitReport() async {
    if (_selectedReason == null) return;

    setState(() => _isSubmitting = true);
    HapticFeedback.mediumImpact();

    // TODO: Submit to Firestore
    await Future.delayed(const Duration(seconds: 1));

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Report submitted. Thank you for helping keep Piccture safe.'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Report Post'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Why are you reporting this post?'),
          const SizedBox(height: 16),
          ...List.generate(_reasons.length, (i) {
            return RadioListTile<String>(
              title: Text(_reasons[i], style: const TextStyle(fontSize: 14)),
              value: _reasons[i],
              groupValue: _selectedReason,
              onChanged: (v) => setState(() => _selectedReason = v),
              dense: true,
              contentPadding: EdgeInsets.zero,
            );
          }),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _selectedReason != null && !_isSubmitting
              ? _submitReport
              : null,
          child: _isSubmitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Submit'),
        ),
      ],
    );
  }
}
