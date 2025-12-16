// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'reply_service.dart';

class ReplyController extends ChangeNotifier {
  final String postId;
  final ReplyService _service = ReplyService();

  ReplyController(this.postId);

  final TextEditingController textController = TextEditingController();
  bool isPosting = false;

  Future<void> submitReply(BuildContext context) async {
    final text = textController.text.trim();
    if (text.isEmpty) return;

    isPosting = true;
    notifyListeners();

    await _service.addReply(postId: postId, text: text);

    isPosting = false;
    notifyListeners();

    Navigator.pop(context);
  }
}
