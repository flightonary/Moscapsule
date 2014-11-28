//
//  MoscapsuleTests.swift
//  MoscapsuleTests
//
//  Created by flightonary on 2014/11/23.
//
//    The MIT License (MIT)
//
//    Copyright (c) 2014 tonary <jetBeaver@gmail.com>. All rights reserved.
//
//    Permission is hereby granted, free of charge, to any person obtaining a copy of
//    this software and associated documentation files (the "Software"), to deal in
//    the Software without restriction, including without limitation the rights to
//    use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
//    the Software, and to permit persons to whom the Software is furnished to do so,
//    subject to the following conditions:
//
//    The above copyright notice and this permission notice shall be included in all
//    copies or substantial portions of the Software.
//
//    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
//    FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
//    COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
//    IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
//    CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

import UIKit
import XCTest

import Moscapsule

class MoscapsuleTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testConnectToMQTTServer() {
        var mqttConfig = MQTTConfig(clientId: "cid", host: "test.mosquitto.org", port: 1883, keepAlive: 60)
        
        mqttConfig.onConnectCallback = { returnCode in
            NSLog("Return Code is \(returnCode) (this callback is defined in swift.)")
        }
        mqttConfig.onDisconnectCallback = { reasonCode in
            NSLog("Reason Code is \(reasonCode) (this callback is defined in swift.)")
        }
        
        let mqttClient = MQTT.invokeMqttConnection(mqttConfig)
        sleep(3)
        XCTAssertTrue(mqttClient.isConnected)
        mqttClient.disconnect()
        sleep(3)
        XCTAssertFalse(mqttClient.isConnected)
    }
    
    func testPublishAndSubscribe() {
        var mqttConfigPub = MQTTConfig(clientId: "pub", host: "test.mosquitto.org", port: 1883, keepAlive: 60)
        var published = false
        var payload = "ほげほげ"
        mqttConfigPub.onPublishCallback = { messageId in
            NSLog("published")
            published = true
        }

        var mqttConfigSub = MQTTConfig(clientId: "sub", host: "test.mosquitto.org", port: 1883, keepAlive: 60)
        var subscribed = false
        mqttConfigSub.onSubscribeCallback = { (messageId, grantedQos) in
            NSLog("subscribed")
            subscribed = true
        }
        mqttConfigSub.onMessageCallback = { mqttMessage in
            XCTAssertEqual(mqttMessage.payloadString!, payload, "Received message is the same as published one!!")
        }
        
        let mqttClientPub = MQTT.invokeMqttConnection(mqttConfigPub)
        let mqttClientSub = MQTT.invokeMqttConnection(mqttConfigSub)
        sleep(2)
        
        mqttClientSub.subscribe("testTopic", qos: 2)
        sleep(2)
        mqttClientPub.publishString(payload, topic: "testTopic", qos: 2, retain: false)
        sleep(2)

        XCTAssertTrue(published)
        XCTAssertTrue(subscribed)

        mqttClientPub.disconnect()
        mqttClientSub.disconnect()
    }
}
