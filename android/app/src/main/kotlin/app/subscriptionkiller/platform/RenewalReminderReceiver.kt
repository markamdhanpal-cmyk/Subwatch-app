package app.subscriptionkiller.platform

import android.Manifest
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import androidx.core.content.ContextCompat

class RenewalReminderReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != ACTION_SHOW_RENEWAL_REMINDER) {
            return
        }

        if (!canPostNotifications(context)) {
            return
        }

        val serviceKey = intent.getStringExtra(EXTRA_SERVICE_KEY)?.trim()?.takeIf { it.isNotEmpty() }
            ?: return
        val title = intent.getStringExtra(EXTRA_TITLE)?.trim()?.takeIf { it.isNotEmpty() }
            ?: return
        val body = intent.getStringExtra(EXTRA_BODY)?.trim()?.takeIf { it.isNotEmpty() }
            ?: return

        createNotificationChannel(context)

        val builder = NotificationCompat.Builder(context, NOTIFICATION_CHANNEL_ID)
            .setSmallIcon(android.R.drawable.ic_popup_reminder)
            .setContentTitle(title)
            .setContentText(body)
            .setStyle(NotificationCompat.BigTextStyle().bigText(body))
            .setPriority(NotificationCompat.PRIORITY_DEFAULT)
            .setCategory(NotificationCompat.CATEGORY_REMINDER)
            .setAutoCancel(true)

        contentPendingIntent(context)?.let(builder::setContentIntent)

        try {
            NotificationManagerCompat.from(context).notify(
                LocalRenewalReminderChannelHandler.notificationIdFor(serviceKey),
                builder.build(),
            )
        } catch (_: SecurityException) {
            return
        }
    }

    private fun canPostNotifications(context: Context): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) {
            return true
        }

        return ContextCompat.checkSelfPermission(
            context,
            Manifest.permission.POST_NOTIFICATIONS,
        ) == android.content.pm.PackageManager.PERMISSION_GRANTED
    }

    private fun createNotificationChannel(context: Context) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
            return
        }

        val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE)
            as? NotificationManager ?: return
        val channel = NotificationChannel(
            NOTIFICATION_CHANNEL_ID,
            NOTIFICATION_CHANNEL_NAME,
            NotificationManager.IMPORTANCE_DEFAULT,
        ).apply {
            description = NOTIFICATION_CHANNEL_DESCRIPTION
        }
        notificationManager.createNotificationChannel(channel)
    }

    private fun contentPendingIntent(context: Context): PendingIntent? {
        val launchIntent = context.packageManager.getLaunchIntentForPackage(context.packageName)
            ?: return null
        launchIntent.flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        val flags = PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        return PendingIntent.getActivity(context, 0, launchIntent, flags)
    }

    companion object {
        const val ACTION_SHOW_RENEWAL_REMINDER =
            "app.subscriptionkiller.action.SHOW_RENEWAL_REMINDER"
        const val EXTRA_SERVICE_KEY = "serviceKey"
        const val EXTRA_TITLE = "title"
        const val EXTRA_BODY = "body"

        private const val NOTIFICATION_CHANNEL_ID = "subwatch_renewal_reminders"
        private const val NOTIFICATION_CHANNEL_NAME = "Renewal reminders"
        private const val NOTIFICATION_CHANNEL_DESCRIPTION =
            "Local reminders for confirmed subscriptions with explicit renewal dates."
    }
}
