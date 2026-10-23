// Guards `openInSystemBrowser`: it opens the URL outside the app and
// reports failure as false, including when url_launcher_android throws
// PlatformException instead of returning false.

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:ledgerly/core/utils/system_browser.dart';

final _url = Uri.parse('https://example.com/app.apk');

void main() {
  test('opens the URL in an external application', () async {
    final calls = <(Uri, LaunchMode)>[];

    final opened = await openInSystemBrowser(
      _url,
      launch: (url, {mode = LaunchMode.platformDefault}) async {
        calls.add((url, mode));
        return true;
      },
    );

    expect(opened, isTrue);
    expect(calls, [(_url, LaunchMode.externalApplication)]);
  });

  test('returns false when the launcher returns false', () async {
    final opened = await openInSystemBrowser(
      _url,
      launch: (url, {mode = LaunchMode.platformDefault}) async => false,
    );

    expect(opened, isFalse);
  });

  test('returns false when the launcher throws PlatformException', () async {
    final opened = await openInSystemBrowser(
      _url,
      launch: (url, {mode = LaunchMode.platformDefault}) =>
          Future.error(PlatformException(code: 'ACTIVITY_NOT_FOUND')),
    );

    expect(opened, isFalse);
  });
}
