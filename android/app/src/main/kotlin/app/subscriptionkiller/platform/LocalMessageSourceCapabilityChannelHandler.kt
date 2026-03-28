package app.subscriptionkiller.platform

import android.Manifest
import android.app.Activity
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.provider.Settings
import androidx.core.content.ContextCompat
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class LocalMessageSourceCapabilityChannelHandler(
    private val context: Context,
    private val activity: Activity?,
) {
    fun handle(call: MethodCall, result: MethodChannel.Result): Boolean {
        when (call.method) {
            GET_ACCESS_STATE_METHOD -> {
                result.success(getAccessState())
                return true
            }
            REQUEST_ACCESS_METHOD -> {
                requestAccess(result)
                return true
            }
            OPEN_APP_SETTINGS_METHOD -> {
                result.success(openAppSettings())
                return true
            }
        }
        return false
    }

    private fun requestAccess(result: MethodChannel.Result) {
        if (!hasSmsCapability()) {
            result.success(REQUEST_RESULT_UNAVAILABLE)
            return
        }

        if (hasReadSmsPermission()) {
            result.success(REQUEST_RESULT_GRANTED)
            return
        }

        val activity = this.activity
        if (activity == null) {
            result.success(REQUEST_RESULT_UNAVAILABLE)
            return
        }

        if (pendingResult != null) {
            result.success(REQUEST_RESULT_UNAVAILABLE)
            return
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            pendingResult = result
            activity.requestPermissions(
                arrayOf(Manifest.permission.READ_SMS),
                REQUEST_CODE_READ_SMS,
            )
            return
        }

        result.success(REQUEST_RESULT_GRANTED)
    }

    private var pendingResult: MethodChannel.Result? = null

    fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ): Boolean {
        if (requestCode != REQUEST_CODE_READ_SMS) {
            return false
        }

        val result = pendingResult
        pendingResult = null
        result?.success(toRequestResult(grantResults))
        return true
    }

    private fun toRequestResult(grantResults: IntArray): String {
        if (grantResults.isEmpty()) {
            return REQUEST_RESULT_DENIED
        }

        return if (grantResults.all { it == PackageManager.PERMISSION_GRANTED }) {
            REQUEST_RESULT_GRANTED
        } else {
            REQUEST_RESULT_DENIED
        }
    }

    private fun getAccessState(): String {
        if (!hasSmsCapability()) {
            return ACCESS_STATE_DEVICE_LOCAL_UNAVAILABLE
        }

        return if (hasReadSmsPermission()) {
            ACCESS_STATE_DEVICE_LOCAL_AVAILABLE
        } else {
            ACCESS_STATE_DEVICE_LOCAL_DENIED
        }
    }

    private fun hasSmsCapability(): Boolean {
        return context.packageManager.hasSystemFeature(PackageManager.FEATURE_TELEPHONY)
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

    private fun openAppSettings(): Boolean {
        val activity = this.activity ?: return false
        val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
            data = Uri.fromParts("package", context.packageName, null)
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }

        return try {
            activity.startActivity(intent)
            true
        } catch (_: Exception) {
            false
        }
    }

    companion object {
        const val CHANNEL_NAME = "sub_killer/local_message_source_capability"
        const val GET_ACCESS_STATE_METHOD = "getAccessState"
        const val REQUEST_ACCESS_METHOD = "requestAccess"
        const val OPEN_APP_SETTINGS_METHOD = "openAppSettings"

        const val ACCESS_STATE_DEVICE_LOCAL_AVAILABLE = "deviceLocalAvailable"
        const val ACCESS_STATE_DEVICE_LOCAL_DENIED = "deviceLocalDenied"
        const val ACCESS_STATE_DEVICE_LOCAL_UNAVAILABLE = "deviceLocalUnavailable"

        const val REQUEST_RESULT_GRANTED = "granted"
        const val REQUEST_RESULT_DENIED = "denied"
        const val REQUEST_RESULT_UNAVAILABLE = "unavailable"

        private const val REQUEST_CODE_READ_SMS = 1001
    }
}
