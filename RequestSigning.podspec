#
#  Be sure to run `pod spec lint VerifyIosSdk.podspec' to ensure this is a
#  valid spec and to remove all comments including this before submitting the spec.
#
#  To learn more about Podspec attributes see http://docs.cocoapods.org/specification.html
#  To see working Podspecs in the CocoaPods repo see https://github.com/CocoaPods/Specs/
#

Pod::Spec.new do |s|
  s.name         = "RequestSigning"
  s.version      = "1.1.0"
  s.summary      = "Nexmo verify SDK for iOS"
  s.homepage     = "https://github.com/notesolution/verify-ios-sdk"
  s.license      = { :type => "Apache 2.0", :file => "LICENSE" }
  s.author       = { "Dorian Peake" => "dorian@nexmo.com" }
  s.platform     = :ios, "8.0"
  s.source       = { :git => "https://github.com/notesolution/verify-ios-sdk.git", 
                     :tag => s.version.to_s }
  s.source_files = 'RequestSigning/*.{h,m}'
  s.requires_arc = true
end