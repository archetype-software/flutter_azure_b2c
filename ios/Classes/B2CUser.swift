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

class B2CUser {
    
    /**
     * List of account objects that are associated to this B2C user.
     */
    var accounts: [MSALAccount] = []
    
    var displayName: String? {
        get {
            if accounts.isEmpty { return nil }
            return B2CUser.getB2CDisplayNameFromAccount(account: accounts.first!)
        }
    }
    
    var subject: String? {
        get {
            if accounts.isEmpty { return nil }
            return B2CUser.getSubjectFromAccount(account: accounts.first!)
        }
    }
    
    var username: String? {
        get {
            if accounts.isEmpty { return nil }
            return accounts.first!.username
        }
    }
    
    var claims: [String: Any]? {
        get {
            if accounts.isEmpty { return nil }
            return accounts.first!.accountClaims
        }
    }
}

extension B2CUser {
    
    /**
     * A factory method for generating B2C users based on the given IAccount list.
     */
    static func getB2CUsersFromAccountList(accounts: [MSALAccount]) -> [B2CUser] {
        var b2CUserHashMap: [String?: B2CUser] = [:]
        accounts.forEach { account in
            /**
             * NOTE: Because B2C treats each policy as a separate authority, the access tokens, refresh tokens, and id tokens returned from each policy are considered logically separate entities.
             * In practical terms, this means that each policy returns a separate IAccount object whose tokens cannot be used to invoke other policies.
             *
             * You can use the 'Subject' claim to identify that those accounts belong to the same user.
             */
            let subject = getSubjectFromAccount(account: account)
            var user = b2CUserHashMap[subject]
            if (user == nil) {
                user = B2CUser()
                b2CUserHashMap[subject] = user
            }
            user?.accounts.append(account)
        }
        var users: [B2CUser] = []
        users.append(contentsOf: b2CUserHashMap.values)
        return users
    }
    
    /**
     * Get name of the policy associated with the given B2C account.
     * See https://docs.microsoft.com/en-us/azure/active-directory-b2c/active-directory-b2c-reference-tokens for more info.
     */
    static func getB2CPolicyNameFromAccount(account: MSALAccount) -> String? {
        if let claims = account.accountClaims {
            if let policy = claims["tfp"] {
                return policy as? String
            }
            if let policy = claims["acr"] {
                return policy as? String
            }
        }
        return nil
    }
    
    /**
     * Get subject of the given B2C account.
     *
     * Subject is the principal about which the token asserts information, such as the user of an application.
     * See https://docs.microsoft.com/en-us/azure/active-directory-b2c/active-directory-b2c-reference-tokens for more info.
     */
    static func getSubjectFromAccount(account: MSALAccount) -> String? {
        if let claims = account.accountClaims {
            if let displayName = claims[IDToken.SUBJECT] {
                return displayName as? String
            }
        }
        return nil
    }
    
    /**
     * Get a displayable name of the given B2C account.
     * This claim is optional.
     */
    static func getB2CDisplayNameFromAccount(account: MSALAccount) -> String? {
        if let claims = account.accountClaims {
            if let displayName = claims[IDToken.NAME] {
                return displayName as? String
            }
        }
        return nil
    }
}
