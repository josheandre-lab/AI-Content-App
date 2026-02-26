import 'package:freezed_annotation/freezed_annotation.dart';

part 'content_detail.freezed.dart';
part 'content_detail.g.dart';

@freezed
class ContentDetail with _$ContentDetail {
  const factory ContentDetail({
    required List<String> hooks,
    required List<String> titles,
    required ContentScript script,
    required String description,
    required List<String> hashtags,
  }) = _ContentDetail;

  factory ContentDetail.fromJson(Map<String, dynamic> json) =>
      _$ContentDetailFromJson(json);
}

@freezed
class ContentScript with _$ContentScript {
  const factory ContentScript({
    required String intro,
    required String problem,
    required String solution,
    required String example,
    required String cta,
  }) = _ContentScript;

  factory ContentScript.fromJson(Map<String, dynamic> json) =>
      _$ContentScriptFromJson(json);

  const ContentScript._();

  String get fullScript => '$intro\n\n$problem\n\n$solution\n\n$example\n\n$cta';

  int get wordCount {
    final allText = fullScript;
    return allText.trim().split(RegExp(r'\s+')).where((s) => s.isNotEmpty).length;
  }
}