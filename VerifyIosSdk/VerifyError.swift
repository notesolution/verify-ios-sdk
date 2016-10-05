//
//  VerifyError.swift
//  VerifyIosSdk
//
//  Created by Dorian Peake on 18/05/2015.
//  Copyright (c) 2015 Nexmo. All rights reserved.
//

import Foundation

/**
    Possible error responses which may be returned from verify services
*/
@objc public enum VerifyError: Int {

    /** There is already a pending verification in progress. Handle {@link VerifyClientListener} events to check the progress. */
    case verification_already_started = 1
    
    /** Number is invalid. Either:
        1. Number is missing or not a real number (in international or local format).
        2. Cannot route any verification messages to this number.
    */
    case invalid_number
    
    /* Number not provided in verify request */
    case number_required
    
    /** User must be in pending status to be able to perform a PIN check. */
    case cannot_perform_check
    
    /** Missing or invalid PIN code supplied. */
    case invalid_pin_code
    
    /** Ongoing verification has failed. A wrong PIN code was provided too many times. */
    case invalid_code_too_many_times
    
    /** Ongoing verification expired. Need to start verify again. */
    case user_expired
    
    /** Ongoing verification rejected. User blacklisted for verification. */
    case user_blacklisted
    
    /** Throttled. Too many failed requests. */
    case throttled
    
    /** Your account does not have sufficient credit to process this request. */
    case quota_exceeded
    
    /**
        Invalid Credentials. Either:
        1. Supplied Application ID may not be listed under your accepted application list.
        2. Shared secret key is invalid.
    */
    case invalid_credentials
    
    /** The SDK revision is not supported anymore. */
    case sdk_revision_not_supported
    
    /** Current iOS OS version is not supported. */
    case os_not_supported
    
    /** Generic internal error, the service might be down for the moment. Please try again later. */
    case internal_error
    
    /** This Nexmo Account has been barred from sending messages */
    case account_barred
    
    /** Having problems accessing the network */
    case network_error
}
