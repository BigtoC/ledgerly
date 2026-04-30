import 'dart:io' show File;

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Android release signing config', () {
    late String workflowSource;
    late String gradleSource;

    setUpAll(() {
      workflowSource = File('.github/workflows/ci.yml').readAsStringSync();
      gradleSource = File('android/app/build.gradle.kts').readAsStringSync();
    });

    test('signed release path requires the full secret set', () {
      expect(workflowSource, contains('KEYSTORE_BASE64'));
      expect(workflowSource, contains('KEY_ALIAS'));
      expect(workflowSource, contains('KEY_PASSWORD'));
      expect(workflowSource, contains('STORE_PASSWORD'));
      expect(workflowSource, contains(r'[ -n "$KEYSTORE_BASE64" ]'));
      expect(workflowSource, contains(r'[ -n "$KEY_ALIAS" ]'));
      expect(workflowSource, contains(r'[ -n "$KEY_PASSWORD" ]'));
      expect(workflowSource, contains(r'[ -n "$STORE_PASSWORD" ]'));
    });

    test('release and debug artifacts are published under different paths', () {
      expect(workflowSource, contains('flutter build apk --release'));
      expect(workflowSource, contains('flutter build apk --debug'));
      expect(workflowSource, contains('ledgerly-release-apk'));
      expect(workflowSource, contains('app-release.apk'));
      expect(workflowSource, contains('ledgerly-debug-apk'));
      expect(workflowSource, contains('app-debug.apk'));
    });

    test('key.properties path matches the decoded keystore location', () {
      expect(workflowSource, contains('android/app/ledgerly-release.jks'));
      expect(workflowSource, contains('storeFile=ledgerly-release.jks'));
      expect(
        workflowSource,
        isNot(contains('storeFile=app/ledgerly-release.jks')),
      );
    });

    test('release signing enforcement is scoped to release tasks only', () {
      expect(gradleSource, contains('GradleException'));
      expect(gradleSource, contains('Release builds require'));
      expect(gradleSource, contains('taskNames.any'));
      expect(gradleSource, contains('contains("release")'));
      expect(
        gradleSource,
        isNot(contains('signingConfigs.getByName("debug")')),
      );
    });
  });
}
