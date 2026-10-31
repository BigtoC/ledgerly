import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

typedef LaunchUrlFn = Future<bool> Function(Uri url, {LaunchMode mode});

/// url_launcher's [launchUrl], for callers whose test seam defaults to it
/// without importing url_launcher themselves.
const LaunchUrlFn defaultLaunch = launchUrl;

/// Opens [url] in the system browser, not the in-app WebView. Returns false
/// when nothing can open it: url_launcher_android throws PlatformException
/// there instead of returning false.
Future<bool> openInSystemBrowser(
  Uri url, {
  LaunchUrlFn launch = defaultLaunch,
}) async {
  try {
    return await launch(url, mode: LaunchMode.externalApplication);
  } on PlatformException {
    return false;
  }
}
