//
//  LogoutRequest.swift
//  VerifyIosSdk
//
//  Created by Dorian Peake on 13/08/2015.
//  Copyright (c) 2015 Nexmo Inc. All rights reserved.
//

import Foundation

class LogoutRequest: Equatable {

    let number: String
    
    let countryCode: String?
    
    init(number: String, countryCode: String?) {
        self.number = number
        self.countryCode = countryCode
    }
    
    static func ==(lhs: LogoutRequest, rhs: LogoutRequest) -> Bool {
        return (lhs.number == rhs.number &&
            lhs.countryCode == rhs.countryCode)
    }
}

