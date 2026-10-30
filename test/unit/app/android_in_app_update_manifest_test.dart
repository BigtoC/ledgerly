// Guards the Android pieces the in-app update needs: the install
// permissions and a non-exported receiver for PackageInstaller status.

import 'dart:io' show File;

import 'package:flutter_test/flutter_test.dart';

void main() {
  late String manifest;
  late String activity;

  setUpAll(() {
    manifest = File('android/app/src/main/AndroidManifest.xml')
        .readAsStringSync();
    activity = File(
      'android/app/src/main/kotlin/com/example/ledgerly/MainActivity.kt',
    ).readAsStringSync();
  });

  test('declares the install permissions', () {
    expect(manifest, contains('android.permission.REQUEST_INSTALL_PACKAGES'));
    expect(
      manifest,
      contains('android.permission.UPDATE_PACKAGES_WITHOUT_USER_ACTION'),
    );
  });

  test('status receiver is declared and not exported', () {
    expect(
      manifest,
      contains(
        '<receiver android:name=".InstallStatusReceiver" android:exported="false"',
      ),
    );
  });

  test('MainActivity registers the channel the Dart service uses', () {
    expect(activity, contains('"ledgerly/apk_installer"'));
  });
}
