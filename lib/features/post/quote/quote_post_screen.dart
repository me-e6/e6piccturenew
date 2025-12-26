import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'quote_controller.dart';
import 'quote_model.dart';

/// ------------------------------------------------------------
/// QUOTE POST SCREEN - v2 (Visual Quote Design)
/// ------------------------------------------------------------
/// Full-screen UI for creating a quote post.
///
/// ✅ NEW FEATURES:
/// - Live preview showing how quote will look in feed
/// - 30 character limit for short, punchy captions
/// - Visual card design (image-first)
/// - Caption appears as overlay on image
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
        backgroundColor: canSubmit
            ? scheme.primary
            : scheme.surfaceContainerHighest,
        foregroundColor: canSubmit ? scheme.onPrimary : scheme.onSurfaceVariant,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
          : const Text('Post', style: TextStyle(fontWeight: FontWeight.w600)),
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

          // ═══════════════════════════════════════════════════════════════
          // ✅ NEW: LIVE PREVIEW CARD (Shows how it will look in feed)
          // ═══════════════════════════════════════════════════════════════
          if (controller.quotedPreview != null)
            _VisualQuotePreview(
              preview: controller.quotedPreview!,
              commentary: controller.commentaryController.text.trim(),
            )
          else
            _buildLoadingPreview(scheme),
          
          const SizedBox(height: 24),

          // ═══════════════════════════════════════════════════════════════
          // ✅ NEW: SHORT CAPTION INPUT (30 chars max)
          // ═══════════════════════════════════════════════════════════════
          Text(
            'Add a caption',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Short & punchy works best! (appears on image)',
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          
          _buildCommentaryInput(context, controller, theme, scheme),

          const SizedBox(height: 8),

          // CHARACTER COUNTER
          _buildCharacterCounter(controller, scheme),

          const SizedBox(height: 24),

          // ═══════════════════════════════════════════════════════════════
          // TIPS SECTION
          // ═══════════════════════════════════════════════════════════════
          _buildTipsSection(scheme),

          const SizedBox(height: 24),

          // NESTED QUOTE WARNING (if applicable)
          if (controller.validationResult?.error ==
              QuoteValidationError.cannotQuoteQuote)
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
              style: TextStyle(color: scheme.onErrorContainer, fontSize: 14),
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
      maxLines: 1, // ✅ Single line for short caption
      maxLength: QuotePostData.maxCommentaryLength,
      enabled: controller.isValidPost,
      style: theme.textTheme.bodyLarge?.copyWith(
        fontWeight: FontWeight.w500,
      ),
      inputFormatters: [
        LengthLimitingTextInputFormatter(QuotePostData.maxCommentaryLength),
      ],
      decoration: InputDecoration(
        hintText: 'e.g. "Must read! 📚"',
        hintStyle: TextStyle(
          color: scheme.onSurfaceVariant.withValues(alpha: 0.5),
        ),
        filled: true,
        fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: scheme.primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        counterText: '', // Hide default counter, we show custom one
      ),
      onChanged: (_) {
        // Trigger rebuild to update preview and counter
        controller.notifyListeners();
      },
    );
  }

  Widget _buildCharacterCounter(
    QuoteController controller,
    ColorScheme scheme,
  ) {
    final remaining = controller.remainingCharacters;
    final isOverLimit = remaining < 0;
    final isNearLimit = remaining <= 10 && remaining >= 0;

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
            child: Icon(
              Icons.warning_amber_rounded,
              size: 16,
              color: scheme.error,
            ),
          ),
        Text(
          '$remaining',
          style: TextStyle(
            color: counterColor,
            fontSize: 14,
            fontWeight: isOverLimit ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
        Text(
          ' / ${controller.maxCommentaryLength}',
          style: TextStyle(
            color: scheme.onSurfaceVariant.withOpacity(0.4),
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingPreview(ColorScheme scheme) {
    return AspectRatio(
      aspectRatio: 0.85,
      child: Container(
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
    );
  }

  Widget _buildTipsSection(ColorScheme scheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.tips_and_updates, color: scheme.primary, size: 18),
              const SizedBox(width: 8),
              Text(
                'Quote Tips',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: scheme.onPrimaryContainer,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _buildTip(scheme, '💬', 'Keep it short & memorable'),
          _buildTip(scheme, '✨', 'Use emojis for personality'),
          _buildTip(scheme, '📸', 'Your caption appears on the image'),
        ],
      ),
    );
  }

  Widget _buildTip(ColorScheme scheme, String emoji, String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                color: scheme.onPrimaryContainer.withValues(alpha: 0.8),
              ),
            ),
          ),
        ],
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
              style: TextStyle(color: scheme.onTertiaryContainer, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

/// ============================================================================
/// ✅ NEW: VISUAL QUOTE PREVIEW (Shows live preview as user types)
/// ============================================================================
class _VisualQuotePreview extends StatelessWidget {
  final QuotedPostPreview preview;
  final String commentary;

  const _VisualQuotePreview({
    required this.preview,
    required this.commentary,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final thumbnailUrl = preview.thumbnailUrl;
    final authorName = preview.authorName;
    final authorHandle = preview.authorHandle;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Preview',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: scheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        
        // Preview Card (aspect ratio like feed)
        AspectRatio(
          aspectRatio: 0.85,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // ═══════════════════════════════════════════════════════════
                  // BACKGROUND IMAGE (Full bleed)
                  // ═══════════════════════════════════════════════════════════
                  if (thumbnailUrl != null && thumbnailUrl.isNotEmpty)
                    CachedNetworkImage(
                      imageUrl: thumbnailUrl,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                        color: scheme.surfaceContainerHighest,
                        child: const Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                      errorWidget: (_, __, ___) => _buildPlaceholderBg(scheme),
                    )
                  else
                    _buildPlaceholderBg(scheme),

                  // ═══════════════════════════════════════════════════════════
                  // QUOTE OVERLAY (Top) - Commentary text
                  // ═══════════════════════════════════════════════════════════
                  if (commentary.isNotEmpty)
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.8),
                              Colors.black.withValues(alpha: 0.5),
                              Colors.transparent,
                            ],
                            stops: const [0.0, 0.7, 1.0],
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.format_quote_rounded,
                              color: Colors.white.withValues(alpha: 0.9),
                              size: 18,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                commentary,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black54,
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // ═══════════════════════════════════════════════════════════
                  // ORIGINAL POSTER BADGE (Bottom-right)
                  // ═══════════════════════════════════════════════════════════
                  Positioned(
                    bottom: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.photo_outlined,
                            color: Colors.white.withValues(alpha: 0.9),
                            size: 12,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            authorHandle != null
                                ? '@$authorHandle'
                                : authorName,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ═══════════════════════════════════════════════════════════
                  // QUOTE BADGE (Top-right)
                  // ═══════════════════════════════════════════════════════════
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: scheme.primary.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.repeat, color: Colors.white, size: 10),
                          SizedBox(width: 3),
                          Text(
                            'Quote',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPlaceholderBg(ColorScheme scheme) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            scheme.primaryContainer,
            scheme.secondaryContainer,
          ],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.format_quote_rounded,
          size: 60,
          color: scheme.onPrimaryContainer.withValues(alpha: 0.2),
        ),
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
      MaterialPageRoute(builder: (_) => QuotePostScreen(postId: postId)),
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
