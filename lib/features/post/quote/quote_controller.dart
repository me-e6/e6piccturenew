// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'quote_model.dart';
import 'quote_service.dart';

/// ------------------------------------------------------------
/// QUOTE STATE
/// ------------------------------------------------------------
enum QuoteState {
  idle,
  validating,
  creating,
  success,
  error,
}

/// ------------------------------------------------------------
/// QUOTE CONTROLLER
/// ------------------------------------------------------------
/// Manages state for creating and managing quote posts.
/// 
/// ✅ UPDATED: Now uses 30 character limit for visual quote design
/// 
/// Usage:
/// ```dart
/// ChangeNotifierProvider(
///   create: (_) => QuoteController(postId: originalPostId),
///   child: QuotePostScreen(),
/// )
/// ```
/// ------------------------------------------------------------
class QuoteController extends ChangeNotifier {
  final String originalPostId;
  final QuoteService _service;

  // ------------------------------------------------------------
  // STATE
  // ------------------------------------------------------------
  QuoteState _state = QuoteState.idle;
  QuoteState get state => _state;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  bool _isValidPost = false;
  bool get isValidPost => _isValidPost;

  QuoteValidationResult? _validationResult;
  QuoteValidationResult? get validationResult => _validationResult;

  // Original post data (loaded for preview)
  Map<String, dynamic>? _originalPostData;
  Map<String, dynamic>? get originalPostData => _originalPostData;

  QuotedPostPreview? _quotedPreview;
  QuotedPostPreview? get quotedPreview => _quotedPreview;

  // Commentary input
  final TextEditingController commentaryController = TextEditingController();
  
  int get commentaryLength => commentaryController.text.trim().length;
  
  /// ✅ Now returns 30 (from QuotePostData.maxCommentaryLength)
  int get maxCommentaryLength => QuotePostData.maxCommentaryLength;
  
  bool get isCommentaryValid => commentaryLength <= maxCommentaryLength;
  int get remainingCharacters => maxCommentaryLength - commentaryLength;

  // Created quote post ID (for navigation after success)
  String? _createdQuoteId;
  String? get createdQuoteId => _createdQuoteId;

  // ------------------------------------------------------------
  // CONSTRUCTOR
  // ------------------------------------------------------------
  QuoteController({
    required this.originalPostId,
    QuoteService? service,
  }) : _service = service ?? QuoteService() {
    _initialize();
  }

  // ------------------------------------------------------------
  // INITIALIZATION
  // ------------------------------------------------------------
  Future<void> _initialize() async {
    await _loadOriginalPost();
    await _validateQuote();
  }

  /// Load original post data for preview display
  Future<void> _loadOriginalPost() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('posts')
          .doc(originalPostId)
          .get();

