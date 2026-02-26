import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';
import '../models/history_item.dart';

class DatabaseService {
  static Isar? _isar;
  static final DatabaseService _instance = DatabaseService._internal();

  factory DatabaseService() => _instance;

  DatabaseService._internal();

  Future<void> initialize() async {
    if (_isar != null && _isar!.isOpen) return;

    try {
      final dir = await getApplicationDocumentsDirectory();
      
      _isar = await Isar.open(
        [HistoryItemSchema],
        directory: dir.path,
        maxSizeMiB: 512,
      );
      
      debugPrint('Database initialized successfully');
    } catch (e) {
      debugPrint('Error initializing database: $e');
      rethrow;
    }
  }

  Isar get isar {
    if (_isar == null || !_isar!.isOpen) {
      throw StateError('Database not initialized. Call initialize() first.');
    }
    return _isar!;
  }

  // History Operations
  Future<HistoryItem> addHistoryItem(HistoryItem item) async {
    try {
      await isar.writeTxn(() async {
        await isar.historyItems.put(item);
      });
      
      // Trim to 200 items
      await _trimHistory();
      
      return item;
    } catch (e) {
      debugPrint('Error adding history item: $e');
      rethrow;
    }
  }

  Future<List<HistoryItem>> getHistoryItems({int limit = 200}) async {
    try {
      return await isar.historyItems
          .where()
          .sortByCreatedAtDesc()
          .limit(limit)
          .findAll();
    } catch (e) {
      debugPrint('Error getting history items: $e');
      return [];
    }
  }

  Future<HistoryItem?> getHistoryItemById(int id) async {
    try {
      return await isar.historyItems.get(id);
    } catch (e) {
      debugPrint('Error getting history item: $e');
      return null;
    }
  }

  Future<void> updateHistoryItem(HistoryItem item) async {
    try {
      await isar.writeTxn(() async {
        await isar.historyItems.put(item);
      });
    } catch (e) {
      debugPrint('Error updating history item: $e');
      rethrow;
    }
  }

  Future<void> deleteHistoryItem(int id) async {
    try {
      await isar.writeTxn(() async {
        await isar.historyItems.delete(id);
      });
    } catch (e) {
      debugPrint('Error deleting history item: $e');
      rethrow;
    }
  }

  Future<void> clearAllHistory() async {
    try {
      await isar.writeTxn(() async {
        await isar.historyItems.clear();
      });
    } catch (e) {
      debugPrint('Error clearing history: $e');
      rethrow;
    }
  }

  Future<void> toggleFavorite(int id) async {
    try {
      final item = await isar.historyItems.get(id);
      if (item != null) {
        item.isFavorite = !item.isFavorite;
        await isar.writeTxn(() async {
          await isar.historyItems.put(item);
        });
      }
    } catch (e) {
      debugPrint('Error toggling favorite: $e');
      rethrow;
    }
  }

  Future<List<HistoryItem>> getFavorites() async {
    try {
      return await isar.historyItems
          .where()
          .isFavoriteEqualTo(true)
          .sortByCreatedAtDesc()
          .findAll();
    } catch (e) {
      debugPrint('Error getting favorites: $e');
      return [];
    }
  }

  Future<int> getHistoryCount() async {
    try {
      return await isar.historyItems.count();
    } catch (e) {
      debugPrint('Error getting history count: $e');
      return 0;
    }
  }

  Future<void> _trimHistory() async {
    try {
      final count = await isar.historyItems.count();
      if (count > 200) {
        final itemsToDelete = await isar.historyItems
            .where()
            .sortByCreatedAt()
            .limit(count - 200)
            .findAll();
        
        await isar.writeTxn(() async {
          for (final item in itemsToDelete) {
            await isar.historyItems.delete(item.id);
          }
        });
      }
    } catch (e) {
      debugPrint('Error trimming history: $e');
    }
  }

  Future<void> close() async {
    if (_isar != null && _isar!.isOpen) {
      await _isar!.close();
    }
  }
}