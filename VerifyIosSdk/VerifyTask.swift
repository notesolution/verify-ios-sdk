//
//  VerifyTask.swift
//  VerifyIosSdk
//
//  Created by Dorian Peake on 09/06/2015.
//  Copyright (c) 2015 Nexmo. All rights reserved.
//

import Foundation

/**
    Represents one verify request. The object should exist until the verification is completed
    or fails, in which case a new verify request (and associated VerifyTask) should be created.
*/
class VerifyTask {

    fileprivate static let Log = Logger(String(describing: VerifyTask.self))

    let countryCode: String?
    
    let phoneNumber: String
    
    let gcmToken: String?
    
    var userStatus = UserStatus.new
    
    var pinCode: String?
    
    let standalone: Bool
    
    let onVerifyInProgress : () -> ()
    
    let onUserVerified : () -> ()
    
    let onError: (_ error: VerifyError) -> ()

    init(countryCode: String?, phoneNumber: String, standalone: Bool, gcmToken: String?, onVerifyInProgress: @escaping () -> (), onUserVerified: @escaping () -> (), onError: @escaping (_ error: VerifyError) -> ()) {
        self.countryCode = countryCode
        self.phoneNumber = phoneNumber
        self.standalone = standalone
        self.onVerifyInProgress = onVerifyInProgress
        self.onUserVerified = onUserVerified
        self.onError = onError
        self.gcmToken = gcmToken
    }
    
    /**
        Create the VerifyRequest object for this VerifyTask
    */
    func createVerifyRequest() -> VerifyRequest {
        return VerifyRequest(countryCode: self.countryCode, phoneNumber: self.phoneNumber, standalone: self.standalone, gcmToken: gcmToken)
    }
    
    /**
        Change user state according to the appropriate state machine
    */
    func setUserState(_ userStatus: UserStatus) {
        switch (userStatus) {
            case .pending:
                if (self.userStatus == .new) {
                    self.userStatus = .pending
                } else {
                    VerifyTask.Log.error("Attempted to set verify task to \(userStatus) but not in valid state (actually in state \(self.userStatus).")
                }
            
            case .blacklisted,
                 .expired,
                 .failed,
                 .verified:
                if (self.userStatus == .pending ||
                    self.userStatus == .new) {
                    self.userStatus = userStatus
                } else {
                    VerifyTask.Log.error("Attempted to set verify task to \(userStatus) but not in valid state (actually in state \(self.userStatus).")
                }
            
            default:
                VerifyTask.Log.error("Attempted to set verify task to \(userStatus) but currently in a final state (actually in state \(self.userStatus).")
        }
    }
}
