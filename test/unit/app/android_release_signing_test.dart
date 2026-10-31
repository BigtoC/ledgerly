import 'dart:io' show File;

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Android release signing config', () {
    late String workflowSource;
    late String gradleSource;

    setUpAll(() {
      workflowSource = File('.github/workflows/check.yml').readAsStringSync();
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

    test('signing secrets choose between a release and a debug build', () {
      expect(
        workflowSource,
        contains(
          "if: steps.check-secrets.outputs.available == 'true'\n"
          '        run: flutter build apk --release',
        ),
      );
      expect(
        workflowSource,
        contains(
          "if: steps.check-secrets.outputs.available != 'true'\n"
          '        run: flutter build apk --debug',
        ),
      );
    });

    test('Check builds APKs as a compile check without uploading them', () {
      // Release APKs ship from android-release.yml on version tags.
      expect(workflowSource, isNot(contains('actions/upload-artifact')));
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
