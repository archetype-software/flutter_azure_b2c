import Flutter
import UIKit

public class SwiftFlutterAzureB2cPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "flutter_azure_b2c", binaryMessenger: registrar.messenger())
    let instance = SwiftFlutterAzureB2cPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    result("iOS " + UIDevice.current.systemVersion)
  }
}
