import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../models/models.dart';
import 'secure_storage_service.dart';

class GeminiService {
  static final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 30),
    sendTimeout: const Duration(seconds: 30),
  ));

  static const String _baseUrl = 'https://generativelanguage.googleapis.com/v1beta/models';
  static const String _model = 'gemini-1.5-flash';
  
  // Mock mode flag
  static bool _mockMode = false;
  static bool get isMockMode => _mockMode;

  // Request tracking for cancellation
  static CancelToken? _currentCancelToken;
  static String? _currentRequestId;

  // Initialize and check API key
  static Future<void> initialize() async {
    final apiKey = await SecureStorageService.getApiKey();
    _mockMode = apiKey == null || apiKey.isEmpty;
  }

  // Generate content ideas
  static Future<ApiResponse<IdeasResponse>> generateIdeas(
    GenerationRequest request, {
    String? requestId,
  }) async {
    _currentRequestId = requestId;
    
    if (_mockMode) {
      await Future.delayed(const Duration(seconds: 1));
      return ApiResponse.success(_getMockIdeasResponse());
    }

    _currentCancelToken = CancelToken();

    try {
      final apiKey = await SecureStorageService.getApiKey();
      if (apiKey == null || apiKey.isEmpty) {
        _mockMode = true;
        return ApiResponse.success(_getMockIdeasResponse());
      }

      final prompt = _buildIdeasPrompt(request);
      final response = await _makeApiCall(prompt, apiKey);

      if (_currentCancelToken?.isCancelled ?? false) {
        return const ApiResponse.error('Request cancelled', type: ApiErrorType.cancelled);
      }

      final parsedData = _parseIdeasResponse(response);
      return ApiResponse.success(parsedData);
    } on DioException catch (e) {
      return _handleDioError(e);
    } catch (e) {
      return ApiResponse.error('Unexpected error: $e');
    } finally {
      _currentCancelToken = null;
    }
  }

  // Generate content details
  static Future<ApiResponse<DetailResponse>> generateDetails(
    GenerationRequest request,
    ContentIdea idea, {
    String? requestId,
  }) async {
    _currentRequestId = requestId;

    // Check daily limit
    final limitStatus = await SecureStorageService.checkDailyLimit();
    if (limitStatus.isLimitReached) {
      return const ApiResponse.error(
        'Daily free limit reached. Please add your own API key in settings.',
        type: ApiErrorType.dailyLimitExceeded,
      );
    }

    if (_mockMode) {
      await Future.delayed(const Duration(seconds: 1));
      await SecureStorageService.incrementDailyUsage();
      return ApiResponse.success(_getMockDetailResponse(request.duration));
    }

    _currentCancelToken = CancelToken();

    try {
      final apiKey = await SecureStorageService.getApiKey();
      if (apiKey == null || apiKey.isEmpty) {
        _mockMode = true;
        await SecureStorageService.incrementDailyUsage();
        return ApiResponse.success(_getMockDetailResponse(request.duration));
      }

      final prompt = _buildDetailPrompt(request, idea);
      final response = await _makeApiCall(prompt, apiKey);

      if (_currentCancelToken?.isCancelled ?? false) {
        return const ApiResponse.error('Request cancelled', type: ApiErrorType.cancelled);
      }

      final parsedData = _parseDetailResponse(response);
      
      // Increment usage only on success
      await SecureStorageService.incrementDailyUsage();
      
      return ApiResponse.success(parsedData);
    } on DioException catch (e) {
      return _handleDioError(e);
    } catch (e) {
      return ApiResponse.error('Unexpected error: $e');
    } finally {
      _currentCancelToken = null;
    }
  }

  // Cancel current request
  static void cancelRequest() {
    _currentCancelToken?.cancel('User cancelled');
    _currentCancelToken = null;
  }

  // Test API key
  static Future<ApiResponse<bool>> testApiKey(String apiKey) async {
    try {
      final testPrompt = 'Return a simple JSON: {"status": "ok"}';
      await _makeApiCall(testPrompt, apiKey);
      return const ApiResponse.success(true);
    } on DioException catch (e) {
      return _handleDioError(e);
    } catch (e) {
      return ApiResponse.error('Invalid API key or service unavailable');
    }
  }

  // API Call
  static Future<String> _makeApiCall(String prompt, String apiKey) async {
    final url = '$_baseUrl/$_model:generateContent?key=$apiKey';

    final response = await _dio.post(
      url,
      data: {
        'contents': [
          {
            'parts': [
              {'text': prompt}
            ]
          }
        ],
        'generationConfig': {
          'temperature': 0.7,
          'maxOutputTokens': 4096,
        },
      },
      cancelToken: _currentCancelToken,
    );

    if (response.statusCode == 200) {
      final candidates = response.data['candidates'] as List<dynamic>?;
      if (candidates != null && candidates.isNotEmpty) {
        final content = candidates[0]['content'];
        final parts = content['parts'] as List<dynamic>?;
        if (parts != null && parts.isNotEmpty) {
          return parts[0]['text'] as String;
        }
      }
      throw Exception('Empty response from API');
    } else {
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        type: DioExceptionType.badResponse,
      );
    }
  }

  // Error Handler
  static ApiResponse<T> _handleDioError<T>(DioException e) {
    if (e.type == DioExceptionType.cancelled) {
      return const ApiResponse.error('Request cancelled', type: ApiErrorType.cancelled);
    }

    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout) {
      return const ApiResponse.error(
        'Request timed out. Please try again.',
        type: ApiErrorType.timeout,
      );
    }

    if (e.type == DioExceptionType.connectionError) {
      return const ApiResponse.error(
        'No internet connection. Please check your network.',
        type: ApiErrorType.offline,
      );
    }

    final statusCode = e.response?.statusCode;
    if (statusCode != null) {
      switch (statusCode) {
        case 401:
        case 403:
          return const ApiResponse.error(
            'Invalid API key. Please check your API key in settings.',
            type: ApiErrorType.invalidKey,
          );
        case 429:
          return const ApiResponse.error(
            'Rate limit exceeded. Please wait a moment and try again.',
            type: ApiErrorType.rateLimited,
          );
        case 500:
        case 502:
        case 503:
        case 504:
          return const ApiResponse.error(
            'Server error. Please try again later.',
            type: ApiErrorType.serverError,
          );
      }
    }

    return ApiResponse.error(
      'Network error: ${e.message}',
      type: ApiErrorType.network,
    );
  }

  // Prompt Builders
  static String _buildIdeasPrompt(GenerationRequest request) {
    final context = request.toPromptContext();
    return '''
You are an expert content strategist. Generate 10 viral content ideas based on the following parameters:

Platform: ${context['platform']}
Niche: ${context['niche']}
Target Audience: ${context['audience']}
Duration: ${context['duration']}
Tone: ${context['tone']}
Goal: ${context['goal']}
Topic: ${context['topic']}

Return ONLY a valid JSON object with this exact structure (no markdown, no backticks, no explanations):
{
  "ideas": [
    {"title": "Catchy title here", "summary": "Brief summary of the content idea"},
    ... (10 items total)
  ]
}

Each title should be attention-grabbing and the summary should explain the key points in 1-2 sentences.'''.trim();
  }

  static String _buildDetailPrompt(GenerationRequest request, ContentIdea idea) {
    final context = request.toPromptContext();
    return '''
You are an expert content creator. Create detailed content for this idea:

Title: ${idea.title}
Summary: ${idea.summary}

Platform: ${context['platform']}
Niche: ${context['niche']}
Target Audience: ${context['audience']}
Duration: ${context['duration']} (Target word count: ${context['wordCountGuideline']})
Tone: ${context['tone']}
Goal: ${context['goal']}

Return ONLY a valid JSON object with this exact structure (no markdown, no backticks, no explanations):
{
  "hooks": ["Hook 1", "Hook 2", "Hook 3"],
  "titles": ["Alternative Title 1", "Alternative Title 2", "Alternative Title 3", "Alternative Title 4", "Alternative Title 5"],
  "script": {
    "intro": "Engaging opening (target: 20% of words)",
    "problem": "Describe the problem or pain point (target: 20% of words)",
    "solution": "Present the solution (target: 30% of words)",
    "example": "Give a concrete example or case study (target: 20% of words)",
    "cta": "Strong call to action (target: 10% of words)"
  },
  "description": "SEO-optimized video description with timestamps and links",
  "hashtags": ["#hashtag1", "#hashtag2", "#hashtag3", "#hashtag4", "#hashtag5", "#hashtag6", "#hashtag7", "#hashtag8", "#hashtag9", "#hashtag10"]
}

The script total word count should be ${context['wordCountGuideline']}. Make the content engaging, valuable, and optimized for the platform.'''.trim();
  }

  // Response Parsers
  static IdeasResponse _parseIdeasResponse(String rawResponse) {
    try {
      final jsonStr = _extractJson(rawResponse);
      final json = jsonDecode(jsonStr) as Map<String, dynamic>;
      return IdeasResponse.fromJson(json);
    } catch (e) {
      // Try to fix JSON and retry
      final fixedJson = _attemptJsonFix(rawResponse);
      if (fixedJson != null) {
        try {
          return IdeasResponse.fromJson(fixedJson);
        } catch (_) {
          // Fall through to error
        }
      }
      throw Exception('Failed to parse ideas response: $e');
    }
  }

  static DetailResponse _parseDetailResponse(String rawResponse) {
    try {
      final jsonStr = _extractJson(rawResponse);
      final json = jsonDecode(jsonStr) as Map<String, dynamic>;
      return DetailResponse.fromJson(json);
    } catch (e) {
      // Try to fix JSON and retry
      final fixedJson = _attemptJsonFix(rawResponse);
      if (fixedJson != null) {
        try {
          return DetailResponse.fromJson(fixedJson);
        } catch (_) {
          // Fall through to error
        }
      }
      throw Exception('Failed to parse detail response: $e');
    }
  }

  static String _extractJson(String text) {
    // Remove markdown code blocks
    var cleaned = text.trim();
    
    // Remove ```json and ```
    if (cleaned.startsWith('```json')) {
      cleaned = cleaned.substring(7);
    } else if (cleaned.startsWith('```')) {
      cleaned = cleaned.substring(3);
    }
    
    if (cleaned.endsWith('```')) {
      cleaned = cleaned.substring(0, cleaned.length - 3);
    }
    
    cleaned = cleaned.trim();
    
    // Find the first { and last }
    final startIndex = cleaned.indexOf('{');
    final endIndex = cleaned.lastIndexOf('}');
    
    if (startIndex == -1 || endIndex == -1 || startIndex >= endIndex) {
      throw Exception('No valid JSON object found');
    }
    
    return cleaned.substring(startIndex, endIndex + 1);
  }

  static Map<String, dynamic>? _attemptJsonFix(String text) {
    try {
      // Try to extract and fix common JSON issues
      var cleaned = text.trim();
      
      // Remove markdown
      cleaned = cleaned.replaceAll(RegExp(r'```json\s*'), '');
      cleaned = cleaned.replaceAll(RegExp(r'```\s*'), '');
      
      // Find JSON object
      final startIndex = cleaned.indexOf('{');
      final endIndex = cleaned.lastIndexOf('}');
      
      if (startIndex != -1 && endIndex != -1 && startIndex < endIndex) {
        var jsonStr = cleaned.substring(startIndex, endIndex + 1);
        
        // Fix trailing commas
        jsonStr = jsonStr.replaceAll(RegExp(r',(\s*[}\]])'), r'\1');
        
        // Fix single quotes to double quotes
        jsonStr = jsonStr.replaceAll("'", '"');
        
        return jsonDecode(jsonStr) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('JSON fix attempt failed: $e');
    }
    return null;
  }

  // Mock Responses
  static IdeasResponse _getMockIdeasResponse() {
    return IdeasResponse(
      ideas: List.generate(
        10,
        (index) => ContentIdea(
          title: 'Mock Content Idea #${index + 1}: How to Go Viral in 2024',
          summary: 'This is a mock idea showing how the UI works. Add your API key in settings for real AI-generated content.',
        ),
      ),
    );
  }

  static DetailResponse _getMockDetailResponse(DurationType duration) {
    final wordCounts = {
      DurationType.s15: 75,
      DurationType.s30: 140,
      DurationType.s60: 270,
      DurationType.m3: 600,
      DurationType.m8: 1400,
    };
    
    final targetWords = wordCounts[duration] ?? 270;

    return DetailResponse(
      detail: ContentDetail(
        hooks: [
          'Stop scrolling! This changes everything...',
          'I wish I knew this sooner!',
          'The secret they don\'t want you to know...',
        ],
        titles: [
          'How to Go Viral: The Ultimate Guide',
          '10 Secrets to Viral Content',
          'This Strategy Got Me 1M Views',
          'The Viral Formula Revealed',
          'Stop Making These Viral Mistakes',
        ],
        script: ContentScript(
          intro: 'Hey everyone! Welcome back to the channel. Today I\'m sharing the exact strategy that helped me reach millions of people.',
          problem: 'Most creators struggle to get views because they\'re making the same mistakes everyone else makes.',
          solution: 'The key is understanding your audience and creating content that resonates with them on a personal level.',
          example: 'For example, when I started using this hook technique, my engagement rate tripled overnight.',
          cta: 'If you found this helpful, hit that like button and subscribe for more tips!',
        ),
        description: '''
In this video, I share my proven strategy for creating viral content.

Timestamps:
0:00 - Introduction
0:30 - The Problem
1:00 - The Solution
2:00 - Real Example
3:00 - Call to Action

Follow me for more tips!
        '''.trim(),
        hashtags: [
          '#viral',
          '#contentcreator',
          '#socialmedia',
          '#growth',
          '#tips',
          '#tutorial',
          '#marketing',
          '#strategy',
          '#success',
          '#trending',
        ],
      ),
    );
  }
}