//
//  SDKLogoutService.swift
//  VerifyIosSdk
//
//  Created by Dorian Peake on 12/08/2015.
//  Copyright (c) 2015 Nexmo Inc. All rights reserved.
//

import Foundation
import RequestSigning
import DeviceProperties

class SDKLogoutService: LogoutService {

    fileprivate static let Log = Logger(String(describing: SDKLogoutService.self))

    fileprivate let nexmoClient: NexmoClient
    
    fileprivate let serviceExecutor: ServiceExecutor
    
    fileprivate let requestSigner: RequestSigner
    
    fileprivate let deviceProperties: DevicePropertyAccessor
    
    init() {
        self.nexmoClient = NexmoClient.sharedInstance
        self.serviceExecutor = ServiceExecutor.sharedInstance
        self.requestSigner = SDKRequestSigner.sharedInstance()
        self.deviceProperties = SDKDeviceProperties.sharedInstance()
    }
    
    init(nexmoClient: NexmoClient, serviceExecutor: ServiceExecutor, requestSigner: RequestSigner, deviceProperties: DevicePropertyAccessor) {
        self.nexmoClient = nexmoClient
        self.serviceExecutor = serviceExecutor
        self.requestSigner = requestSigner
        self.deviceProperties = deviceProperties
    }
    
    func start(request: LogoutRequest, onResponse: @escaping (_ response: LogoutResponse?, _ error: NSError?) -> ()) {
        DispatchQueue.global().async {
            let params = NSMutableDictionary()
            
            if (!self.deviceProperties.addDeviceIdentifier(toParams: params, withKey: ServiceExecutor.PARAM_DEVICE_ID)) {
                let error = NSError(domain: "SDKLogoutService", code: 1, userInfo: [NSLocalizedDescriptionKey : "Failed to get duid!"])
                SDKLogoutService.Log.error(error.localizedDescription)
                DispatchQueue.main.async {
                    onResponse(nil, error)
                }
                
                return
            }
            
            if (!self.deviceProperties.addIpAddress(toParams: params, withKey: ServiceExecutor.PARAM_SOURCE_IP)) {
                let error = NSError(domain: "SDKLogoutService", code: 2, userInfo: [NSLocalizedDescriptionKey : "Failed to get duid!"])
                SDKLogoutService.Log.error(error.localizedDescription)
                DispatchQueue.main.async {
                    onResponse(nil, error)
                }
                
                return
            }
            
            params[ServiceExecutor.PARAM_NUMBER] = request.number
            
            if let countryCode = request.countryCode {
                params[ServiceExecutor.PARAM_COUNTRY_CODE] = countryCode
            }
            
            let swiftParams = params.copy() as! [String :String]
            self.serviceExecutor.performHttpRequestForService(LogoutResponseFactory(), nexmoClient: self.nexmoClient, path: ServiceExecutor.METHOD_LOGOUT, timestamp: Date(), params: swiftParams, isPost: false) { response, error in
                if let error = error {
                    DispatchQueue.main.async {
                        onResponse(nil, error)
                    }
                } else {
                    DispatchQueue.main.async {
                        onResponse((response as! LogoutResponse), nil)
                    }
                }
            }
            return
        }
    }
}
