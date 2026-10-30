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
        // The copy and fsync stay off the main thread, which is also Flutter's UI thread.
        Thread {
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
                val written = sessionId
                runOnUiThread { commit(installer, written, status, result) }
            } catch (e: Exception) {
                if (sessionId != -1) abandonQuietly(installer, sessionId)
                runOnUiThread { result.success(failureStatus(e)) }
            }
        }.start()
    }

    /**
     * Commits on the main thread, where the receiver also runs, so
     * [InstallStatusReceiver.pending] is set before this session can report.
     */
    private fun commit(
        installer: PackageInstaller,
        sessionId: Int,
        status: PendingIntent,
        result: MethodChannel.Result,
    ) {
        try {
            // A newer tap replaces the install in flight: report it aborted
            // and try to abandon its session. Android ignores that once the
            // user has confirmed; the receiver then drops its late status.
            val replaced = InstallStatusReceiver.pendingSessionId
            InstallStatusReceiver.finish(PackageInstaller.STATUS_FAILURE_ABORTED)
            if (replaced != -1) abandonQuietly(installer, replaced)
            InstallStatusReceiver.pending = result
            InstallStatusReceiver.pendingSessionId = sessionId
            installer.openSession(sessionId).use { it.commit(status.intentSender) }
        } catch (e: Exception) {
            abandonQuietly(installer, sessionId)
            if (InstallStatusReceiver.pending === result) {
                InstallStatusReceiver.pending = null
                InstallStatusReceiver.pendingSessionId = -1
            }
            result.success(failureStatus(e))
        }
    }

    /** A session that already finished or was abandoned throws; nothing is left to clean up. */
    private fun abandonQuietly(installer: PackageInstaller, sessionId: Int) {
        try {
            installer.abandonSession(sessionId)
        } catch (e: Exception) {
        }
    }

    private fun failureStatus(e: Exception) = if (e is java.io.IOException) {
        PackageInstaller.STATUS_FAILURE_STORAGE
    } else {
        PackageInstaller.STATUS_FAILURE
    }
}
