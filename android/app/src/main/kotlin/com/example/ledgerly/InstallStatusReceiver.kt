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
        val status = intent.getIntExtra(
            PackageInstaller.EXTRA_STATUS,
            PackageInstaller.STATUS_FAILURE,
        )
        if (status == PackageInstaller.STATUS_PENDING_USER_ACTION) {
            val confirm = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
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

        fun finish(status: Int) {
            pending?.success(status)
            pending = null
        }
    }
}
