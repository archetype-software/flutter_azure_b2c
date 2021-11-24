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

import Foundation
import MSAL

class B2CProvider {
    
    var operationListener: IB2COperationListener
    var controller: FlutterViewController
    
    var b2cApp: MSALPublicClientApplication?
    var b2cConfig: B2CConfigurationIOS?
    var webViewParameters : MSALWebviewParameters?
    var users: [B2CUser]?
    
    var hostName: String!
    var tenantName: String!
    var defaultScopes: [String]!
    var authResults: [String: MSALResult] = [:]
    
    init(operationListener: IB2COperationListener, controller: FlutterViewController) {
        self.operationListener = operationListener
        self.controller = controller
    }
    
    /**
     * Init B2C application. It looks for existing accounts and retrieves information.
     */
    func initMSAL(fileName: String) {
        if let path = Bundle.main.path(forResource: fileName, ofType: "json") {
            do {
                let data = try Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe)
                let jsonResult = try JSONSerialization.jsonObject(with: data, options: .mutableLeaves)
                
                if let jsonResult = jsonResult as? Dictionary<String, AnyObject> {
                    let clientId = jsonResult["client_id"] as! String
                    let redirectUri = jsonResult["redirect_uri"] as! String
                    let accountMode = jsonResult["account_mode"] as! String
                    let brokerRedirectUriRegistered = jsonResult["broker_redirect_uri_registered"] as! Bool
                    var authorities: [B2CAuthority] = []
                    
                    if let authorityDicts = jsonResult["authorities"] as? [Dictionary<String, AnyObject>] {
                        authorityDicts.forEach { dictionary in
                            authorities.append(B2CAuthority(fromDictionary: dictionary))
                        }
                    }
                    
                    if let scopes = jsonResult["default_scopes"] as? [String] {
                        defaultScopes = []
                        scopes.forEach { scope in
                            defaultScopes?.append(scope)
                        }
                    }
                    
                    b2cConfig = B2CConfigurationIOS(
                        clientId: clientId,
                        redirectUri: redirectUri,
                        accountMode: accountMode,
                        brokerRedirectUriRegistered: brokerRedirectUriRegistered,
                        authorities: authorities,
                        defaultScopes: defaultScopes
                    )
                    
                    if let kAuthority = b2cConfig?.authorities.first?.authorityUrl {
                        
                        guard let authorityURL = URL(string: kAuthority) else {
                            // handle error (authority url could not be parsed)
                            return
                        }

                        let authority = try MSALB2CAuthority(url: authorityURL)
                        let msalConfiguration = MSALPublicClientApplicationConfig(
                            clientId: b2cConfig!.clientId,
                            redirectUri: b2cConfig!.redirectUri,
                            authority: authority
                        )
                        msalConfiguration.knownAuthorities = try b2cConfig!.authorities.map({ b2cAuthority in
                            let authorityURL = URL(string: b2cAuthority.authorityUrl)
                            let authority = try MSALB2CAuthority(url: authorityURL!)
                            return authority
                        })
                        
                        self.b2cApp = try MSALPublicClientApplication(configuration: msalConfiguration)
                        self.setHostAndTenantFromAuthority(authority: b2cApp!.configuration.authority)
                        
                        self.initWebViewParams()
                        self.loadAccounts(source: B2CProvider.INIT)
                    }
                    else {
                        operationListener.onEvent(operationResult: B2COperationResult(
                            source: B2CProvider.INIT,
                            reason: B2COperationState.CLIENT_ERROR,
                            data: "No authority URLs specified in configuration JSON file."
                        ))
                    }
                }
                else {
                    operationListener.onEvent(operationResult: B2COperationResult(
                        source: B2CProvider.INIT,
                        reason: B2COperationState.CLIENT_ERROR,
                        data: "Configuration JSON could not be parsed. Please ensure JSON is valid."
                    ))
                }
            }
            catch {
                operationListener.onEvent(operationResult: B2COperationResult(
                    source: B2CProvider.INIT,
                    reason: B2COperationState.CLIENT_ERROR,
                    data: error
                ))
            }
        }
    }
    
    /**
     * Runs user flow interactively.
     *
     * Once the user finishes with the flow, you will also receive an access token containing the
     * claims for the scope you passed in, which you can subsequently use to obtain your resources.
     */
    func policyTriggerInteractive(policyName: String, scopes: [String], loginHint: String?) {
        guard let b2cApp = self.b2cApp else { return }
        guard let webViewParameters = self.webViewParameters else { return }
        
        let parameters = MSALInteractiveTokenParameters(scopes: scopes, webviewParameters: webViewParameters)
        parameters.promptType = .login
        parameters.loginHint = loginHint
        if let authority = getAuthorityFromPolicyName(policyName: policyName, source: B2CProvider.POLICY_TRIGGER_INTERACTIVE) {
            parameters.authority = authority
        }
        
        b2cApp.acquireToken(with: parameters, completionBlock: <#T##MSALCompletionBlock##MSALCompletionBlock##(MSALResult?, Error?) -> Void#>)
    }
    
    func initWebViewParams() {
        self.webViewParameters = MSALWebviewParameters(authPresentationViewController: controller)
    }
    
    func loadAccounts(source: String) {
        if (b2cApp == nil) { return }
        
        let msalParameters = MSALAccountEnumerationParameters()
        msalParameters.completionBlockQueue = DispatchQueue.main
        msalParameters.returnOnlySignedInAccounts = true
        
        b2cApp!.accountsFromDevice(for: msalParameters) { accs, err in
            if let error = err {
                self.operationListener.onEvent(operationResult: B2COperationResult(
                    source: source,
                    reason: B2COperationState.CLIENT_ERROR,
                    data: error
                ))
                return
            }
            if let accounts = accs {
                self.users = B2CUser.getB2CUsersFromAccountList(accounts: accounts)
                self.operationListener.onEvent(operationResult: B2COperationResult(
                    source: B2CProvider.INIT,
                    reason: B2COperationState.SUCCESS,
                    data: nil
                ))
            }
        }
    }
    
    private func setHostAndTenantFromAuthority(authority: MSALAuthority) {
        let parts = authority.url.absoluteString.split(usingRegex: "https://|/")
        hostName = parts[1]
        tenantName = parts[2]
    }
    
    private func getAuthorityFromPolicyName(policyName: String, source: String) -> MSALB2CAuthority? {
        do {
            let urlString = "https://\(hostName!)/\(tenantName!)/\(policyName)/"
            let authorityURL = URL(string: urlString)!
            return try MSALB2CAuthority(url: authorityURL)
        }
        catch {
            self.operationListener.onEvent(operationResult: B2COperationResult(
                source: source,
                reason: B2COperationState.CLIENT_ERROR,
                data: error
            ))
            return nil
        }
    }
    
    /**
     * Callback used for interactive request.
     * If succeeds we use the access token to call the Microsoft Graph.
     * Does not check cache.
     */
    private func authInteractiveCallback(source: String) -> MSALCompletionBlock {
        return { res, err in
            if let result = res {
                /* Successfully got a token, use it to call a protected resource - MSGraph */
                print("[B2CProvider] Successfully authenticated.")
                /* Stores in memory the access token. Note: refresh token managed by MSAL */
                if let subject = B2CUser.getSubjectFromAccount(account: result.account) {
                    self.authResults[subject] = result
                }
                /* Reload account asynchronously to get the up-to-date list. */
                self.loadAccounts(source: B2CProvider.POLICY_TRIGGER_INTERACTIVE)
            }
            
            if let error = err {
                if error.localizedDescription.contains(B2CProvider.B2C_PASSWORD_CHANGE) {
                    self.operationListener.onEvent(operationResult: B2COperationResult(
                        source: B2CProvider.POLICY_TRIGGER_INTERACTIVE,
                        reason: B2COperationState.PASSWORD_RESET,
                        data: error
                    ))
                }
                else {
                    // TODO: We have no real way to distinguish between client and service errors in Swift
                    // using exception types. We will have to look for specific exception messages in the
                    // error message. For now we just return every error as a client error, with the full
                    // error object.
                    self.operationListener.onEvent(operationResult: B2COperationResult(
                        source: B2CProvider.POLICY_TRIGGER_INTERACTIVE,
                        reason: B2COperationState.CLIENT_ERROR,
                        data: error
                    ))
                    print("Error: \(error.localizedDescription)")
                }
            }
        }
    }
    
    static let B2C_PASSWORD_CHANGE = "AADB2C90118"
    static let INIT = "init"
    static let POLICY_TRIGGER_SILENTLY = "policy_trigger_silently"
    static let POLICY_TRIGGER_INTERACTIVE = "policy_trigger_interactive"
    static let SIGN_OUT = "sign_out"
}

extension String {
    
    func split(usingRegex pattern: String) -> [String] {
        let regex = try! NSRegularExpression(pattern: pattern)
        let matches = regex.matches(in: self, range: NSRange(0..<utf16.count))
        let ranges = [startIndex..<startIndex] + matches.map{Range($0.range, in: self)!} + [endIndex..<endIndex]
        return (0...matches.count).map {String(self[ranges[$0].upperBound..<ranges[$0+1].lowerBound])}
    }
}