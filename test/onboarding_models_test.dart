import 'package:flutter_test/flutter_test.dart';
import 'package:lolango_v2/features/onboarding/domain/onboarding_models.dart';

void main() {
  group('OnboardingProfile', () {
    test('normalizedUsername strips @ and trims whitespace', () {
      const profile = OnboardingProfile(username: ' @alice ');
      expect(profile.normalizedUsername, 'alice');
    });

    test('usernameIsValid only when username is valid and available', () {
      const profile = OnboardingProfile(
        username: '@alice',
        usernameAvailable: true,
      );

      expect(profile.usernameIsValid, isTrue);
    });

    test('usernameIsValid is false when it is already taken', () {
      const profile = OnboardingProfile(
        username: '@alice',
        usernameAvailable: false,
      );

      expect(profile.usernameIsValid, isFalse);
    });
  });
}
