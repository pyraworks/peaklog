import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    let messenger = engineBridge.applicationRegistrar.messenger()
    let channel = FlutterMethodChannel(name: "peaklog/calendar", binaryMessenger: messenger)
    channel.setMethodCallHandler { call, result in
      if call.method == "getFirstDayOfWeek" {
        // Calendar.current.firstWeekday: 1=Sun, 2=Mon, ..., 7=Sat
        result(Calendar.current.firstWeekday)
      } else {
        result(FlutterMethodNotImplemented)
      }
    }
  }
}
