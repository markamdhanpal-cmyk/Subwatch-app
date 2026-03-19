package app.subscriptionkiller.platform

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class LocalRenewalReminderChannelHandler(
    private val context: Context,
) {
    fun handle(call: MethodCall, result: MethodChannel.Result): Boolean {
        return when (call.method) {
            SCHEDULE_REMINDER_METHOD -> {
                result.success(scheduleReminder(call))
                true
            }
            CANCEL_REMINDER_METHOD -> {
                result.success(cancelReminder(call))
                true
            }
            else -> false
        }
    }

    private fun scheduleReminder(call: MethodCall): Boolean {
        val serviceKey = call.argument<String>(ARG_SERVICE_KEY)?.trim()?.takeIf { it.isNotEmpty() }
            ?: return false
        val title = call.argument<String>(ARG_TITLE)?.trim()?.takeIf { it.isNotEmpty() }
            ?: return false
        val body = call.argument<String>(ARG_BODY)?.trim()?.takeIf { it.isNotEmpty() }
            ?: return false
        val scheduledAtMillis = call.argument<Number>(ARG_SCHEDULED_AT_MILLIS)?.toLong()
            ?: return false

        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as? AlarmManager
            ?: return false
        val pendingIntent = pendingIntent(
            serviceKey = serviceKey,
            title = title,
            body = body,
        )

        return try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                alarmManager.setAndAllowWhileIdle(
                    AlarmManager.RTC_WAKEUP,
                    scheduledAtMillis,
                    pendingIntent,
                )
            } else {
                alarmManager.set(
                    AlarmManager.RTC_WAKEUP,
                    scheduledAtMillis,
                    pendingIntent,
                )
            }
            true
        } catch (_: SecurityException) {
            false
        }
    }

    private fun cancelReminder(call: MethodCall): Boolean {
        val serviceKey = call.argument<String>(ARG_SERVICE_KEY)?.trim()?.takeIf { it.isNotEmpty() }
            ?: return false
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as? AlarmManager
            ?: return false
        val pendingIntent = pendingIntent(
            serviceKey = serviceKey,
            title = "",
            body = "",
        )

        return try {
            alarmManager.cancel(pendingIntent)
            pendingIntent.cancel()
            true
        } catch (_: SecurityException) {
            false
        }
    }

    private fun pendingIntent(
        serviceKey: String,
        title: String,
        body: String,
    ): PendingIntent {
        val intent = Intent(context, RenewalReminderReceiver::class.java).apply {
            action = RenewalReminderReceiver.ACTION_SHOW_RENEWAL_REMINDER
            putExtra(RenewalReminderReceiver.EXTRA_SERVICE_KEY, serviceKey)
            putExtra(RenewalReminderReceiver.EXTRA_TITLE, title)
            putExtra(RenewalReminderReceiver.EXTRA_BODY, body)
        }
        val flags = PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        return PendingIntent.getBroadcast(
            context,
            notificationIdFor(serviceKey),
            intent,
            flags,
        )
    }

    companion object {
        const val CHANNEL_NAME = "sub_killer/local_renewal_reminder_scheduler"
        const val SCHEDULE_REMINDER_METHOD = "scheduleReminder"
        const val CANCEL_REMINDER_METHOD = "cancelReminder"

        private const val ARG_SERVICE_KEY = "serviceKey"
        private const val ARG_TITLE = "title"
        private const val ARG_BODY = "body"
        private const val ARG_SCHEDULED_AT_MILLIS = "scheduledAtMillisecondsSinceEpoch"

        fun notificationIdFor(serviceKey: String): Int {
            return serviceKey.hashCode() and Int.MAX_VALUE
        }
    }
}
