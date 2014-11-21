Pod::Spec.new do |s|
  s.name             = "mnuboSDK"
  s.version          = "1.0.0"
  s.summary          = "iOS SDK to communicate with the mnubo cloud platform"
  s.homepage         = "https://github.com/mnubo/mnubo-iOS-SDK"
  s.license          = 'MIT'
  s.author           = { "Mnubo, Inc" => "info@mnubo.com" }
  s.source           = { :git => "https://github.com/mnubo/mnubo-iOS-SDK.git", :tag => s.version.to_s }
  s.platform     = :ios, '7.0'
  s.requires_arc = true

  s.source_files = "Pod/Classes/**/*.{h,m}"
  s.public_header_files = 'Pod/Classes/*.h'
  s.private_header_files = "Pod/Classes/Private/*/*.h"
end
