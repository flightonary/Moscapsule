Pod::Spec.new do |s|

  s.name         = "Moscapsule"
  s.version      = "0.7.1"
  s.summary      = "MQTT Client for iOS written in Swift"
  s.description  = <<-DESC
                   MQTT Client for iOS written in Swift.
                   This framework is implemented as a wrapper of Mosquitto library
                   and covers almost all mosquitto features.
                   DESC
  s.homepage     = "https://github.com/flightonary/Moscapsule"

  s.license      = "MIT"
  s.author       = { "tonary" => "nekomelife@gmail.com" }

  s.platform = :ios
  s.ios.deployment_target = '13.0'

  s.source       = { :git => "https://github.com/flightonary/Moscapsule.git", :tag => s.version }

  s.source_files = "Moscapsule/*.{h,swift}", "MoscapsuleBridge/**/*.{h,m}", "mosquitto/lib/*.{h,c}"
  s.public_header_files = "Moscapsule/Moscapsule.h", "MoscapsuleBridge/include/MosquittoCallbackBridge.h", "MoscapsuleBridge/include/__MosquittoContext.h", "mosquitto/lib/mosquitto.h"

  s.requires_arc = true
  s.xcconfig     = {
    'SWIFT_VERSION' => '5.9',
    'OTHER_CFLAGS' => '-DWITH_THREADING -DWITH_TLS -DWITH_TLS_PSK'
  }

  s.dependency 'OpenSSL-Universal', '~> 3.3'

end
