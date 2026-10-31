import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/data/services/package_info_service.dart';
import 'package:package_info_plus/package_info_plus.dart';

void main() {
  test('reads the version and build number from the platform', () async {
    PackageInfo.setMockInitialValues(
      appName: 'Ledgerly',
      packageName: 'com.example.ledgerly',
      version: '1.2.3',
      buildNumber: '45',
      buildSignature: '',
    );

    final info = await const PackageInfoService().read();

    expect(info.version, '1.2.3');
    expect(info.buildNumber, '45');
  });
}
