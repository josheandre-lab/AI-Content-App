import 'package:freezed_annotation/freezed_annotation.dart';
import 'enums/enums.dart';

part 'generation_request.freezed.dart';
part 'generation_request.g.dart';

@freezed
class GenerationRequest with _$GenerationRequest {
  const factory GenerationRequest({
    required PlatformType platform,
    required String niche,
    required String audience,
    required DurationType duration,
    required ToneType tone,
    required GoalType goal,
    @JsonKey(name: 'topic') required String topic,
  }) = _GenerationRequest;

  factory GenerationRequest.fromJson(Map<String, dynamic> json) =>
      _$GenerationRequestFromJson(json);

  const GenerationRequest._();

  Map<String, dynamic> toPromptContext() {
    return {
      'platform': platform.displayName,
      'niche': niche.trim(),
      'audience': audience.trim(),
      'duration': duration.displayName,
      'wordCountGuideline': duration.wordCountGuideline,
      'tone': tone.displayName,
      'goal': goal.displayName,
      'topic': topic.trim(),
    };
  }
}