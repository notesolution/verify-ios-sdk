//
//  SearchResponse.swift
//  VerifyIosSdk
//
//  Created by Dorian Peake on 16/08/2015.
//  Copyright (c) 2015 Nexmo Inc. All rights reserved.
//

import Foundation

class SearchResponse: BaseResponse {
    
    fileprivate(set) var userStatus = UserStatus.unknown
    
    required init?(_ httpResponse: HttpResponse) {
        super.init(httpResponse)
        
        if let userStatus = self.json[ServiceExecutor.PARAM_RESULT_USER_STATUS] as? String {
            self.userStatus = UserStatus(rawValue: userStatus) ?? .unknown
        }
    }
    
    init(userStatus: String, signature: String, resultCode: Int, resultMessage: String, timestamp: String, messageBody: String) {
        self.userStatus = UserStatus(rawValue: userStatus) ?? .unknown
        super.init(signature: signature, resultCode: resultCode, resultMessage: resultMessage, timestamp: timestamp, messageBody: messageBody)
    }
    
    convenience init(userStatus: String, signature: String, resultCode: Int, resultMessage: String, timestamp: Date, messageBody: String) {
        self.init(userStatus: userStatus, signature: signature, resultCode: resultCode, resultMessage: resultMessage, timestamp: "\(Int(timestamp.timeIntervalSince1970))", messageBody: messageBody)
    }
}
