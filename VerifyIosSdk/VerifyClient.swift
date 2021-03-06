//
//  VerifyClient.swift
//  VerifyIosSdk
//
//  Created by Dorian Peake on 13/05/2015.
//  Copyright (c) 2015 Nexmo. All rights reserved.
//

import Foundation
import DeviceProperties
import UIKit

/**
    Contains all verification commands available within the Nexmo Verify Service
*/
public class VerifyClient {
    
    fileprivate static var Log = Logger(String(describing: VerifyClient.self))
    
    fileprivate static var instance: VerifyClient?
    
    static var PARAM_PIN = "pin"
    
    static var sharedInstance : VerifyClient {
        get {
            if let instance = instance {
                return instance
            }
    
            instance = VerifyClient(nexmoClient: NexmoClient.sharedInstance)
            return instance!
        }
    }
    
    // nexmo sdk services
    fileprivate let nexmoClient: NexmoClient
    
    fileprivate let serviceExecutor: ServiceExecutor
    
    fileprivate let verifyService: VerifyService
    
    fileprivate let checkService: CheckService
    
    fileprivate let controlService: ControlService
    
    fileprivate let logoutService: LogoutService
    
    fileprivate let searchService: SearchService
    
    fileprivate var currentVerifyTask: VerifyTask?

    init(nexmoClient: NexmoClient, serviceExecutor: ServiceExecutor, verifyService: VerifyService, checkService: CheckService, controlService: ControlService, logoutService: LogoutService, searchService: SearchService) {
            self.nexmoClient = nexmoClient
            self.serviceExecutor = serviceExecutor
            self.verifyService = verifyService
            self.checkService = checkService
            self.controlService = controlService
            self.logoutService = logoutService
            self.searchService = searchService
    }
    
    convenience init(nexmoClient: NexmoClient) {
        self.init(nexmoClient: nexmoClient,
                  serviceExecutor: ServiceExecutor(),
                  verifyService: SDKVerifyService(),
                  checkService: SDKCheckService(),
                  controlService: SDKControlService(),
                  logoutService: SDKLogoutService(),
                  searchService: SDKSearchService())
    }
    
    /**
        Attempt to verify a user using Nexmo's Verify Service.
        Once the verification process has been started, updates on its progress
        will be relayed through the callbacks provided.
        
        To check if a user's verification pin code is correct, a subsequent call to checkPinCode should be
        initiated, along with the code provided by the user.
        
        - parameter countryCode: the ISO 3166-1 alpha-2 two-letter country code
        
        - parameter phoneNumber: the local phone number/msisdn of the mobile to verify
        
        - parameter onVerifyInProgress: callback triggered when a verification process has been successfully triggered
        
        - parameter onUserVerified: callback triggered when a user has been successfully verified
        
        - parameter onError: callback triggered when some error has occurred, e.g. wrong pin entered
    */
    public static func getVerifiedUser(countryCode: String?,
                                     phoneNumber: String,
                                     onVerifyInProgress: @escaping () -> (),
                                     onUserVerified: @escaping () -> (),
                                     onError: @escaping (_ error: VerifyError) -> ()) {
        sharedInstance.getVerifiedUser(countryCode: countryCode, phoneNumber: phoneNumber, onVerifyInProgress: onVerifyInProgress, onUserVerified: onUserVerified, onError: onError)
    }
    
