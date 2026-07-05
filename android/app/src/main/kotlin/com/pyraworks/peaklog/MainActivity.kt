package com.pyraworks.peaklog

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.Calendar

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "peaklog/calendar")
            .setMethodCallHandler { call, result ->
                if (call.method == "getFirstDayOfWeek") {
                    // Calendar.getInstance().firstDayOfWeek: 1=Sun, 2=Mon, ..., 7=Sat
                    result.success(Calendar.getInstance().firstDayOfWeek)
                } else {
                    result.notImplemented()
                }
            }
    }
}
