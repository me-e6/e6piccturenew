// ============================================================================
// FILE: lib/features/admin/admin_dashboard_screen.dart
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
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
        children: const [
          _VerificationTab(),
          _ReportsTab(),
          _StatsTab(),
        ],
      ),
    );
  }
}

class _VerificationTab extends StatelessWidget {
  const _VerificationTab();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('verification_requests')
          .where('status', isEqualTo: 'pending')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final requests = snapshot.data!.docs;
        if (requests.isEmpty) {
          return const Center(child: Text('No pending requests'));
        }

        return ListView.builder(
          itemCount: requests.length,
          itemBuilder: (context, index) {
            final data = requests[index].data() as Map<String, dynamic>;
            final docId = requests[index].id;

            return Card(
              margin: const EdgeInsets.all(8),
              child: ListTile(
                leading: const Icon(Icons.verified_user, color: Colors.blue),
                title: Text(data['userName'] ?? 'Unknown'),
                subtitle: Text('Type: ${data['type'] ?? 'gazetteer'}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.check, color: Colors.green),
                      onPressed: () => _approve(docId, data['userId']),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.red),
                      onPressed: () => _reject(docId),
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

  void _approve(String docId, String? userId) async {
    if (userId == null) return;

    final batch = FirebaseFirestore.instance.batch();

    // Update request status
    batch.update(
      FirebaseFirestore.instance.collection('verification_requests').doc(docId),
      {'status': 'approved', 'reviewedAt': FieldValue.serverTimestamp()},
    );

    // Update user verification
    batch.update(
      FirebaseFirestore.instance.collection('users').doc(userId),
      {'isVerified': true, 'role': 'gazetteer'},
    );

    await batch.commit();
  }

  void _reject(String docId) async {
    await FirebaseFirestore.instance
        .collection('verification_requests')
        .doc(docId)
        .update({'status': 'rejected', 'reviewedAt': FieldValue.serverTimestamp()});
  }
}

class _ReportsTab extends StatelessWidget {
  const _ReportsTab();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('reports')
          .where('status', isEqualTo: 'pending')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final reports = snapshot.data!.docs;
        if (reports.isEmpty) {
          return const Center(child: Text('No pending reports'));
        }

        return ListView.builder(
          itemCount: reports.length,
          itemBuilder: (context, index) {
            final data = reports[index].data() as Map<String, dynamic>;
            final docId = reports[index].id;

            return Card(
              margin: const EdgeInsets.all(8),
              child: ExpansionTile(
                leading: Icon(
                  Icons.flag,
                  color: _getReportColor(data['reason']),
                ),
                title: Text(data['reason'] ?? 'Report'),
                subtitle: Text('Target: ${data['targetType'] ?? 'unknown'}'),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Details: ${data['details'] ?? 'No details'}'),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () => _dismissReport(docId),
                              child: const Text('Dismiss'),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: () => _takeAction(docId, data),
                              child: const Text('Take Action'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Color _getReportColor(String? reason) {
    switch (reason) {
      case 'spam':
        return Colors.orange;
      case 'harassment':
        return Colors.red;
      case 'inappropriate':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  void _dismissReport(String docId) async {
    await FirebaseFirestore.instance.collection('reports').doc(docId).update({
      'status': 'dismissed',
      'reviewedAt': FieldValue.serverTimestamp(),
    });
  }

  void _takeAction(String docId, Map<String, dynamic> data) async {
    // Implement action based on report type
    await FirebaseFirestore.instance.collection('reports').doc(docId).update({
      'status': 'actioned',
      'reviewedAt': FieldValue.serverTimestamp(),
    });
  }
}

class _StatsTab extends StatelessWidget {
  const _StatsTab();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, int>>(
      future: _loadStats(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final stats = snapshot.data!;

        return Padding(
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
                icon: Icons.photo,
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
                icon: Icons.report,
                label: 'Pending Reports',
                value: stats['reports'] ?? 0,
                color: Colors.orange,
              ),
            ],
          ),
        );
      },
    );
  }

  Future<Map<String, int>> _loadStats() async {
    final users = await FirebaseFirestore.instance.collection('users').count().get();
    final posts = await FirebaseFirestore.instance.collection('posts').count().get();
    final verified = await FirebaseFirestore.instance
        .collection('users')
        .where('isVerified', isEqualTo: true)
        .count()
        .get();
    final reports = await FirebaseFirestore.instance
        .collection('reports')
        .where('status', isEqualTo: 'pending')
        .count()
        .get();

    return {
      'users': users.count ?? 0,
      'posts': posts.count ?? 0,
      'verified': verified.count ?? 0,
      'reports': reports.count ?? 0,
    };
  }
}

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
          backgroundColor: color.withOpacity(0.2),
          child: Icon(icon, color: color),
        ),
        title: Text(label),
        trailing: Text(
          value.toString(),
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ),
    );
  }
}
