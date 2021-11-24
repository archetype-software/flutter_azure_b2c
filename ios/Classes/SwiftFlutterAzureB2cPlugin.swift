import Flutter
import UIKit
import MSAL

public class SwiftFlutterAzureB2cPlugin: NSObject, FlutterPlugin, IB2COperationListener {
    
    var controller: FlutterViewController!
    var provider: B2CProvider!
    var channel: FlutterMethodChannel!
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "flutter_azure_b2c", binaryMessenger: registrar.messenger())
        let instance = SwiftFlutterAzureB2cPlugin()
        instance.controller = ((UIApplication.shared.delegate?.window??.rootViewController)! as! FlutterViewController)
        instance.provider = B2CProvider(operationListener: instance, controller: instance.controller)
        instance.channel = channel
        registrar.addApplicationDelegate(instance)
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    
    /**
     * Handles method calls from Flutter.
     */
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        if call.method == "handleRedirectFuture" {
            result("B2C_PLUGIN_DEFAULT")
        }
        
        else if call.method == "init" {
            let args = call.arguments as! [String: AnyObject]
            let configFile = args["configFile"] as! String
            provider.initMSAL(fileName: configFile)
            result(nil)
        }
        
        else if call.method == "policyTriggerInteractive" {
            let args = call.arguments as! [String: AnyObject]
            let policyName = args["policyName"] as! String
            let scopes = args["scopes"] as! [String]
            var loginHint: String? = nil
            
            if (args.contains(where: { key, value in return key == "loginHint" }) && args["loginHint"] != nil) {
                loginHint = args["loginHint"] as? String
            }
            
            provider.policyTriggerInteractive(policyName: policyName, scopes: scopes, loginHint: loginHint)
            result(nil)
        }
    }
    
    /**
     * B2C provider listener.
     */
    func onEvent(operationResult: B2COperationResult) {
        channel.invokeMethod("onEvent", arguments: [
            "source": operationResult.source,
            "reason": operationResult.reason,
            "data": operationResult.data
        ])
    }
    
    /**
     * Intercepts redirect URIs which match the application's registered URI schemes.
     */
    public func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        return MSALPublicClientApplication.handleMSALResponse(url, sourceApplication: options[UIApplication.OpenURLOptionsKey.sourceApplication] as? String)
    }
}