    func getVerifiedUser(countryCode: String?,
                         phoneNumber: String,
                         onVerifyInProgress: @escaping () -> (),
                         onUserVerified: @escaping () -> (),
                         onError: @escaping (_ error: VerifyError) -> ()) {
        
        if (self.currentVerifyTask?.userStatus == .pending) {
            VerifyClient.Log.info("Verification attempted but one is already in progress.")
            onError(VerifyError.verification_already_started)
            return
        }
        
        // acquire new token for this verification attempt
        let verifyTask = VerifyTask(countryCode: countryCode, phoneNumber: phoneNumber, standalone: false, gcmToken: self.nexmoClient.gcmToken, onVerifyInProgress: onVerifyInProgress, onUserVerified: onUserVerified, onError: onError)
        self.currentVerifyTask = verifyTask
        
        // begin verification process
        self.verifyService.start(request: self.currentVerifyTask!.createVerifyRequest()) { response, error in
            if let error = error {
                if (error.code == 1000) {
                    onError(.network_error)
                } else {
                onError(.internal_error)
                }
                return
            }
            
            if let response = response {
                if let responseCode =  ResponseCode.Code(rawValue: response.resultCode) ,
                        (responseCode == .result_code_ok ||
                        responseCode == .verification_restarted ||
                        responseCode == .verification_expired_restarted) {
                    
                    verifyTask.setUserState(response.userStatus)
                    
                    switch (response.userStatus) {
                        case .pending:
                            verifyTask.onVerifyInProgress()
                        
                        case .verified:
                            verifyTask.onUserVerified()
                        
                        case .expired:
                            verifyTask.onError(.user_expired)
                        
                        case .blacklisted:
                            verifyTask.onError(.user_blacklisted)
                        
                        default:
                            verifyTask.onError(.internal_error)
                    }
                } else if let responseCode = ResponseCode.Code(rawValue: response.resultCode),
                          let error = ResponseCode.responseCodeToVerifyError[responseCode] {
                    verifyTask.onError(error)
                } else {
                    verifyTask.onError(.internal_error)
                }
            }
        }
    }
    
    /**
        Check whether a pin code (ususally entered by the user) is the correct verification code.
        
        Note: This command is only useful if a verification request is in progress, otherwise the command
        will simply quit and no callbacks will be triggered. If a verification request *is currently in progress*,
        either the onError or onUserVerified callbacks will be triggered, depending on whether the code is correct.
        
        - parameter pinCode: a string containing the pin code to check.
    */
    public static func checkPinCode(_ pinCode: String) {
        sharedInstance.checkPinCode(pinCode)
    }
    
    func checkPinCode(_ pinCode: String) {
        VerifyClient.Log.info("checkPinCode called")
        if let verifyTask = currentVerifyTask , verifyTask.userStatus == .pending || verifyTask.standalone {
            checkService.start(request: CheckRequest(verifyTask: verifyTask, pinCode: pinCode)) { response, error in
                if let _ = error {
                    verifyTask.onError(.internal_error)
                    return
                }
                
                if let response = response,
                        let responseCode = ResponseCode.Code(rawValue: response.resultCode) {
                    switch (responseCode) {
                        case .result_code_ok:
                            if (response.userStatus == .verified) {
                                self.currentVerifyTask?.setUserState(.verified)
                                self.currentVerifyTask?.onUserVerified()
                            }
                        
                        default:
                            if let error = ResponseCode.responseCodeToVerifyError[responseCode] {
                                verifyTask.onError(error)
                            } else {
                                verifyTask.onError(.internal_error)
                            }
                    }
                } else {
                    verifyTask.onError(.internal_error)
                }
            }
        } else {
            VerifyClient.Log.error("no verify task currently in progress")
        }
    }
    
    /**
        Check whether a pin code (ususally entered by the user) is the correct verification code.
        A verification attempt does not need to be in progress to call this command. This is useful in the
        case that an App is restarted before the verification is complete.
        
        Note: This version of the command should only be used in cases where an app may restart before verification is complete. Then you have the opportunity to continue with the verification process by calling this function with the appropriate parameters.
        
        - parameter pinCode: a string containing the pin code to check.
    
        - parameter countryCode: The ISO 3166 alpha-2 country code for the specified number
    
        - parameter number: Mobile number to verify
    
        - parameter onUserVerified: Callback which is executed when a user is verified
        
        - parameter onError: Callback which is executed when an error occurs
    */
    open static func checkPinCode(_ pinCode: String, countryCode: String?, number: String, onUserVerified: @escaping () -> (), onError: @escaping (VerifyError) -> ()) {
        sharedInstance.checkPinCode(pinCode, countryCode: countryCode, number: number, onUserVerified: onUserVerified, onError: onError)
    }
    
