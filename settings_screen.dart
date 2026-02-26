import 'package:isar/isar.dart';
import 'content_idea.dart';
import 'content_detail.dart';
import 'generation_request.dart';

part 'history_item.g.dart';

@Collection()
class HistoryItem {
  Id id = Isar.autoIncrement;

  @Index()
  late DateTime createdAt;

  late String requestJson;
  late String? ideasJson;
  late String? detailJson;
  late String? selectedTitle;
  
  @Index()
  late bool isFavorite;

  HistoryItem({
    required this.createdAt,
    required this.requestJson,
    this.ideasJson,
    this.detailJson,
    this.selectedTitle,
    this.isFavorite = false,
  });
}