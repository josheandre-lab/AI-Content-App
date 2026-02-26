import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';
import '../services/services.dart';

final generationProvider = StateNotifierProvider<GenerationNotifier, GenerationState>((ref) {
  return GenerationNotifier(ref);
});

class GenerationState {
  final ApiResponse<IdeasResponse>? ideasResponse;
  final ApiResponse<DetailResponse>? detailResponse;
  final bool isGeneratingIdeas;
  final bool isGeneratingDetails;
  final String? currentRequestId;
  final GenerationRequest? lastRequest;
  final ContentIdea? selectedIdea;

  const GenerationState({
    this.ideasResponse,
    this.detailResponse,
    this.isGeneratingIdeas = false,
    this.isGeneratingDetails = false,
    this.currentRequestId,
    this.lastRequest,
    this.selectedIdea,
  });

  GenerationState copyWith({
    ApiResponse<IdeasResponse>? ideasResponse,
    ApiResponse<DetailResponse>? detailResponse,
    bool? isGeneratingIdeas,
    bool? isGeneratingDetails,
    String? currentRequestId,
    GenerationRequest? lastRequest,
    ContentIdea? selectedIdea,
    bool clearIdeasResponse = false,
    bool clearDetailResponse = false,
  }) {
    return GenerationState(
      ideasResponse: clearIdeasResponse ? null : ideasResponse ?? this.ideasResponse,
      detailResponse: clearDetailResponse ? null : detailResponse ?? this.detailResponse,
      isGeneratingIdeas: isGeneratingIdeas ?? this.isGeneratingIdeas,
      isGeneratingDetails: isGeneratingDetails ?? this.isGeneratingDetails,
      currentRequestId: currentRequestId ?? this.currentRequestId,
      lastRequest: lastRequest ?? this.lastRequest,
      selectedIdea: selectedIdea ?? this.selectedIdea,
    );
  }

  bool get isLoading => isGeneratingIdeas || isGeneratingDetails;
}

class GenerationNotifier extends StateNotifier<GenerationState> {
  final Ref _ref;
  final _uuid = const Uuid();
  Timer? _debounceTimer;

  GenerationNotifier(this._ref) : super(const GenerationState());

  Future<void> generateIdeas(GenerationRequest request) async {
    // Debounce
    if (_debounceTimer?.isActive ?? false) return;
    _debounceTimer = Timer(const Duration(milliseconds: 800), () {});

    // Cancel any existing request
    if (state.isLoading) {
      GeminiService.cancelRequest();
    }

    final requestId = _uuid.v4();
    
    state = state.copyWith(
      isGeneratingIdeas: true,
      currentRequestId: requestId,
      lastRequest: request,
      clearIdeasResponse: true,
      clearDetailResponse: true,
    );

    final response = await GeminiService.generateIdeas(
      request,
      requestId: requestId,
    );

    // Check if this response is still relevant
    if (state.currentRequestId != requestId) {
      return;
    }

    state = state.copyWith(
      ideasResponse: response,
      isGeneratingIdeas: false,
    );

    // Save to history if successful
    if (response is ApiSuccess<IdeasResponse>) {
      await _saveToHistory(request, response.data);
    }
  }

  Future<void> generateDetails(ContentIdea idea) async {
    if (state.lastRequest == null) return;

    // Debounce
    if (_debounceTimer?.isActive ?? false) return;
    _debounceTimer = Timer(const Duration(milliseconds: 800), () {});

    // Cancel any existing request
    if (state.isGeneratingDetails) {
      GeminiService.cancelRequest();
    }

    final requestId = _uuid.v4();
    
    state = state.copyWith(
      isGeneratingDetails: true,
      currentRequestId: requestId,
      selectedIdea: idea,
      clearDetailResponse: true,
    );

    final response = await GeminiService.generateDetails(
      state.lastRequest!,
      idea,
      requestId: requestId,
    );

    // Check if this response is still relevant
    if (state.currentRequestId != requestId) {
      return;
    }

    state = state.copyWith(
      detailResponse: response,
      isGeneratingDetails: false,
    );

    // Refresh daily limit in settings
    await _ref.read(settingsProvider.notifier).refreshDailyLimit();

    // Update history if successful
    if (response is ApiSuccess<DetailResponse>) {
      await _updateHistoryWithDetails(idea, response.data);
    }
  }

  Future<void> regenerateDetails() async {
    if (state.selectedIdea != null && state.lastRequest != null) {
      await generateDetails(state.selectedIdea!);
    }
  }

  void cancelRequest() {
    GeminiService.cancelRequest();
    state = state.copyWith(
      isGeneratingIdeas: false,
      isGeneratingDetails: false,
    );
  }

  void clearIdeas() {
    state = state.copyWith(
      clearIdeasResponse: true,
      clearDetailResponse: true,
      selectedIdea: null,
    );
  }

  void clearDetails() {
    state = state.copyWith(
      clearDetailResponse: true,
    );
  }

  Future<void> _saveToHistory(
    GenerationRequest request,
    IdeasResponse ideas,
  ) async {
    try {
      final historyItem = HistoryItem(
        createdAt: DateTime.now(),
        requestJson: jsonEncode(request.toJson()),
        ideasJson: jsonEncode(ideas.toJson()),
      );

      final db = DatabaseService();
      await db.addHistoryItem(historyItem);
    } catch (e) {
      debugPrint('Error saving to history: $e');
    }
  }

  Future<void> _updateHistoryWithDetails(
    ContentIdea idea,
    DetailResponse detail,
  ) async {
    try {
      final db = DatabaseService();
      final items = await db.getHistoryItems(limit: 1);
      
      if (items.isNotEmpty) {
        final latestItem = items.first;
        latestItem.detailJson = jsonEncode(detail.toJson());
        latestItem.selectedTitle = idea.title;
        await db.updateHistoryItem(latestItem);
      }
    } catch (e) {
      debugPrint('Error updating history: $e');
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}