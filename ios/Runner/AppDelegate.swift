import UIKit
import Flutter

@main
@objc class AppDelegate: FlutterAppDelegate {
  private let vpnBridge = IOSVpnBridge()

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    if let controller = window?.rootViewController as? FlutterViewController {
      let channel = FlutterMethodChannel(name: "inet/vpn", binaryMessenger: controller.binaryMessenger)
      channel.setMethodCallHandler(vpnBridge.handle)
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