      if (doc.exists) {
        _originalPostData = doc.data();
        _quotedPreview = QuotedPostPreview.fromPostData(_originalPostData!, originalPostId);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading original post: $e');
    }
  }

  /// Validate if the post can be quoted
  Future<void> _validateQuote() async {
    _state = QuoteState.validating;
    notifyListeners();

    try {
      _validationResult = await _service.validateQuote(originalPostId);
      _isValidPost = _validationResult?.isValid ?? false;
      
      if (!_isValidPost) {
        _errorMessage = _validationResult?.message;
      }
      
      _state = QuoteState.idle;
    } catch (e) {
      _state = QuoteState.error;
      _errorMessage = 'Failed to validate: $e';
      _isValidPost = false;
    }
    
    notifyListeners();
  }

  // ------------------------------------------------------------
  // CREATE QUOTE
  // ------------------------------------------------------------
  
  /// Submit the quote post
  Future<bool> submitQuote(BuildContext context) async {
    // Validate state
    if (!_isValidPost) {
      _showSnackBar(context, _errorMessage ?? 'Cannot quote this post', isError: true);
      return false;
    }

    if (!isCommentaryValid) {
      _showSnackBar(context, 'Caption is too long (max $maxCommentaryLength chars)', isError: true);
      return false;
    }

    _state = QuoteState.creating;
    _errorMessage = null;
    notifyListeners();

    try {
      final commentary = commentaryController.text.trim();
      
      _createdQuoteId = await _service.createQuote(
        originalPostId: originalPostId,
        commentary: commentary.isNotEmpty ? commentary : null,
      );

      _state = QuoteState.success;
      notifyListeners();

      _showSnackBar(context, 'Quote posted! 🎉');
      
      // Pop after short delay to show success
      await Future.delayed(const Duration(milliseconds: 300));
      if (context.mounted) {
        Navigator.pop(context, _createdQuoteId);
      }
      
      return true;
    } catch (e) {
      _state = QuoteState.error;
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();

      _showSnackBar(context, _errorMessage ?? 'Failed to create quote', isError: true);
      return false;
    }
  }

  // ------------------------------------------------------------
  // HELPERS
  // ------------------------------------------------------------

  void _showSnackBar(BuildContext context, String message, {bool isError = false}) {
    if (!context.mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError 
            ? Theme.of(context).colorScheme.error
            : Theme.of(context).colorScheme.primary,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: isError ? 4 : 2),
      ),
    );
  }

  /// Check if currently processing
  bool get isLoading => _state == QuoteState.validating || _state == QuoteState.creating;

  /// Check if can submit
  bool get canSubmit => _isValidPost && !isLoading && isCommentaryValid;

  /// Reset controller state
  void reset() {
    _state = QuoteState.idle;
    _errorMessage = null;
    _createdQuoteId = null;
    commentaryController.clear();
    notifyListeners();
  }

  // ------------------------------------------------------------
  // DISPOSE
  // ------------------------------------------------------------
  @override
  void dispose() {
    commentaryController.dispose();
    super.dispose();
  }
}

/// ------------------------------------------------------------
/// QUOTES LIST CONTROLLER
/// ------------------------------------------------------------
/// Manages the list of quotes for a specific post.
/// Used in the "Quotes" tab/screen for viewing all quotes.
/// ------------------------------------------------------------
class QuotesListController extends ChangeNotifier {
  final String postId;
  final QuoteService _service;

  List<DocumentSnapshot> _quotes = [];
  List<DocumentSnapshot> get quotes => _quotes;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  // Stream subscription for real-time updates
  Stream<List<DocumentSnapshot>>? _quotesStream;

  QuotesListController({
    required this.postId,
    QuoteService? service,
  }) : _service = service ?? QuoteService() {
    _initialize();
  }

  void _initialize() {
    _quotesStream = _service.streamQuotesForPost(postId);
    _quotesStream?.listen(
      (quotes) {
        _quotes = quotes;
        _isLoading = false;
        _error = null;
        notifyListeners();
      },
      onError: (e) {
        _error = 'Failed to load quotes: $e';
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  /// Refresh quotes list
  Future<void> refresh() async {
    _isLoading = true;
    notifyListeners();

    try {
      _quotes = await _service.fetchQuotesForPost(postId);
      _error = null;
    } catch (e) {
      _error = 'Failed to refresh: $e';
    }

    _isLoading = false;
    notifyListeners();
  }
}

/// ------------------------------------------------------------
/// USER QUOTES CONTROLLER
/// ------------------------------------------------------------
/// Manages quotes created by a specific user.
/// Used in the profile "Quotes" tab.
/// ------------------------------------------------------------
class UserQuotesController extends ChangeNotifier {
  final String userId;
  final QuoteService _service;

  List<DocumentSnapshot> _quotes = [];
  List<DocumentSnapshot> get quotes => _quotes;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  UserQuotesController({
    required this.userId,
    QuoteService? service,
  }) : _service = service ?? QuoteService() {
    _initialize();
  }

  void _initialize() {
    _service.streamUserQuotes(userId).listen(
      (quotes) {
        _quotes = quotes;
        _isLoading = false;
        _error = null;
        notifyListeners();
      },
      onError: (e) {
        _error = 'Failed to load quotes: $e';
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  bool get isEmpty => !_isLoading && _quotes.isEmpty;
  int get count => _quotes.length;
}
