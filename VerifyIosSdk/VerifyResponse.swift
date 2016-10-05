//
//  VerifyResponse.swift
//  VerifyIosSdk
//
//  Created by Dorian Peake on 13/05/2015.
//  Copyright (c) 2015 Nexmo. All rights reserved.
//

import Foundation

/**
    Contains response information from a verify request
*/
class VerifyResponse : BaseResponse {
    
    fileprivate(set) var userStatus = UserStatus.unknown
    
    required init?(_ httpResponse: HttpResponse) {
        super.init(httpResponse)
        
        if let userStatus = self.json["user_status"] as? String {
            self.userStatus = UserStatus(rawValue: userStatus) ?? .unknown
        }
    }
    
    init(userStatus: String, signature: String, resultCode: Int, resultMessage: String, timestamp: String, messageBody: String) {
        self.userStatus = UserStatus(rawValue: userStatus) ?? .unknown
        super.init(signature: signature, resultCode: resultCode, resultMessage: resultMessage, timestamp: timestamp, messageBody: messageBody)
    }
}
