import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

typedef LaunchUrlFn = Future<bool> Function(Uri url, {LaunchMode mode});

/// Opens [url] in the system browser, not the in-app WebView. Returns false
/// when nothing can open it: url_launcher_android throws PlatformException
/// there instead of returning false.
Future<bool> openInSystemBrowser(
  Uri url, {
  LaunchUrlFn launch = launchUrl,
}) async {
  try {
    return await launch(url, mode: LaunchMode.externalApplication);
  } on PlatformException {
    return false;
  }
}
