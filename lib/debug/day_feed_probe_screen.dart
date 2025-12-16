import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DayFeedProbeScreen extends StatefulWidget {
  const DayFeedProbeScreen({super.key});

  @override
  State<DayFeedProbeScreen> createState() => _DayFeedProbeScreenState();
}

class _DayFeedProbeScreenState extends State<DayFeedProbeScreen> {
  String status = "Running probe...";
  int postCount = 0;
  Map<String, dynamic>? firstPost;

  @override
  void initState() {
    super.initState();
    _runProbe();
  }

  Future<void> _runProbe() async {
    try {
      final startOfToday = DateTime(
        DateTime.now().year,
        DateTime.now().month,
        DateTime.now().day,
      );

      final snap = await FirebaseFirestore.instance
          .collection('posts')
          .where(
            'createdAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfToday),
          )
          .where('isRemoved', isEqualTo: false)
          .limit(5)
          .get();

      setState(() {
        postCount = snap.docs.length;
        if (snap.docs.isNotEmpty) {
          firstPost = snap.docs.first.data();
        }
        status = "SUCCESS";
      });
    } catch (e) {
      setState(() {
        status = "ERROR: $e";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Day Feed Probe")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Status: $status"),
            const SizedBox(height: 12),
            Text("Post count (today): $postCount"),
            const SizedBox(height: 12),
            if (firstPost != null) ...[
              const Text("First post fields:"),
              const SizedBox(height: 8),
              Text(firstPost.toString()),
            ],
          ],
        ),
      ),
    );
  }
}
