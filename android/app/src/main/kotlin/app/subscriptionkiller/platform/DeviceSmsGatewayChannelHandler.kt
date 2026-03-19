package app.subscriptionkiller.platform

import android.Manifest
import android.content.ContentResolver
import android.content.Context
import android.content.pm.PackageManager
import android.database.Cursor
import android.os.Build
import android.provider.Telephony
import androidx.core.content.ContextCompat
import io.flutter.plugin.common.MethodCall

class DeviceSmsGatewayChannelHandler(
    private val context: Context,
) {
    fun handle(call: MethodCall): List<Map<String, Any>>? {
        if (call.method != READ_MESSAGES_METHOD) {
            return null
        }

        return readMessages()
    }

    private fun readMessages(): List<Map<String, Any>> {
        if (!hasSmsCapability() || !hasReadSmsPermission()) {
            return emptyList()
        }

        return try {
            queryMessages(context.contentResolver)
        } catch (_: SecurityException) {
            emptyList()
        }
    }

    private fun queryMessages(contentResolver: ContentResolver): List<Map<String, Any>> {
        val projection = arrayOf(
            Telephony.Sms._ID,
            Telephony.Sms.ADDRESS,
            Telephony.Sms.BODY,
            Telephony.Sms.DATE,
        )

        val messages = mutableListOf<Map<String, Any>>()
        val cursor = contentResolver.query(
            Telephony.Sms.CONTENT_URI,
            projection,
            null,
            null,
            "${Telephony.Sms.DATE} DESC LIMIT $MAX_MESSAGE_COUNT",
        )

        cursor?.use {
            while (it.moveToNext()) {
                messages += it.toRawSmsPayload()
            }
        }

        return messages
    }

    private fun Cursor.toRawSmsPayload(): Map<String, Any> {
        val idIndex = getColumnIndex(Telephony.Sms._ID)
        val addressIndex = getColumnIndex(Telephony.Sms.ADDRESS)
        val bodyIndex = getColumnIndex(Telephony.Sms.BODY)
        val dateIndex = getColumnIndex(Telephony.Sms.DATE)

        return mapOf(
            "id" to getStringOrEmpty(idIndex),
            "address" to getStringOrEmpty(addressIndex),
            "body" to getStringOrEmpty(bodyIndex),
            "receivedAtMillisecondsSinceEpoch" to getLongOrZero(dateIndex),
        )
    }

    private fun Cursor.getStringOrEmpty(columnIndex: Int): String {
        if (columnIndex == -1 || isNull(columnIndex)) {
            return ""
        }

        return getString(columnIndex) ?: ""
    }

    private fun Cursor.getLongOrZero(columnIndex: Int): Long {
        if (columnIndex == -1 || isNull(columnIndex)) {
            return 0L
        }

        return getLong(columnIndex)
    }

    private fun hasSmsCapability(): Boolean {
        val packageManager = context.packageManager

        return packageManager.hasSystemFeature(PackageManager.FEATURE_TELEPHONY)
    }

    private fun hasReadSmsPermission(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) {
            return true
        }

        return ContextCompat.checkSelfPermission(
            context,
            Manifest.permission.READ_SMS,
        ) == PackageManager.PERMISSION_GRANTED
    }

    companion object {
        const val CHANNEL_NAME = "sub_killer/device_sms_gateway"
        const val READ_MESSAGES_METHOD = "readMessages"
        private const val MAX_MESSAGE_COUNT = 250
    }
}
