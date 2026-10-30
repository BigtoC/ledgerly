package com.example.ledgerly

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.pm.PackageInstaller
import android.os.Build
import io.flutter.plugin.common.MethodChannel

/** Receives PackageInstaller session status for the in-app update. */
class InstallStatusReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        // A session a newer tap replaced still reports (abandoning it sends
        // STATUS_FAILURE_ABORTED); that status is not the install in flight.
        if (intent.getIntExtra(PackageInstaller.EXTRA_SESSION_ID, -1) != pendingSessionId) return
        val status = intent.getIntExtra(
            PackageInstaller.EXTRA_STATUS,
            PackageInstaller.STATUS_FAILURE,
        )
        if (status == PackageInstaller.STATUS_PENDING_USER_ACTION) {
            // The typed overload is buggy on API 33; AndroidX IntentCompat also waits for 34.
            val confirm = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
                intent.getParcelableExtra(Intent.EXTRA_INTENT, Intent::class.java)
            } else {
                @Suppress("DEPRECATION")
                intent.getParcelableExtra(Intent.EXTRA_INTENT)
            }
            if (confirm != null) {
                // The system confirm dialog; the final status arrives later.
                context.startActivity(confirm.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
                return
            }
            finish(PackageInstaller.STATUS_FAILURE)
            return
        }
        finish(status)
    }

    companion object {
        /** Channel result of the install in flight; completed once. */
        var pending: MethodChannel.Result? = null

        /** PackageInstaller session [pending] waits on, or -1. */
        var pendingSessionId = -1

        fun finish(status: Int) {
            pending?.success(status)
            pending = null
            pendingSessionId = -1
        }
    }
}
