import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

/// ============================================================================
/// REPORT SERVICE
/// ============================================================================
/// Handles content reporting for moderation.
/// 
/// Report Types:
/// - post: Report a post
/// - user: Report a user
/// - comment: Report a comment/reply
/// 
/// Reasons:
/// - spam
/// - harassment
/// - inappropriate
/// - violence
/// - misinformation
/// - copyright
/// - other
/// ============================================================================
class ReportService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  ReportService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance;

  /// Create a report
  Future<bool> createReport({
    required String type, // post, user, comment
    required String targetId,
    required String reason,
    String? details,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return false;

    try {
      await _firestore.collection('reports').add({
        'type': type,
        'targetId': targetId,
        'reason': reason,
        'details': details,
        'reporterId': user.uid,
        'reporterEmail': user.email,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ Report created for $type: $targetId');
      return true;
    } catch (e) {
      debugPrint('❌ Error creating report: $e');
      return false;
    }
  }

  /// Check if user already reported this target
  Future<bool> hasReported(String targetId) async {
    final user = _auth.currentUser;
    if (user == null) return false;

    try {
      final snap = await _firestore
          .collection('reports')
          .where('targetId', isEqualTo: targetId)
          .where('reporterId', isEqualTo: user.uid)
          .limit(1)
          .get();

      return snap.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }
}

/// ============================================================================
/// REPORT BOTTOM SHEET
/// ============================================================================
/// Shows a bottom sheet for users to report content.
/// ============================================================================
class ReportBottomSheet extends StatefulWidget {
  final String type; // post, user, comment
  final String targetId;
  final String? targetName; // For display

  const ReportBottomSheet({
    super.key,
    required this.type,
    required this.targetId,
    this.targetName,
  });

  /// Show the report sheet
  static Future<bool?> show(
    BuildContext context, {
    required String type,
    required String targetId,
    String? targetName,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => ReportBottomSheet(
        type: type,
        targetId: targetId,
        targetName: targetName,
      ),
    );
  }

  @override
  State<ReportBottomSheet> createState() => _ReportBottomSheetState();
}

class _ReportBottomSheetState extends State<ReportBottomSheet> {
  final ReportService _service = ReportService();
  String? _selectedReason;
  final _detailsController = TextEditingController();
  bool _isSubmitting = false;

  static const _reasons = [
    ('spam', 'Spam', Icons.report),
    ('harassment', 'Harassment or bullying', Icons.person_off),
    ('inappropriate', 'Inappropriate content', Icons.block),
    ('violence', 'Violence or threats', Icons.warning),
    ('misinformation', 'Misinformation', Icons.info),
    ('copyright', 'Copyright violation', Icons.copyright),
    ('other', 'Other', Icons.more_horiz),
  ];

  @override
  void dispose() {
    _detailsController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_selectedReason == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a reason')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final success = await _service.createReport(
      type: widget.type,
      targetId: widget.targetId,
      reason: _selectedReason!,
      details: _detailsController.text.trim().isNotEmpty
          ? _detailsController.text.trim()
          : null,
    );

    if (!mounted) return;

    if (success) {
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Report submitted. Thank you!'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to submit report. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
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
                Icon(Icons.flag, color: scheme.error),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Report ${widget.type}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (widget.targetName != null)
                        Text(
                          widget.targetName!,
                          style: TextStyle(
                            fontSize: 14,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Reasons list
          Expanded(
            child: ListView(
              controller: scrollController,
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  'Why are you reporting this?',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurface,
                  ),
                ),
                const SizedBox(height: 12),

                ..._reasons.map((r) => RadioListTile<String>(
                  value: r.$1,
                  groupValue: _selectedReason,
                  onChanged: (value) => setState(() => _selectedReason = value),
                  title: Text(r.$2),
                  secondary: Icon(r.$3, size: 20),
                  contentPadding: EdgeInsets.zero,
                )),

                const SizedBox(height: 16),

                // Details field
                TextField(
                  controller: _detailsController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Additional details (optional)',
                    hintText: 'Tell us more about the issue...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Submit button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: scheme.error,
                      foregroundColor: scheme.onError,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Submit Report',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                  ),
                ),

                const SizedBox(height: 16),

                Text(
                  'Reports are reviewed within 24 hours. False reports may result in account restrictions.',
                  style: TextStyle(
                    fontSize: 12,
                    color: scheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
