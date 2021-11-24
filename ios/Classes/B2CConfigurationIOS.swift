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

class B2CAuthority {
    
    var authorityUrl: String
    var authorityType: String
    var isDefault: Bool
    
    init(authorityUrl: String, authorityType: String, isDefault: Bool) {
        self.authorityUrl = authorityUrl
        self.authorityType = authorityType
        self.isDefault = isDefault
    }
    
    init(fromDictionary dictionary: Dictionary<String, AnyObject>) {
        self.authorityUrl = dictionary["authority_url"] as! String
        self.authorityType = dictionary["type"] as! String
        self.isDefault = dictionary["default"] as! Bool
    }
    
    func toDictionary() -> [String: Any] {
        return [
            "authority_url": authorityUrl,
            "type": authorityType,
            "default": isDefault
        ]
    }
}

class B2CConfigurationIOS {
    
    var clientId: String
    var redirectUri: String
    var accountMode: String
    var brokerRedirectUriRegistered: Bool
    var authorities: [B2CAuthority]
    var defaultScopes: [String]?
    
    init(clientId: String, redirectUri: String, accountMode: String = "MULTI",
         brokerRedirectUriRegistered: Bool = false, authorities: [B2CAuthority],
         defaultScopes: [String]?) {
        self.clientId = clientId
        self.redirectUri = redirectUri
        self.accountMode = accountMode
        self.brokerRedirectUriRegistered = brokerRedirectUriRegistered
        self.authorities = authorities
        self.defaultScopes = defaultScopes
    }
    
    func toDictionary() -> [String: Any] {
        return [
            "client_id": clientId,
            "redirect_uri": redirectUri,
            "authorities": authorities.map({ authority in
                return authority.toDictionary()
            }),
            "account_mode": accountMode,
            "broker_redirect_uri_registered": brokerRedirectUriRegistered,
            "default_scopes": defaultScopes ?? []
        ]
    }
}
