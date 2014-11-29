Moscapsule
==========

MQTT Client for iOS written in Swift.

This framework is implemented as a wrapper of Mosquitto library.

It uses Mosquitto version 1.3.5.

Mosquitto
---------
[Mosquitto](http://mosquitto.org/ "Mosquitto") is an open source message broker that implements the MQ Telemetry Transport protocol versions 3.1 and 3.1.1.
MQTT provides a lightweight method of carrying out messaging using a publish/subscribe model.
Mosquitto is written in C language.

Usage
-----
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
let mqttClient = MQTT.invokeMqttConnection(mqttConfig)

// publish and subscribe
mqttClient.publishString("message", topic: "publish/topic", qos: 2, retain: false)
mqttClient.subscribe("subscribe/topic", qos: 2)

// disconnect
mqttClient.disconnect()
```

License
-------
The MIT License (MIT)

Author
------
tonary <<jetBeaver@gmail.com>>
