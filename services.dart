import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../services/services.dart';

final historyProvider = StateNotifierProvider<HistoryNotifier, HistoryState>((ref) {
  return HistoryNotifier();
});

class HistoryState {
  final List<HistoryItemDisplay> items;
  final bool isLoading;
  final String? error;

  const HistoryState({
    this.items = const [],
    this.isLoading = false,
    this.error,
  });

  HistoryState copyWith({
    List<HistoryItemDisplay>? items,
    bool? isLoading,
    String? error,
  }) {
    return HistoryState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class HistoryItemDisplay {
  final int id;
  final DateTime createdAt;
  final GenerationRequest request;
  final List<ContentIdea>? ideas;
  final ContentDetail? detail;
  final String? selectedTitle;
  final bool isFavorite;

  const HistoryItemDisplay({
    required this.id,
    required this.createdAt,
    required this.request,
    this.ideas,
    this.detail,
    this.selectedTitle,
    this.isFavorite = false,
  });

  String get displayTitle {
    return selectedTitle ?? 
           ideas?.firstOrNull?.title ?? 
           request.topic.substring(0, request.topic.length.clamp(0, 50));
  }
}

class HistoryNotifier extends StateNotifier<HistoryState> {
  HistoryNotifier() : super(const HistoryState()) {
    loadHistory();
  }

  Future<void> loadHistory() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final db = DatabaseService();
      final items = await db.getHistoryItems();
      
      final displayItems = items.map(_parseHistoryItem).whereType<HistoryItemDisplay>().toList();
      
      state = state.copyWith(
        items: displayItems,
        isLoading: false,
      );
    } catch (e) {
      debugPrint('Error loading history: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load history',
      );
    }
  }

  Future<void> deleteItem(int id) async {
    try {
      final db = DatabaseService();
      await db.deleteHistoryItem(id);
      
      state = state.copyWith(
        items: state.items.where((item) => item.id != id).toList(),
      );
    } catch (e) {
      debugPrint('Error deleting history item: $e');
    }
  }

  Future<void> clearAllHistory() async {
    try {
      final db = DatabaseService();
      await db.clearAllHistory();
      
      state = state.copyWith(items: []);
    } catch (e) {
      debugPrint('Error clearing history: $e');
    }
  }

  Future<void> toggleFavorite(int id) async {
    try {
      final db = DatabaseService();
      await db.toggleFavorite(id);
      
      // Update local state
      final updatedItems = state.items.map((item) {
        if (item.id == id) {
          return HistoryItemDisplay(
            id: item.id,
            createdAt: item.createdAt,
            request: item.request,
            ideas: item.ideas,
            detail: item.detail,
            selectedTitle: item.selectedTitle,
            isFavorite: !item.isFavorite,
          );
        }
        return item;
      }).toList();
      
      state = state.copyWith(items: updatedItems);
    } catch (e) {
      debugPrint('Error toggling favorite: $e');
    }
  }

  HistoryItemDisplay? _parseHistoryItem(HistoryItem item) {
    try {
      final requestJson = jsonDecode(item.requestJson) as Map<String, dynamic>;
      final request = GenerationRequest.fromJson(requestJson);

      List<ContentIdea>? ideas;
      if (item.ideasJson != null) {
        final ideasData = jsonDecode(item.ideasJson!) as Map<String, dynamic>;
        ideas = IdeasResponse.fromJson(ideasData).ideas;
      }

      ContentDetail? detail;
      if (item.detailJson != null) {
        final detailData = jsonDecode(item.detailJson!) as Map<String, dynamic>;
        detail = DetailResponse.fromJson(detailData).detail;
      }

      return HistoryItemDisplay(
        id: item.id,
        createdAt: item.createdAt,
        request: request,
        ideas: ideas,
        detail: detail,
        selectedTitle: item.selectedTitle,
        isFavorite: item.isFavorite,
      );
    } catch (e) {
      debugPrint('Error parsing history item: $e');
      return null;
    }
  }
}