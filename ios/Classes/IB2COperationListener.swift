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

enum B2COperationState {
    case READY
    case SUCCESS
    case PASSWORD_RESET
    case USER_CANCELLED_OPERATION
    case USER_INTERACTION_REQUIRED
    case CLIENT_ERROR
    case SERVICE_ERROR
}

extension B2COperationState {
    func toString() -> String {
        switch self {
        case .READY: return "READY"
        case .SUCCESS: return "SUCCESS"
        case .PASSWORD_RESET: return "PASSWORD_RESET"
        case .USER_CANCELLED_OPERATION: return "USER_CANCELLED_OPERATION"
        case .USER_INTERACTION_REQUIRED: return "USER_INTERACTION_REQUIRED"
        case .CLIENT_ERROR: return "CLIENT_ERROR"
        case .SERVICE_ERROR: return "SERVICE_ERROR"
        }
    }
}

class B2COperationResult {
    
    var source: String
    var reason: B2COperationState
    var data: Any? = nil
    
    init(source: String, reason: B2COperationState, data: Any?) {
        self.source = source
        self.reason = reason
        self.data = data
    }
    
    func toDictionary() -> [String: Any] {
        return [
            "source": source,
            "reason": reason.toString(),
            "data": data ?? "",
            "tag": "tag"
        ]
    }
}

protocol IB2COperationListener {
    func onEvent(operationResult: B2COperationResult) -> Void
}
