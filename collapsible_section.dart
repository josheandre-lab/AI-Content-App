import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/models.dart';
import '../providers/providers.dart';
import '../utils/utils.dart';
import '../widgets/widgets.dart';
import 'detail_screen.dart';

class GenerateScreen extends ConsumerStatefulWidget {
  const GenerateScreen({super.key});

  @override
  ConsumerState<GenerateScreen> createState() => _GenerateScreenState();
}

class _GenerateScreenState extends ConsumerState<GenerateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _topicController = TextEditingController();
  final _nicheController = TextEditingController();
  final _audienceController = TextEditingController();

  PlatformType _selectedPlatform = PlatformType.youtube;
  DurationType _selectedDuration = DurationType.s60;
  ToneType _selectedTone = ToneType.casual;
  GoalType _selectedGoal = GoalType.views;

  @override
  void dispose() {
    _topicController.dispose();
    _nicheController.dispose();
    _audienceController.dispose();
    super.dispose();
  }

  Future<void> _generateIdeas() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Check connectivity
    final isOnline = await ConnectivityService.checkConnection();
    if (!isOnline) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No internet connection. Please check your network.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    final request = GenerationRequest(
      platform: _selectedPlatform,
      niche: InputValidator.sanitizeInput(_nicheController.text),
      audience: InputValidator.sanitizeInput(_audienceController.text),
      duration: _selectedDuration,
      tone: _selectedTone,
      goal: _selectedGoal,
      topic: InputValidator.sanitizeInput(_topicController.text),
    );

    await ref.read(generationProvider.notifier).generateIdeas(request);
  }

  void _navigateToDetail(ContentIdea idea) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => DetailScreen(idea: idea),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final generationState = ref.watch(generationProvider);
    final isOnline = ref.watch(isOnlineProvider);

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Create Viral Content',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Fill in the details below to generate AI-powered content ideas.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Platform
                      CustomDropdown<PlatformType>(
                        label: 'Platform',
                        value: _selectedPlatform,
                        items: PlatformType.values,
                        itemLabel: (p) => p.displayName,
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _selectedPlatform = value);
                          }
                        },
                      ),
                      const SizedBox(height: 16),

                      // Niche
                      CustomTextField(
                        label: 'Niche',
                        hint: 'e.g., Fitness, Tech, Cooking, Finance',
                        controller: _nicheController,
                        validator: InputValidator.validateNiche,
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 16),

                      // Audience
                      CustomTextField(
                        label: 'Target Audience',
                        hint: 'e.g., Young professionals, Parents, Gamers',
                        controller: _audienceController,
                        validator: InputValidator.validateAudience,
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 16),

                      // Duration
                      CustomDropdown<DurationType>(
                        label: 'Duration',
                        value: _selectedDuration,
                        items: DurationType.values,
                        itemLabel: (d) => '${d.displayName} (${d.wordCountGuideline})',
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _selectedDuration = value);
                          }
                        },
                      ),
                      const SizedBox(height: 16),

                      // Tone
                      CustomDropdown<ToneType>(
                        label: 'Tone',
                        value: _selectedTone,
                        items: ToneType.values,
                        itemLabel: (t) => t.displayName,
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _selectedTone = value);
                          }
                        },
                      ),
                      const SizedBox(height: 16),

                      // Goal
                      CustomDropdown<GoalType>(
                        label: 'Goal',
                        value: _selectedGoal,
                        items: GoalType.values,
                        itemLabel: (g) => g.displayName,
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _selectedGoal = value);
                          }
                        },
                      ),
                      const SizedBox(height: 16),

                      // Topic
                      CustomTextField(
                        label: 'Topic',
                        hint: 'Describe what your content is about...',
                        controller: _topicController,
                        maxLines: 4,
                        maxLength: InputValidator.maxTopicLength,
                        validator: InputValidator.validateTopic,
                        textInputAction: TextInputAction.done,
                        onSubmitted: _generateIdeas,
                      ),
                      const SizedBox(height: 24),

                      // Generate Button
                      LoadingButton(
                        label: 'Generate Ideas',
                        onPressed: isOnline ? _generateIdeas : null,
                        isLoading: generationState.isGeneratingIdeas,
                        icon: Icons.auto_awesome,
                      ),
                      const SizedBox(height: 8),

                      // Offline warning
                      if (!isOnline)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.wifi_off,
                                color: Colors.orange.shade700,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'You are offline. Please connect to the internet to generate content.',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: Colors.orange.shade700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),

            // Results
            if (generationState.ideasResponse != null)
              _buildResultsSection(generationState),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsSection(GenerationState state) {
    final response = state.ideasResponse!;

    return response.when(
      success: (data) => SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Divider(),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Generated Ideas',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      ref.read(generationProvider.notifier).clearIdeas();
                    },
                    icon: const Icon(Icons.clear, size: 18),
                    label: const Text('Clear'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ...data.ideas.asMap().entries.map((entry) {
                return IdeaCard(
                  idea: entry.value,
                  index: entry.key,
                  onGenerateDetails: () => _navigateToDetail(entry.value),
                  isLoading: state.isGeneratingDetails && 
                             state.selectedIdea?.title == entry.value.title,
                );
              }),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
      error: (message, type) => SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: ErrorDisplay(
            message: message,
            onRetry: _generateIdeas,
          ),
        ),
      ),
      loading: () => const SliverToBoxAdapter(
        child: SizedBox.shrink(),
      ),
    );
  }
}