//
//  ResponseCode.swift
//  VerifyIosSdk
//
//  Created by Dorian Peake on 16/05/2015.
//  Copyright (c) 2015 Nexmo. All rights reserved.
//

import Foundation

open class ResponseCode {

    enum Code : Int {
        /** The request was successfully accepted by Nexmo. */
        case result_code_ok = 0
        
        /** Exceeded maximum throughput - response has been throttled */
        case response_throttle = 1
        
        /** Missing or invalid App ID */
        case invalid_app_id = 2
        
        /** Invalid token. Expired token needs to be re-generated. */
        case invalid_token = 3
        
        /** Invalid app_id. Supplied app_id is not listed under your accepted application list. */
        case invalid_credentials = 4
        
        /** Internal error occurred */
        case internal_error = 5
        
        /** Unable to route your verify request! */
        case unroutable_request = 6
        
        /** Number blacklisted from verification */
        case number_blacklisted = 7
        
        /** This account has been barred from sending messages */
        case account_barred = 8
        
        /** Your account does not have sufficient credit to process this request. */
        case quota_exceeded = 9
        
        /** Concurrent verifications are not allowed - this error should never occur */
        case concurrent_verifications_not_allowed = 10
        
        /////////** Invalid signature (usually related to bad secret) **/
        case invalid_signature = 14
        
        /** Destination number does not reside within a supported network */
        case destination_number_not_supported = 15

        /** Missing or invalid PIN code supplied. */
        case invalid_pin_code = 16

        /** A wrong PIN code was provided too many times. */
        case invalid_code_too_many_times = 17
        
        /** Too many request_ids provided - this error should never occur */
        case too_many_request_ids = 18
        
        /** Control command could not be executed */
        case cannot_execute_command = 19

        /** Device ID was missing or invalid */
        case invalid_device_id = 50
        
        /** Source IP Address was missing or invalid */
        case invalid_source_ip_address = 51
        
        /** Source IP differs from previous communication with sdk service */
        case source_ip_mismatch = 52

        /** Missing or invalid phone number. */
        case invalid_number = 53

        /** Missing or invalid PIN code. */
        case invalid_code = 54

        /** User must be in pending status to be able to perform a PIN check. */
        case cannot_perform_check = 55

        /** User verified with another phone number - we will verify again. */
        case verification_restarted = 56

        /** Verified User returning after too long a duration - we will verify again. */
        case verification_expired_restarted = 57

        /** This Number SDK revision is not supported anymore. Please upgrade the SDK version to be able to perform verifications. */
        case sdk_not_supported = 58

        /** The device  iOS version is not supported. */
        case os_not_supported = 59

        /** Throttled. Too many failed requests. */
        case request_rejected = 60
        
        /** Command missing or invalid */
        case invalid_command = 61
        
        /** User status invalid for this Control request - user's should be in pending status */
        case invalid_user_status_for_command = 62
    }
    
    static let responseCodeToVerifyError: [Code: VerifyError] =
        [.response_throttle     :   .throttled,
         .invalid_app_id        :   .invalid_credentials,
         .invalid_token         :   .internal_error,
         .internal_error        :   .internal_error,
         .unroutable_request    :   .invalid_number,
         .number_blacklisted    :   .user_blacklisted,
         .account_barred        :   .account_barred,
         .quota_exceeded        :   .quota_exceeded,
         .concurrent_verifications_not_allowed  : .internal_error,
         .invalid_signature     :   .invalid_credentials,
         .destination_number_not_supported  :   .invalid_number,
         .invalid_pin_code      :   .invalid_pin_code,
         .invalid_code_too_many_times   :   .invalid_code_too_many_times,
         .too_many_request_ids  :   .internal_error,
         .invalid_device_id     :   .internal_error,
         .invalid_source_ip_address     :   .internal_error,
         .source_ip_mismatch    :   .internal_error,
         .invalid_number        :   .invalid_number,
         .invalid_code          :   .invalid_pin_code,
         .cannot_perform_check  :   .cannot_perform_check,
         .sdk_not_supported     :   .sdk_revision_not_supported,
         .os_not_supported      :   .os_not_supported,
         .request_rejected      :   .throttled,
         .invalid_command       :   .internal_error
        ]
}
