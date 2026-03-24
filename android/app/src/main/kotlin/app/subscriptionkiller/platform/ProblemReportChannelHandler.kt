package app.subscriptionkiller.platform

import android.content.ActivityNotFoundException
import android.content.Context
import android.content.Intent
import android.net.Uri
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class ProblemReportChannelHandler(
    private val context: Context,
) {
    fun handle(call: MethodCall, result: MethodChannel.Result): Boolean {
        return when (call.method) {
            OPEN_PROBLEM_REPORT_METHOD -> {
                result.success(openProblemReport(call))
                true
            }
            else -> false
        }
    }

    private fun openProblemReport(call: MethodCall): Boolean {
        val recipient = call.argument<String>(ARG_RECIPIENT)?.trim()?.takeIf { it.isNotEmpty() }
            ?: return false
        val subject = call.argument<String>(ARG_SUBJECT)?.trim()?.takeIf { it.isNotEmpty() }
            ?: return false
        val body = call.argument<String>(ARG_BODY)?.trim()?.takeIf { it.isNotEmpty() }
            ?: return false
        val emailIntent = Intent(Intent.ACTION_SENDTO).apply {
            data = Uri.parse("mailto:$recipient")
            putExtra(Intent.EXTRA_SUBJECT, subject)
            putExtra(Intent.EXTRA_TEXT, body)
        }
        val chooserIntent = Intent.createChooser(emailIntent, "Report a problem").apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }

        return try {
            context.startActivity(chooserIntent)
            true
        } catch (_: ActivityNotFoundException) {
            false
        }
    }

    companion object {
        const val CHANNEL_NAME = "sub_killer/problem_report_launcher"
        const val OPEN_PROBLEM_REPORT_METHOD = "openProblemReport"

        private const val ARG_RECIPIENT = "recipient"
        private const val ARG_SUBJECT = "subject"
        private const val ARG_BODY = "body"
    }
}
