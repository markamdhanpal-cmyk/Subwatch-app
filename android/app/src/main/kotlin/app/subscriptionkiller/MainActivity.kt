package app.subscriptionkiller

import app.subscriptionkiller.platform.DeviceSmsGatewayChannelHandler
import app.subscriptionkiller.platform.LocalMessageSourceCapabilityChannelHandler
import app.subscriptionkiller.platform.LocalRenewalReminderChannelHandler
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var capabilityHandler: LocalMessageSourceCapabilityChannelHandler? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        val capabilityHandler = LocalMessageSourceCapabilityChannelHandler(applicationContext, this)
        this.capabilityHandler = capabilityHandler
        val deviceSmsHandler = DeviceSmsGatewayChannelHandler(applicationContext)
        val localRenewalReminderHandler = LocalRenewalReminderChannelHandler(applicationContext)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            LocalMessageSourceCapabilityChannelHandler.CHANNEL_NAME,
        ).setMethodCallHandler { call, result ->
            if (!capabilityHandler.handle(call, result)) {
                result.notImplemented()
            }
        }

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            DeviceSmsGatewayChannelHandler.CHANNEL_NAME,
        ).setMethodCallHandler { call, result ->
            val messages = deviceSmsHandler.handle(call)

            if (messages == null) {
                result.notImplemented()
                return@setMethodCallHandler
            }

            result.success(messages)
        }

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            LocalRenewalReminderChannelHandler.CHANNEL_NAME,
        ).setMethodCallHandler { call, result ->
            if (!localRenewalReminderHandler.handle(call, result)) {
                result.notImplemented()
            }
        }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        capabilityHandler?.onRequestPermissionsResult(requestCode, permissions, grantResults)
    }
}