    func checkPinCode(_ pinCode: String, countryCode: String?, number: String, onUserVerified: @escaping () -> (), onError: @escaping (VerifyError) -> ()) {
        VerifyClient.Log.info("checkPinCode called")
        let verifyTask = VerifyTask(countryCode: countryCode,
                                    phoneNumber: number,
                                    standalone: false, /* doesn't mean anything here */
                                    gcmToken: nil,
                                    onVerifyInProgress: {},
                                    onUserVerified: onUserVerified,
                                    onError: onError)
        self.currentVerifyTask = verifyTask
        checkService.start(request: CheckRequest(verifyTask: verifyTask, pinCode: pinCode)) { response, error in
            if let _ = error {
                verifyTask.onError(.internal_error)
                return
            }
            
            if let response = response,
                    let responseCode = ResponseCode.Code(rawValue: response.resultCode) {
                switch (responseCode) {
                    case .result_code_ok:
                        if (response.userStatus == .verified) {
                            self.currentVerifyTask?.setUserState(.verified)
                            self.currentVerifyTask?.onUserVerified()
                        }
                    
                    default:
                        if let error = ResponseCode.responseCodeToVerifyError[responseCode] {
                            verifyTask.onError(error)
                        } else {
                            verifyTask.onError(.internal_error)
                        }
                }
            } else {
                verifyTask.onError(.internal_error)
            }
        }
    }
    
    /**
        Cancel the ongoing verification request - if one exists
        
        - parameter completionBlock: A callback which is invoked when the cancel request completes or fails (with an NSError)
    */
    open static func cancelVerification(_ completionBlock: @escaping (_ error: NSError?) -> ()) {
        sharedInstance.cancelVerification(completionBlock)
    }
    
    func cancelVerification(_ completionBlock: @escaping (_ error: NSError?) -> ()) {
        if let currentVerifyTask = currentVerifyTask {
            controlService.start(ControlRequest(.Cancel, verifyTask: currentVerifyTask)) { response, error in
                if let error = error {
                    completionBlock(error)
                } else {
                    self.currentVerifyTask = nil
                    completionBlock(nil)
                }
            }
        } else {
            completionBlock(NSError(domain: "VerifyClient", code: 1, userInfo: [NSLocalizedDescriptionKey : "No verification attempt in progress"]))
        }
    }
    
    /**
        Begins the next stage of the verification workflow.
    
        For example having an (SMS)->TTS->TTS and being in the SMS stage,
        invoking this function will move the verification stage onto the first TTS stage:
        SMS->(TTS)->TTS.
        
        - parameter completionBlock: A callback which is invoked when the 'next event'
                request completes or fails (with an NSError)
    */
    open static func triggerNextEvent(_ completionBlock: @escaping (_ error: NSError?) -> ()) {
        sharedInstance.triggerNextEvent(completionBlock)
    }
    
    func triggerNextEvent(_ completionBlock: @escaping (_ error: NSError?) -> ()) {
        if let currentVerifyTask = currentVerifyTask {
            controlService.start(ControlRequest(.NextEvent, verifyTask: currentVerifyTask)) { response, error in
                if let error = error {
                    completionBlock(error)
                } else {
                    completionBlock(nil)
                }
            }
        } else {
            completionBlock(NSError(domain: "VerifyClient", code: 1, userInfo: [NSLocalizedDescriptionKey : "No verification attempt in progress"]))
        }
    }
    
    /**
        Log's out the current user - if they have already been verified.
        To log out a user is to assume them unverified again.
        
        - parameter number: The user's phone number
        
        - parameter completionBlock: A callback which is invoked when the logout
                request completes of fails (with an NSError)
    */
    open static func logoutUser(countryCode: String?, number: String, completionBlock: @escaping (_ error: NSError?) -> ()) {
        sharedInstance.logoutUser(countryCode: countryCode, number: number, completionBlock: completionBlock)
    }
    
    func logoutUser(countryCode: String?, number: String, completionBlock: @escaping (_ error: NSError?) -> ()) {

        let logoutRequest = LogoutRequest(number: number, countryCode: countryCode)
        self.logoutService.start(request: logoutRequest) { response, error in
            if let error = error {
                completionBlock(error)
            } else {
                completionBlock(nil)
            }
        }
    }
    
    /**
        Returns the verification status of a given user. 
        
        This can be one of:
        
            *verified*
                The user has been successfully verified.
    
            *pending*
                A verification request for this user 
                is currently in progress.

            *new*
                This user just been created on the SDK service
            
            *failed*
                A previous verification request for this
                user has failed.
            
            *expired*
                A previous verification request for this
                user expired.
            
            *unverified*
                A user's verified status has been revoked,
                possibly due to timeout.
            
            *blacklisted*
                This user has failed too many verification
                requests and is therefore blacklisted.

            *error*
                An error ocurred during the last verification
                attempt for this user.

            *unknown*
                The user is unknown to the SDK service.
        
        - parameter completionBlock: A callback which is invoked when the logout request
                completes or fails (with an NSError)
    */
    open static func getUserStatus(countryCode: String?, number: String, completionBlock: @escaping (_ status: UserStatus, _ error: NSError?) -> ()) {
        VerifyClient.sharedInstance.getUserStatus(countryCode: countryCode, number: number, completionBlock: completionBlock)
    }
    
