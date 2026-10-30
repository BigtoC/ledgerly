// Guards the Dart side of the `ledgerly/apk_installer` channel: method
// names, arguments and result decoding must match MainActivity.kt.

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/data/services/apk_installer_service.dart';

const _channel = MethodChannel('ledgerly/apk_installer');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final calls = <MethodCall>[];

  void handle(Object? Function(MethodCall call) reply) {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, (call) async {
          calls.add(call);
          return reply(call);
        });
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(_channel, null),
    );
  }

  setUp(calls.clear);

  test('canRequestInstalls returns the platform bool', () async {
    handle((_) => true);
    expect(await const ApkInstallerService().canRequestInstalls(), isTrue);
    expect(calls.single.method, 'canRequestInstalls');
  });

  test('openInstallSettings invokes the platform method', () async {
    handle((_) => null);
    await const ApkInstallerService().openInstallSettings();
    expect(calls.single.method, 'openInstallSettings');
  });

  test('install sends the path and returns the session status', () async {
    handle((_) => 3);
    expect(await const ApkInstallerService().install('/c/u/a.apk'), 3);
    expect(calls.single.method, 'install');
    expect(calls.single.arguments, {'path': '/c/u/a.apk'});
  });

  test('a null install result counts as STATUS_FAILURE (1)', () async {
    handle((_) => null);
    expect(await const ApkInstallerService().install('/a.apk'), 1);
  });
}
