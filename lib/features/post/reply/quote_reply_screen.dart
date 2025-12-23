import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../engagement/engagement_controller.dart';

class QuoteReplyScreen extends StatefulWidget {
  final String postId;

  const QuoteReplyScreen({super.key, required this.postId});

  @override
  State<QuoteReplyScreen> createState() => _QuoteReplyScreenState();
}

class _QuoteReplyScreenState extends State<QuoteReplyScreen> {
  final _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final engagement = context.read<EngagementController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quote'),
        actions: [
          TextButton(
            onPressed: () async {
              // NOTE: Actual quote-post creation handled elsewhere
              await engagement.incrementQuoteReply();
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Post'),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: TextField(
          controller: _controller,
          maxLines: 6,
          decoration: const InputDecoration(
            hintText: 'Add your thoughts…',
            border: OutlineInputBorder(),
          ),
        ),
      ),
    );
  }
}
