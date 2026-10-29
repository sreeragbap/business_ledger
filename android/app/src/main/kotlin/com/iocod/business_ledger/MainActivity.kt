package com.iocod.business_ledger

import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

// local_auth shows the system BiometricPrompt, which needs a FragmentActivity.
class MainActivity : FlutterFragmentActivity() {
    // Registers its activity-result launchers, so it must exist before start.
    private val receiptScanner = ReceiptScanner(this)

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, ReceiptScanner.CHANNEL)
            .setMethodCallHandler(receiptScanner)
    }
}
