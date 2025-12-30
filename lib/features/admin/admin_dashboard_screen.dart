// ============================================================================
// FILE: lib/features/admin/admin_dashboard_screen.dart
// ============================================================================
// FIXES:
// ✅ Error handling on all tabs
// ✅ Shows helpful messages when data can't load
// ✅ Uses withValues instead of withOpacity
// ✅ Catches permission errors
// ============================================================================

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    debugPrint('🔍 Admin Dashboard initialized');
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('🔍 Building Admin Dashboard');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.verified), text: 'Verify'),
            Tab(icon: Icon(Icons.report), text: 'Reports'),
            Tab(icon: Icon(Icons.analytics), text: 'Stats'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [_VerificationTab(), _ReportsTab(), _StatsTab()],
      ),
    );
  }
}

// ============================================================================
// VERIFICATION TAB
// ============================================================================

class _VerificationTab extends StatelessWidget {
  const _VerificationTab();

  @override
  Widget build(BuildContext context) {
    debugPrint('🔍 Building Verification Tab');

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('verification_requests')
          .where('status', isEqualTo: 'pending')
          .snapshots(),
      builder: (context, snapshot) {
        // Error state
        if (snapshot.hasError) {
          debugPrint('❌ Verification Tab Error: ${snapshot.error}');
          return _ErrorView(
            icon: Icons.error_outline,
            title: 'Error loading verification requests',
            message: '${snapshot.error}',
            hint: 'This might be a Firestore index or permission issue.',
          );
        }

        // Loading state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        // No data
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _EmptyView(
            icon: Icons.verified_outlined,
            title: 'No pending requests',
            message: 'All verification requests have been processed.',
          );
        }

        final requests = snapshot.data!.docs;
        debugPrint('✅ Found ${requests.length} pending verification requests');

        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: requests.length,
          itemBuilder: (context, index) {
            final data = requests[index].data() as Map<String, dynamic>;
            final docId = requests[index].id;

            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.blue.shade50,
                  child: const Icon(Icons.verified_user, color: Colors.blue),
                ),
                title: Text(
                  data['userName'] ?? data['fullName'] ?? 'Unknown User',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Type: ${data['type'] ?? 'gazetteer'}'),
                    if (data['reason'] != null)
                      Text(
                        'Reason: ${data['reason']}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                  ],
                ),
                isThreeLine: data['reason'] != null,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.check_circle, color: Colors.green),
                      tooltip: 'Approve',
                      onPressed: () => _approve(context, docId, data['userId']),
                    ),
                    IconButton(
                      icon: const Icon(Icons.cancel, color: Colors.red),
                      tooltip: 'Reject',
                      onPressed: () => _reject(context, docId),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _approve(
    BuildContext context,
    String docId,
    String? userId,
  ) async {
    if (userId == null) {
      _showSnackBar(context, 'Error: No user ID', Colors.red);
      return;
    }

    try {
      final batch = FirebaseFirestore.instance.batch();

      batch.update(
        FirebaseFirestore.instance
            .collection('verification_requests')
            .doc(docId),
        {'status': 'approved', 'reviewedAt': FieldValue.serverTimestamp()},
      );

      batch.update(FirebaseFirestore.instance.collection('users').doc(userId), {
        'isVerified': true,
        'type': 'gazetteer',
        'verifiedAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();

      if (context.mounted) {
        _showSnackBar(context, '✅ User verified successfully!', Colors.green);
      }
    } catch (e) {
      debugPrint('❌ Approve error: $e');
      if (context.mounted) {
        _showSnackBar(context, 'Error: $e', Colors.red);
      }
    }
  }

  Future<void> _reject(BuildContext context, String docId) async {
    try {
      await FirebaseFirestore.instance
          .collection('verification_requests')
          .doc(docId)
          .update({
            'status': 'rejected',
            'reviewedAt': FieldValue.serverTimestamp(),
          });

      if (context.mounted) {
        _showSnackBar(context, 'Request rejected', Colors.orange);
      }
    } catch (e) {
      debugPrint('❌ Reject error: $e');
      if (context.mounted) {
        _showSnackBar(context, 'Error: $e', Colors.red);
      }
    }
  }

  void _showSnackBar(BuildContext context, String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

// ============================================================================
// REPORTS TAB
// ============================================================================

class _ReportsTab extends StatelessWidget {
  const _ReportsTab();

  @override
  Widget build(BuildContext context) {
    debugPrint('🔍 Building Reports Tab');

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('reports')
          .where('status', isEqualTo: 'pending')
          .snapshots(),
      builder: (context, snapshot) {
        // Error state
        if (snapshot.hasError) {
          debugPrint('❌ Reports Tab Error: ${snapshot.error}');
          return _ErrorView(
            icon: Icons.error_outline,
            title: 'Error loading reports',
            message: '${snapshot.error}',
            hint:
                'Make sure the "reports" collection exists and you have permission.',
          );
        }

        // Loading state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        // No data
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _EmptyView(
            icon: Icons.report_off,
            title: 'No pending reports',
            message: 'All reports have been reviewed.',
          );
        }

        final reports = snapshot.data!.docs;
        debugPrint('✅ Found ${reports.length} pending reports');

        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: reports.length,
          itemBuilder: (context, index) {
            final data = reports[index].data() as Map<String, dynamic>;
            final docId = reports[index].id;

            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.orange.shade50,
                  child: const Icon(Icons.flag, color: Colors.orange),
                ),
                title: Text(data['reason'] ?? 'Report'),
                subtitle: Text('Post: ${data['postId'] ?? 'Unknown'}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.check, color: Colors.green),
                      tooltip: 'Resolve',
                      onPressed: () => _resolve(context, docId, 'resolved'),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.grey),
                      tooltip: 'Dismiss',
                      onPressed: () => _resolve(context, docId, 'dismissed'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _resolve(
    BuildContext context,
    String docId,
    String status,
  ) async {
    try {
      await FirebaseFirestore.instance.collection('reports').doc(docId).update({
        'status': status,
        'reviewedAt': FieldValue.serverTimestamp(),
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Report $status'),
            backgroundColor: status == 'resolved' ? Colors.green : Colors.grey,
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Resolve error: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}

// ============================================================================
// STATS TAB
// ============================================================================

class _StatsTab extends StatelessWidget {
  const _StatsTab();

  @override
  Widget build(BuildContext context) {
    debugPrint('🔍 Building Stats Tab');

    return FutureBuilder<Map<String, int>>(
      future: _loadStats(),
      builder: (context, snapshot) {
        // Error state
        if (snapshot.hasError) {
          debugPrint('❌ Stats Tab Error: ${snapshot.error}');
          return _ErrorView(
            icon: Icons.analytics_outlined,
            title: 'Error loading statistics',
            message: '${snapshot.error}',
            hint: 'Check Firestore permissions.',
          );
        }

        // Loading state
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final stats = snapshot.data!;
        debugPrint('✅ Stats loaded: $stats');

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _StatCard(
                icon: Icons.people,
                label: 'Total Users',
                value: stats['users'] ?? 0,
                color: Colors.blue,
              ),
              _StatCard(
                icon: Icons.photo_library,
                label: 'Total Posts',
                value: stats['posts'] ?? 0,
                color: Colors.green,
              ),
              _StatCard(
                icon: Icons.verified,
                label: 'Verified Users',
                value: stats['verified'] ?? 0,
                color: Colors.purple,
              ),
              _StatCard(
                icon: Icons.pending,
                label: 'Pending Verifications',
                value: stats['pendingVerifications'] ?? 0,
                color: Colors.orange,
              ),
              _StatCard(
                icon: Icons.report,
                label: 'Pending Reports',
                value: stats['reports'] ?? 0,
                color: Colors.red,
              ),
            ],
          ),
        );
      },
    );
  }

  Future<Map<String, int>> _loadStats() async {
    try {
      final results = await Future.wait([
        _getCount('users'),
        _getCount('posts'),
        _getCountWhere('users', 'isVerified', true),
        _getCountWhere('verification_requests', 'status', 'pending'),
        _getCountWhere('reports', 'status', 'pending'),
      ]);

      return {
        'users': results[0],
        'posts': results[1],
        'verified': results[2],
        'pendingVerifications': results[3],
        'reports': results[4],
      };
    } catch (e) {
      debugPrint('❌ Error loading stats: $e');
      rethrow;
    }
  }

  Future<int> _getCount(String collection) async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection(collection)
          .count()
          .get();
      return snap.count ?? 0;
    } catch (e) {
      debugPrint('❌ Error counting $collection: $e');
      return 0;
    }
  }

  Future<int> _getCountWhere(
    String collection,
    String field,
    dynamic value,
  ) async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection(collection)
          .where(field, isEqualTo: value)
          .count()
          .get();
      return snap.count ?? 0;
    } catch (e) {
      debugPrint('❌ Error counting $collection where $field=$value: $e');
      return 0;
    }
  }
}

// ============================================================================
// STAT CARD WIDGET
// ============================================================================

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final int value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.15),
          child: Icon(icon, color: color),
        ),
        title: Text(label),
        trailing: Text(
          _formatCount(value),
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}K';
    return count.toString();
  }
}

// ============================================================================
// EMPTY VIEW WIDGET
// ============================================================================

class _EmptyView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _EmptyView({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// ERROR VIEW WIDGET
// ============================================================================

class _ErrorView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String hint;

  const _ErrorView({
    required this.icon,
    required this.title,
    required this.message,
    required this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: Colors.red.shade300),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.red.shade700,
                  fontFamily: 'monospace',
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              hint,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}
