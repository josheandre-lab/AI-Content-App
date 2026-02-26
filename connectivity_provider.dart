import 'package:freezed_annotation/freezed_annotation.dart';

part 'content_idea.freezed.dart';
part 'content_idea.g.dart';

@freezed
class ContentIdea with _$ContentIdea {
  const factory ContentIdea({
    required String title,
    required String summary,
  }) = _ContentIdea;

  factory ContentIdea.fromJson(Map<String, dynamic> json) =>
      _$ContentIdeaFromJson(json);
}