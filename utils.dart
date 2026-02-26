import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/models.dart';
import '../providers/providers.dart';
import '../utils/utils.dart';
import '../widgets/widgets.dart';

class DetailScreen extends ConsumerStatefulWidget {
  final ContentIdea idea;

  const DetailScreen({
    super.key,
    required this.idea,
  });

  @override
  ConsumerState<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends ConsumerState<DetailScreen> {
  bool _hasGenerated = false;

  @override
  void initState() {
    super.initState();
    // Generate details when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _generateDetails();
    });
  }

  Future<void> _generateDetails() async {
    if (_hasGenerated) return;
    
    setState(() => _hasGenerated = true);
    
    // Check daily limit
    final settings = ref.read(settingsProvider);
    if (settings.isDailyLimitReached && !settings.hasApiKey) {
      return;
    }
    
    await ref.read(generationProvider.notifier).generateDetails(widget.idea);
  }

  Future<void> _regenerateDetails() async {
    await ref.read(generationProvider.notifier).regenerateDetails();
  }

  Future<void> _copyAll(ContentDetail detail) async {
    final allContent = '''
HOOKS:
${detail.hooks.join('\n')}

TITLES:
${detail.titles.join('\n')}

SCRIPT:
${detail.script.fullScript}

DESCRIPTION:
${detail.description}

HASHTAGS:
${detail.hashtags.join(' ')}
    '''.trim();

    final success = await CopyHelper.copyToClipboard(allContent);
    
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All content copied to clipboard!'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _exportToJson(ContentDetail detail) async {
    await ExportHelper.exportToJson(detail, widget.idea.title);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final generationState = ref.watch(generationProvider);
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Content Details'),
        centerTitle: true,
        actions: [
          if (generationState.detailResponse is ApiSuccess<DetailResponse>)
            PopupMenuButton<String>(
              onSelected: (value) {
                final detail = (generationState.detailResponse 
                    as ApiSuccess<DetailResponse>).data.detail;
                
                switch (value) {
                  case 'copy':
                    _copyAll(detail);
                    break;
                  case 'export':
                    _exportToJson(detail);
                    break;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'copy',
                  child: Row(
                    children: [
                      Icon(Icons.copy_all),
                      SizedBox(width: 8),
                      Text('Copy All'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'export',
                  child: Row(
                    children: [
                      Icon(Icons.download),
                      SizedBox(width: 8),
                      Text('Export JSON'),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Idea header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withOpacity(0.3),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.idea.title,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.idea.summary,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),

            // Daily limit warning
            if (settings.isDailyLimitReached && !settings.hasApiKey)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                color: Colors.orange.withOpacity(0.1),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.orange.shade700,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Daily Free Limit Reached',
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: Colors.orange.shade800,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            'You have used all 3 free generations today. Add your own API key in settings to continue.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.orange.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            // Content
            Expanded(
              child: _buildContent(generationState),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(GenerationState state) {
    if (state.isGeneratingDetails) {
      return _buildLoadingState();
    }

    final response = state.detailResponse;
    if (response == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return response.when(
      success: (data) => _buildDetailContent(data.detail),
      error: (message, type) => ErrorDisplay(
        message: message,
        onRetry: type == ApiErrorType.dailyLimitExceeded ? null : _regenerateDetails,
      ),
      loading: () => _buildLoadingState(),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 24),
          Text(
            'Generating content details...',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'This may take a few seconds',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _buildDetailContent(ContentDetail detail) {
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Word count badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: theme.colorScheme.secondaryContainer,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.text_snippet,
                size: 16,
                color: theme.colorScheme.onSecondaryContainer,
              ),
              const SizedBox(width: 6),
              Text(
                '${detail.script.wordCount} words',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSecondaryContainer,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Hooks
        ListCollapsibleSection(
          title: 'Hooks',
          items: detail.hooks,
          icon: Icons.flash_on,
          initiallyExpanded: true,
        ),

        // Titles
        ListCollapsibleSection(
          title: 'Alternative Titles',
          items: detail.titles,
          icon: Icons.title,
        ),

        // Script
        CollapsibleSection(
          title: 'Script - Intro',
          content: detail.script.intro,
          icon: Icons.play_circle_outline,
          initiallyExpanded: true,
        ),
        CollapsibleSection(
          title: 'Script - Problem',
          content: detail.script.problem,
          icon: Icons.error_outline,
        ),
        CollapsibleSection(
          title: 'Script - Solution',
          content: detail.script.solution,
          icon: Icons.lightbulb_outline,
        ),
        CollapsibleSection(
          title: 'Script - Example',
          content: detail.script.example,
          icon: Icons.format_quote,
        ),
        CollapsibleSection(
          title: 'Script - Call to Action',
          content: detail.script.cta,
          icon: Icons.call_made,
        ),

        // Full Script
        CollapsibleSection(
          title: 'Full Script',
          content: detail.script.fullScript,
          icon: Icons.article_outlined,
          initiallyExpanded: true,
        ),

        // Description
        CollapsibleSection(
          title: 'Description',
          content: detail.description,
          icon: Icons.description_outlined,
        ),

        // Hashtags
        Card(
          elevation: 1,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.tag,
                      size: 22,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Hashtags',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: detail.hashtags.map((tag) {
                    return ActionChip(
                      label: Text(tag),
                      onPressed: () => CopyHelper.copyToClipboard(tag),
                      avatar: const Icon(Icons.copy, size: 16),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () => CopyHelper.copyToClipboard(
                      detail.hashtags.join(' '),
                    ),
                    icon: const Icon(Icons.copy_all, size: 18),
                    label: const Text('Copy All'),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Regenerate button
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: _regenerateDetails,
          icon: const Icon(Icons.refresh),
          label: const Text('Regenerate'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 48),
          ),
        ),
        const SizedBox(height: 32),
      ],
    ).animate().fadeIn(duration: 400.ms);
  }
}