import 'package:flutter_test/flutter_test.dart';
import 'package:ai_content_assistant/utils/utils.dart';

void main() {
  group('InputValidator', () {
    group('validateTopic', () {
      test('returns error for null value', () {
        expect(InputValidator.validateTopic(null), 'Topic is required');
      });

      test('returns error for empty value', () {
        expect(InputValidator.validateTopic(''), 'Topic is required');
      });

      test('returns error for whitespace only', () {
        expect(InputValidator.validateTopic('   '), 'Topic is required');
      });

      test('returns null for valid topic', () {
        expect(InputValidator.validateTopic('Valid topic'), isNull);
      });

      test('returns error for topic exceeding max length', () {
        final longTopic = 'a' * 501;
        expect(
          InputValidator.validateTopic(longTopic),
          'Topic must be less than ${InputValidator.maxTopicLength} characters',
        );
      });

      test('returns null for topic at max length', () {
        final maxTopic = 'a' * 500;
        expect(InputValidator.validateTopic(maxTopic), isNull);
      });
    });

    group('validateNiche', () {
      test('returns error for null value', () {
        expect(InputValidator.validateNiche(null), 'Niche is required');
      });

      test('returns error for empty value', () {
        expect(InputValidator.validateNiche(''), 'Niche is required');
      });

      test('returns null for valid niche', () {
        expect(InputValidator.validateNiche('Fitness'), isNull);
      });

      test('returns error for niche exceeding max length', () {
        final longNiche = 'a' * 101;
        expect(
          InputValidator.validateNiche(longNiche),
          'Niche must be less than ${InputValidator.maxNicheLength} characters',
        );
      });
    });

    group('validateAudience', () {
      test('returns error for null value', () {
        expect(InputValidator.validateAudience(null), 'Audience is required');
      });

      test('returns error for empty value', () {
        expect(InputValidator.validateAudience(''), 'Audience is required');
      });

      test('returns null for valid audience', () {
        expect(InputValidator.validateAudience('Young professionals'), isNull);
      });
    });

    group('sanitizeInput', () {
      test('trims whitespace', () {
        expect(InputValidator.sanitizeInput('  hello  '), 'hello');
      });

      test('removes HTML tags', () {
        expect(InputValidator.sanitizeInput('<script>alert("xss")</script>'), 
            'scriptalert("xss")/script');
      });

      test('removes control characters', () {
        expect(InputValidator.sanitizeInput('hello\x00world'), 'helloworld');
      });
    });

    group('truncate', () {
      test('returns original string if within limit', () {
        expect(InputValidator.truncate('hello', 10), 'hello');
      });

      test('truncates string exceeding limit', () {
        expect(InputValidator.truncate('hello world', 8), 'hello...');
      });

      test('handles empty string', () {
        expect(InputValidator.truncate('', 10), '');
      });
    });
  });
}