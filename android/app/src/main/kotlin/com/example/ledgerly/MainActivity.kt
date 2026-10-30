package com.example.ledgerly

import android.app.PendingIntent
import android.content.Intent
import android.content.pm.PackageInstaller
import android.net.Uri
import android.os.Build
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "ledgerly/apk_installer")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "canRequestInstalls" -> result.success(
                        Build.VERSION.SDK_INT < Build.VERSION_CODES.O ||
                            packageManager.canRequestPackageInstalls(),
                    )
                    "openInstallSettings" -> {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                            startActivity(
                                Intent(
                                    Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES,
                                    Uri.parse("package:$packageName"),
                                ),
                            )
                        }
                        result.success(null)
                    }
                    "install" -> install(call.argument<String>("path")!!, result)
                    else -> result.notImplemented()
                }
            }
    }

    /** Streams the verified APK into a PackageInstaller session and commits it. */
    private fun install(path: String, result: MethodChannel.Result) {
        val installer = packageManager.packageInstaller
        var sessionId = -1
        try {
            val file = File(path)
            val params = PackageInstaller.SessionParams(
                PackageInstaller.SessionParams.MODE_FULL_INSTALL,
            ).apply {
                setAppPackageName(packageName)
                setSize(file.length())
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                    setRequireUserAction(PackageInstaller.SessionParams.USER_ACTION_NOT_REQUIRED)
                }
            }
            sessionId = installer.createSession(params)
            installer.openSession(sessionId).use { session ->
                file.inputStream().use { input ->
                    session.openWrite("base.apk", 0, file.length()).use { output ->
                        input.copyTo(output)
                        session.fsync(output)
                    }
                }
                // Mutable: the installer fills in EXTRA_STATUS. Explicit
                // intent, as targetSdk 34+ requires for mutable PendingIntents.
                val flags = PendingIntent.FLAG_UPDATE_CURRENT or
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) PendingIntent.FLAG_MUTABLE else 0
                val status = PendingIntent.getBroadcast(
                    this,
                    sessionId,
                    Intent(this, InstallStatusReceiver::class.java),
                    flags,
                )
                InstallStatusReceiver.pending?.success(PackageInstaller.STATUS_FAILURE_ABORTED)
                InstallStatusReceiver.pending = result
                session.commit(status.intentSender)
            }
        } catch (e: Exception) {
            if (sessionId != -1) installer.abandonSession(sessionId)
            if (InstallStatusReceiver.pending === result) InstallStatusReceiver.pending = null
            result.success(
                if (e is java.io.IOException) {
                    PackageInstaller.STATUS_FAILURE_STORAGE
                } else {
                    PackageInstaller.STATUS_FAILURE
                },
            )
        }
    }
}
