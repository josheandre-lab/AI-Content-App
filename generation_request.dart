import 'package:freezed_annotation/freezed_annotation.dart';
import 'content_idea.dart';
import 'content_detail.dart';

part 'api_response.freezed.dart';

@freezed
class ApiResponse<T> with _$ApiResponse<T> {
  const factory ApiResponse.success(T data) = ApiSuccess<T>;
  const factory ApiResponse.error(String message, {ApiErrorType? type}) = ApiError<T>;
  const factory ApiResponse.loading() = ApiLoading<T>;
}

enum ApiErrorType {
  network,
  timeout,
  invalidKey,
  rateLimited,
  invalidResponse,
  serverError,
  offline,
  dailyLimitExceeded,
  cancelled,
}

@freezed
class IdeasResponse with _$IdeasResponse {
  const factory IdeasResponse({
    required List<ContentIdea> ideas,
  }) = _IdeasResponse;

  factory IdeasResponse.fromJson(Map<String, dynamic> json) {
    final ideasList = (json['ideas'] as List<dynamic>?)
        ?.map((e) => ContentIdea.fromJson(e as Map<String, dynamic>))
        .toList() ??
        [];
    return IdeasResponse(ideas: ideasList);
  }
}

@freezed
class DetailResponse with _$DetailResponse {
  const factory DetailResponse({
    required ContentDetail detail,
  }) = _DetailResponse;

  factory DetailResponse.fromJson(Map<String, dynamic> json) {
    return DetailResponse(
      detail: ContentDetail.fromJson(json),
    );
  }
}