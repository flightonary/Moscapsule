Moscapsule
==========

MQTT Client for iOS written in Swift.  
This framework is implemented as a wrapper of Mosquitto library and covers almost all mosquitto features.  
It uses Mosquitto version 1.4.8.

Mosquitto
---------
[Mosquitto](http://mosquitto.org/ "Mosquitto") is an open source message broker that implements the MQ Telemetry Transport protocol versions 3.1 and 3.1.1.
MQTT provides a lightweight method of carrying out messaging using a publish/subscribe model.
Mosquitto is written in C language.

Installation
------------

### CocoaPods
[CocoaPods](http://cocoapods.org) is a Cocoa project manager. It is a easy way for to install framework, so I recommend to using it.  
Specify it in your podfile;
```
use_frameworks!

pod 'Moscapsule', :git => 'https://github.com/flightonary/Moscapsule.git'
pod 'OpenSSL-Universal', '~> 1.0.1.18'
```

and then run;
```
$ pod install
```

In order to import the framework in tests, you should select configuration files.  
a) Select your project and `info`.  
b) Change configuration files from none to Pods.debug/release.  
![Configuration File](https://flightonary.github.io/img/inst_with_cocoapods.png)

### Manual Installation
If you don't want to use CocoaPods, you can install manually.

a) Check out Moscapsule.  
```
$ git clone https://github.com/flightonary/Moscapsule.git
```
b) The framework depends on [OpenSSL](https://github.com/krzyzanowskim/OpenSSL "OpenSSL"). Before building it, you must checkout the submodule.
```
$ git submodule update --init  
```
c) Create a Xcode project and Workspace if you don't have these.  
d) Open workspace and drag & drop your project and Moscapsule.xcodeproj into Navigation.  
e) Drag & drop Moscapsule.xcodeproj under your project tree in Navitaion.  
f) Select your project and `Build Phases`.  
g) Add Moscapsule in `Target Dependencies` and `Link Binary With Libraries` using `+` button.  

![Moscapsule Manual Installation](https://flightonary.github.io/img/mosq_install.png)


Usage
-----
Here is a basic sample.
```swift
import Moscapsule

// set MQTT Client Configuration
let mqttConfig = MQTTConfig(clientId: "cid", host: "test.mosquitto.org", port: 1883, keepAlive: 60)
mqttConfig.onPublishCallback = { messageId in
    NSLog("published (mid=\(messageId))")
}
mqttConfig.onMessageCallback = { mqttMessage in
    NSLog("MQTT Message received: payload=\(mqttMessage.payloadString)")
}

// create new MQTT Connection
let mqttClient = MQTT.newConnection(mqttConfig)

// publish and subscribe
mqttClient.publishString("message", topic: "publish/topic", qos: 2, retain: false)
mqttClient.subscribe("subscribe/topic", qos: 2)

// disconnect
mqttClient.disconnect()
```

The framework supports TLS_PSK, Server and/or Client certification.  
Here is a sample for server certificate.
```swift
import Moscapsule

// Note that you must initialize framework only once after launch application
// in case that it uses SSL/TLS functions.
moscapsule_init()

let mqttConfig = MQTTConfig(clientId: "server_cert_test", host: "test.mosquitto.org", port: 8883, keepAlive: 60)

let bundlePath = NSBundle(forClass: self.dynamicType).bundlePath.stringByAppendingPathComponent("cert.bundle")
let certFile = bundlePath.stringByAppendingPathComponent("mosquitto.org.crt")

mqttConfig.mqttServerCert = MQTTServerCert(cafile: certFile, capath: nil)

let mqttClient = MQTT.newConnection(mqttConfig)
```

License
-------
The MIT License (MIT)

Author
------
tonary <<jetBeaver@gmail.com>>
