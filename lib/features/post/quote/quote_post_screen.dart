import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'quote_controller.dart';
import 'quote_model.dart';
import 'quoted_post_card.dart';

/// ------------------------------------------------------------
/// QUOTE POST SCREEN
/// ------------------------------------------------------------
/// Full-screen UI for creating a quote post.
/// 
/// Features:
/// - Preview of original post being quoted
/// - Commentary input with character counter
/// - Validation feedback
/// - Loading states
/// - Dark mode support
/// 
/// Usage:
/// ```dart
/// Navigator.push(
///   context,
///   MaterialPageRoute(
///     builder: (_) => QuotePostScreen(postId: originalPostId),
///   ),
/// );
/// ```
/// ------------------------------------------------------------
class QuotePostScreen extends StatelessWidget {
  final String postId;

  const QuotePostScreen({super.key, required this.postId});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => QuoteController(originalPostId: postId),
      child: const _QuotePostScreenContent(),
    );
  }
}

class _QuotePostScreenContent extends StatelessWidget {
  const _QuotePostScreenContent();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final controller = context.watch<QuoteController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quote Post'),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          // POST BUTTON
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _buildPostButton(context, controller, scheme),
          ),
        ],
      ),
      body: SafeArea(
        child: controller.isLoading && controller.quotedPreview == null
            ? const Center(child: CircularProgressIndicator())
            : _buildBody(context, controller, theme, scheme),
      ),
    );
  }

  Widget _buildPostButton(
    BuildContext context,
    QuoteController controller,
    ColorScheme scheme,
  ) {
    final isLoading = controller.state == QuoteState.creating;
    final canSubmit = controller.canSubmit;

    return TextButton(
      onPressed: canSubmit ? () => controller.submitQuote(context) : null,
      style: TextButton.styleFrom(
        backgroundColor: canSubmit ? scheme.primary : scheme.surfaceContainerHighest,
        foregroundColor: canSubmit ? scheme.onPrimary : scheme.onSurfaceVariant,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      child: isLoading
          ? SizedBox(
              height: 18,
              width: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: scheme.onPrimary,
              ),
            )
          : const Text(
              'Post',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    QuoteController controller,
    ThemeData theme,
    ColorScheme scheme,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // VALIDATION ERROR BANNER
          if (!controller.isValidPost && controller.errorMessage != null)
            _buildErrorBanner(controller, scheme),

          // COMMENTARY INPUT
          _buildCommentaryInput(context, controller, theme, scheme),

          const SizedBox(height: 16),

          // CHARACTER COUNTER
          _buildCharacterCounter(controller, scheme),

          const SizedBox(height: 20),

          // QUOTED POST PREVIEW LABEL
          Text(
            'Quoting',
            style: theme.textTheme.labelMedium?.copyWith(
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 8),

          // QUOTED POST PREVIEW
          if (controller.quotedPreview != null)
            QuotedPostCard(
              preview: controller.quotedPreview!,
              onTap: null, // Disable tap in creation screen
            )
          else
            _buildLoadingPreview(scheme),

          const SizedBox(height: 24),

          // NESTED QUOTE WARNING (if applicable)
          if (controller.validationResult?.error == QuoteValidationError.cannotQuoteQuote)
            _buildNestedQuoteWarning(scheme),
        ],
      ),
    );
  }

  Widget _buildErrorBanner(QuoteController controller, ColorScheme scheme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: scheme.onErrorContainer, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              controller.errorMessage!,
              style: TextStyle(
                color: scheme.onErrorContainer,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentaryInput(
    BuildContext context,
    QuoteController controller,
    ThemeData theme,
    ColorScheme scheme,
  ) {
    return TextField(
      controller: controller.commentaryController,
      maxLines: 5,
      minLines: 3,
      enabled: controller.isValidPost,
      style: theme.textTheme.bodyLarge,
      decoration: InputDecoration(
        hintText: 'Add your thoughts... (optional)',
        hintStyle: TextStyle(color: scheme.onSurfaceVariant.withOpacity(0.6)),
        filled: true,
        fillColor: scheme.surfaceContainerHighest.withOpacity(0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: scheme.primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.all(16),
      ),
      onChanged: (_) {
        // Trigger rebuild to update character counter
        controller.notifyListeners();
      },
    );
  }

  Widget _buildCharacterCounter(QuoteController controller, ColorScheme scheme) {
    final remaining = controller.remainingCharacters;
    final isOverLimit = remaining < 0;
    final isNearLimit = remaining <= 50 && remaining >= 0;

    Color counterColor;
    if (isOverLimit) {
      counterColor = scheme.error;
    } else if (isNearLimit) {
      counterColor = scheme.tertiary;
    } else {
      counterColor = scheme.onSurfaceVariant.withOpacity(0.6);
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (isOverLimit)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Icon(Icons.warning_amber_rounded, size: 16, color: scheme.error),
          ),
        Text(
          '$remaining',
          style: TextStyle(
            color: counterColor,
            fontSize: 13,
            fontWeight: isOverLimit ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        Text(
          ' / ${controller.maxCommentaryLength}',
          style: TextStyle(
            color: scheme.onSurfaceVariant.withOpacity(0.4),
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingPreview(ColorScheme scheme) {
    return Container(
      height: 100,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }

  Widget _buildNestedQuoteWarning(ColorScheme scheme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.tertiaryContainer.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.tertiary.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: scheme.tertiary, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'This is already a quote. You can only quote original posts.',
              style: TextStyle(
                color: scheme.onTertiaryContainer,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// ------------------------------------------------------------
/// QUOTE ACTION BUTTON
/// ------------------------------------------------------------
/// Reusable button for triggering quote creation from anywhere.
/// Shows quote count and handles navigation.
/// ------------------------------------------------------------
class QuoteActionButton extends StatelessWidget {
  final String postId;
  final int quoteCount;
  final bool compact;

  const QuoteActionButton({
    super.key,
    required this.postId,
    this.quoteCount = 0,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: () => _navigateToQuote(context),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.format_quote_rounded,
              size: compact ? 18 : 22,
              color: scheme.onSurfaceVariant,
            ),
            if (quoteCount > 0) ...[
              const SizedBox(width: 4),
              Text(
                _formatCount(quoteCount),
                style: TextStyle(
                  color: scheme.onSurfaceVariant,
                  fontSize: compact ? 12 : 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _navigateToQuote(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => QuotePostScreen(postId: postId),
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }
}
