//
//  Moscapsule.swift
//  Moscapsule
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

import Foundation

public func initialize() {
    mosquitto_lib_init()
}

public func cleanup() {
    mosquitto_lib_cleanup()
}

public struct MQTTReconnOpts {
    public let reconnect_delay_s: UInt32
    public let reconnect_delay_max_s: UInt32
    public let reconnect_exponential_backoff: Bool
    public let loop_timeout_ms: Int32?
    
    public init() {
        self.reconnect_delay_s = 5 //5sec
        self.reconnect_delay_max_s = 60 * 30 //30min
        self.reconnect_exponential_backoff = true
        self.loop_timeout_ms = Optional.None
    }
    
    public init(reconnect_delay_s: UInt32, reconnect_delay_max_s: UInt32,
                reconnect_exponential_backoff: Bool, loop_timeout_ms: Int32? = Optional.None) {
        self.reconnect_delay_s = reconnect_delay_s
        self.reconnect_delay_max_s = reconnect_delay_max_s
        self.reconnect_exponential_backoff = reconnect_exponential_backoff
        self.loop_timeout_ms = loop_timeout_ms
    }
}

public struct MQTTWillOpts {
    public let topic: String
    public let payload: NSData
    public let qos: Int32
    public let retain: Bool
    
    public init(topic: String, payload: NSData, qos: Int32, retain: Bool) {
        self.topic = topic
        self.payload = payload
        self.qos = qos
        self.retain = retain
    }

    public init(topic: String, payload: String, qos: Int32, retain: Bool) {
        let rawPayload = payload.dataUsingEncoding(NSUTF8StringEncoding)!
        self.init(topic: topic, payload: rawPayload, qos: qos, retain: retain)
    }
}

public struct MQTTAuthOpts {
    public let username: String
    public let password: String
    public init(username: String, password: String) {
        self.username = username
        self.password = password
    }
}

public struct MQTTConfig {
    public let clientId: String
    public let host: String
    public let port: Int32
    public let keepAlive: Int32
    public var cleanSession: Bool
    public var mqttReconnOpts: MQTTReconnOpts
    public var mqttWillOpts: MQTTWillOpts?
    public var mqttAuthOpts: MQTTAuthOpts?
    
    public var onConnectCallback: ((returnCode: Int) -> Void)!
    public var onDisconnectCallback: ((reasonCode: Int) -> Void)!
    public var onPublishCallback: ((messageId: Int) -> Void)!
    public var onMessageCallback: ((mqttMessage: MQTTMessage) -> Void)!
    public var onSubscribeCallback: ((messageId: Int, grantedQos: Array<Int>) -> Void)!
    public var onUnsubscribeCallback: ((messageId: Int) -> Void)!
    
    public init(clientId: String, host: String, port: Int32, keepAlive: Int32) {
        self.clientId = clientId
        self.host = host
        self.port = port
        self.keepAlive = keepAlive
        cleanSession = true
        mqttReconnOpts = MQTTReconnOpts()
    }
}

@objc(MQTTMessage)
public class MQTTMessage {
    //    int mid;
    //    char *topic;
    //    void *payload;
    //    int payloadlen;
    //    int qos;
    //    bool retain;
    public let messageId: Int = 0
    public let topic: String = ""
    public let payload: NSData = NSData()
    public let qos: Int = 0
    public let retain: Bool = false
}

@objc(__MosquittoContext)
public class __MosquittoContext {
    public var mosquittoHandler: COpaquePointer = COpaquePointer.null()
    public var isConnected: Bool = false
    public var onConnectCallback: ((returnCode: Int) -> Void)!
    public var onDisconnectCallback: ((reasonCode: Int) -> Void)!
    public var onPublishCallback: ((messageId: Int) -> Void)!
    public var onMessageCallback: ((mqttMessage: MQTTMessage) -> Void)!
    public var onSubscribeCallback: ((messageId: Int, grantedQos: Array<Int>) -> Void)!
    public var onUnsubscribeCallback: ((messageId: Int) -> Void)!
}

public class MQTT {
    public class func invokeMqttConnection(mqttConfig: MQTTConfig) -> MQTTClient {
        let mosquittoContext = __MosquittoContext()

        // Test Code
        mosquittoContext.onConnectCallback = { returnCode in
            NSLog("Return Code is \(returnCode) (this callback is defined in swift.)")
        }
        mosquittoContext.onDisconnectCallback = { reasonCode in
            NSLog("Reason Code is \(reasonCode) (this callback is defined in swift.)")
        }
        // Test Code end

        mosquitto_context_initialize(mqttConfig.clientId.cCharArray, mqttConfig.cleanSession, mosquittoContext)
        
        // set MQTT Reconnection Options
        mosquitto_reconnect_delay_set(mosquittoContext.mosquittoHandler,
            mqttConfig.mqttReconnOpts.reconnect_delay_s,
            mqttConfig.mqttReconnOpts.reconnect_delay_max_s,
            mqttConfig.mqttReconnOpts.reconnect_exponential_backoff)
        
        // set MQTT Will Options
        if let mqttWillOpts = mqttConfig.mqttWillOpts {
            mosquitto_will_set(mosquittoContext.mosquittoHandler, mqttWillOpts.topic.cCharArray,
                Int32(mqttWillOpts.payload.length), mqttWillOpts.payload.bytes,
                mqttWillOpts.qos, mqttWillOpts.retain)
        }
        
        // set MQTT Authentication Options
        if let mqttAuthOpts = mqttConfig.mqttAuthOpts {
            mosquitto_username_pw_set(mosquittoContext.mosquittoHandler, mqttAuthOpts.username.cCharArray, mqttAuthOpts.password.cCharArray)
        }
        
        // create new MQTT Client !!!!!
        let mqttClient = MQTTClient(mqttConfig: mqttConfig, mosquittoContext: mosquittoContext)

        let mosquittoHandler = mosquittoContext.mosquittoHandler
        let timeout = mqttConfig.mqttReconnOpts.loop_timeout_ms ?? mqttConfig.keepAlive*1000
        let host = mqttConfig.host
        let port = mqttConfig.port
        let keepAlive = mqttConfig.keepAlive
        mqttClient.operationQueue.addOperationWithBlock {
            mosquitto_connect(mosquittoHandler, host.cCharArray, port, keepAlive)
            mosquitto_loop_forever(mosquittoHandler, timeout, 1)
        }
        
        return mqttClient
    }
}

public class MQTTClient {
    public let mqttConfig: MQTTConfig
    private let mosquittoContext: __MosquittoContext
    internal let operationQueue: NSOperationQueue
    private var hasFinished: Bool

    internal init(mqttConfig: MQTTConfig, mosquittoContext: __MosquittoContext) {
        self.mqttConfig = mqttConfig
        self.mosquittoContext = mosquittoContext
        self.operationQueue = NSOperationQueue()
        self.hasFinished = false
    }
    
    deinit {
        if(!hasFinished) {
            disconnect()
        }
    }
    
    public func publish() {}
    public func subscribe() {}

    public func disconnect() {
        hasFinished = true
        let mosquittoContext = self.mosquittoContext
        operationQueue.addOperationWithBlock {
            mosquitto_disconnect(mosquittoContext.mosquittoHandler)
            mosquitto_context_destroy(mosquittoContext)
        }
    }
}

private extension String {
    var cCharArray: [CChar] {
        return self.cStringUsingEncoding(NSUTF8StringEncoding)!
    }
}