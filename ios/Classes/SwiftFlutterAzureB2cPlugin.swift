// Copyright © 2021 <Christian Wheeler - Archetype Software>
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the “Software”), to
// deal in the Software without restriction, including without limitation the
// rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
// sell copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:

// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.

// THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
// FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
// IN THE SOFTWARE.

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
        
        else if call.method == "policyTriggerSilently" {
            let args = call.arguments as! [String: AnyObject]
            let subject = args["subject"] as! String
            let tag = args["tag"] as! String
            let policyName = args["policyName"] as! String
            let scopes = args["scopes"] as! [String]
            
            if provider.hasSubject(subject: subject) {
                provider.policyTriggerSilently(tag: tag, subject: subject, policyName: policyName, scopes: scopes)
                result(nil)
            }
            else {
                // result.error("SubjectNotExist", "Unable to find stored user: $subject", null)
            }
        }
        
        else if call.method == "signOut" {
            let args = call.arguments as! [String: AnyObject]
            let subject = args["subject"] as! String
            let tag = args["tag"] as! String
            
            if provider.hasSubject(subject: subject) {
                provider.signOut(tag: tag, subject: subject)
                result(nil)
            }
            else {
                // result.error("SubjectNotExist", "Unable to find stored user: $subject", null)
            }
        }
        
        else if call.method == "getConfiguration" {
            let configuration: B2CConfigurationIOS = provider.getConfiguration()
            result(configuration.toDictionary())
        }
        
        else if call.method == "getSubjects" {
            let subjects = provider.getSubjects()
            result(["subjects": subjects])
        }
        
        else if call.method == "hasSubject" {
            let args = call.arguments as! [String: Any]
            let subject = args["subject"] as! String
            result(provider.hasSubject(subject: subject))
        }
        
        else if call.method == "getSubjectInfo" {
            let args = call.arguments as! [String: Any]
            let subject = args["subject"] as! String
            
            let usernm = provider.getUsername(subject: subject)
            let clms = provider.getClaims(subject: subject)
            
            if let username = usernm, let claims = clms {
                result([
                    "username": username,
                    "claims": claims
                ])
            }
            else {
                // TODO: Implement an error flag for iOS method calls, since we don't have the result.error option
//                result.error(
//                    "SubjectNotExist",
//                    "Unable to find stored user: $subject", null
//                )

            }
        }
        
        else if call.method == "getAccessToken" {
            let args = call.arguments as! [String: Any]
            let subject = args["subject"] as! String
            
            let accessToken = provider.getAccessToken(subject: subject)
            let expireDate = provider.getAccessTokenExpireDate(subject: subject)
            
            if let token = accessToken, let expiry = expireDate {
                result([
                    "subject": subject,
                    "token": token,
                    "expire": PluginUtilities.toIsoFormat(date: expiry)
                ])
            }
            else {
                print("accessToken or expiry date was null \(accessToken ?? "_") \(expireDate?.description ?? "null")")
                //                result.error(
                //                    "SubjectNotExist|SubjectNotAuthenticated",
                //                    "Unable to find authenticated user: $subject", null)
            }
        }
        else {
            // result.notImplemented()
        }
    }
    
    /**
     * B2C provider listener.
     */
    func onEvent(operationResult: B2COperationResult) {
        channel.invokeMethod("onEvent", arguments: operationResult.toDictionary())
    }
    
    /**
     * Intercepts redirect URIs which match the application's registered URI schemes.
     */
    public func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        return MSALPublicClientApplication.handleMSALResponse(url, sourceApplication: options[UIApplication.OpenURLOptionsKey.sourceApplication] as? String)
    }
}