    func getUserStatus(countryCode: String?, number: String, completionBlock: @escaping (_ status: UserStatus, _ error: NSError?) -> ()) {
        let searchRequest = SearchRequest(number: number, countryCode: countryCode)
        self.searchService.start(request: searchRequest) { response, error in
            if let error = error {
                completionBlock(.unknown, error)
            } else {
                completionBlock(response!.userStatus, nil)
            }
        }
        return
    }
    
    /**
        Filters Nexmo Verify push notifications and returns the verify pin code where possible.
        
        - parameter userInfo: The push data passed in through UIApplicationDelegate's
                application:didReceiveRemoteNotification: function.
        
        - parameter performSilentCheck: if true, Nexmo Verify SDK will complete the verification request
                automatically, which verifies the user.
    */
    open static func handleNotification(_ userInfo: [AnyHashable: Any], performSilentCheck: Bool) -> Bool {
        return VerifyClient.sharedInstance.handleNotification(userInfo, performSilentCheck: performSilentCheck)
    }
    
    func handleNotification(_ userInfo: [AnyHashable: Any], performSilentCheck: Bool) -> Bool {
        if let pin = userInfo[VerifyClient.PARAM_PIN] as? String {
            if (performSilentCheck) {
                checkPinCode(pin)
            } else {
                let controller = UIAlertController(title: "Verify Pin", message: "Your verification pin is \(pin)", preferredStyle: .alert)
                let okAction = UIAlertAction(title: "Okay", style: .default, handler: nil)
                controller.addAction(okAction)
                UIApplication.shared.keyWindow?.rootViewController?.present(controller, animated: true, completion: nil)
            }
            return true
        }
        return false
    }
    
    open static func verifyStandalone(countryCode: String?, phoneNumber: String,
                                        onVerifyInProgress: @escaping () -> (),
                                        onUserVerified: @escaping () -> (),
                                        onError: @escaping (_ error: VerifyError) -> ()) {
        sharedInstance.verifyStandalone(countryCode: countryCode, phoneNumber: phoneNumber, onVerifyInProgress: onVerifyInProgress, onUserVerified: onUserVerified, onError: onError)
    }
    
    func verifyStandalone(countryCode: String?, phoneNumber: String,
                                        onVerifyInProgress: @escaping () -> (),
                                        onUserVerified: @escaping () -> (),
                                        onError: @escaping (_ error: VerifyError) -> ()) {
        
        if (self.currentVerifyTask?.userStatus == .pending) {
            VerifyClient.Log.info("Verification attempted but one is already in progress.")
            onError(VerifyError.verification_already_started)
            return
        }
        
        // acquire new token for this verification attempt
        let verifyTask = VerifyTask(countryCode: countryCode,
                                    phoneNumber: phoneNumber,
                                    standalone: true,
                                    gcmToken: self.nexmoClient.gcmToken,
                                    onVerifyInProgress: onVerifyInProgress,
                                    onUserVerified: onUserVerified,
                                    onError: onError)
        self.currentVerifyTask = verifyTask
        
        // begin verification process
        self.verifyService.start(request: self.currentVerifyTask!.createVerifyRequest()) { response, error in
            if let _ = error {
                onError(.internal_error)
                return
            }
            
            if let response = response {
                if let responseCode =  ResponseCode.Code(rawValue: response.resultCode) ,
                        (responseCode == .result_code_ok ||
                        responseCode == .verification_restarted ||
                        responseCode == .verification_expired_restarted) {
                            
                    switch (response.userStatus) {
                        case .verified:
                            verifyTask.onVerifyInProgress()
                        
                        case .expired:
                            verifyTask.onError(.user_expired)
                        
                        case .blacklisted:
                            verifyTask.onError(.user_blacklisted)
                        
                        default:
                            verifyTask.onError(.internal_error)
                    }
                } else if let responseCode = ResponseCode.Code(rawValue: response.resultCode),
                          let error = ResponseCode.responseCodeToVerifyError[responseCode] {
                    verifyTask.onError(error)
                } else {
                    verifyTask.onError(.internal_error)
                }
            }
        }
    }
}
