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

public class MQTTReconnOpts {
    public let reconnect_delay_s: UInt32
    public let reconnect_delay_max_s: UInt32
    public let reconnect_exponential_backoff: Bool
    
    public init() {
        self.reconnect_delay_s = 5 //5sec
        self.reconnect_delay_max_s = 60 * 30 //30min
        self.reconnect_exponential_backoff = true
    }
    
    public init(reconnect_delay_s: UInt32, reconnect_delay_max_s: UInt32, reconnect_exponential_backoff: Bool) {
        self.reconnect_delay_s = reconnect_delay_s
        self.reconnect_delay_max_s = reconnect_delay_max_s
        self.reconnect_exponential_backoff = reconnect_exponential_backoff
    }
}

public class MQTTWillOpts {
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

    public convenience init(topic: String, payload: String, qos: Int32, retain: Bool) {
        let rawPayload = payload.dataUsingEncoding(NSUTF8StringEncoding)!
        self.init(topic: topic, payload: rawPayload, qos: qos, retain: retain)
    }
}

public class MQTTAuthOpts {
    public let username: String
    public let password: String

    public init(username: String, password: String) {
        self.username = username
        self.password = password
    }
}

public class MQTTConfig: __MQTTCallback {
    public let clientId: String
    public let host: String
    public let port: Int32
    public let keepAlive: Int32
    public var cleanSession: Bool
    public var mqttReconnOpts: MQTTReconnOpts
    public var mqttWillOpts: MQTTWillOpts?
    public var mqttAuthOpts: MQTTAuthOpts?
    
    public init(clientId: String, host: String, port: Int32, keepAlive: Int32) {
        self.clientId = clientId
        self.host = host
        self.port = port
        self.keepAlive = keepAlive
        cleanSession = true
        mqttReconnOpts = MQTTReconnOpts()
    }
}

@objc(__MQTTCallback)
public class __MQTTCallback {
    public var onConnectCallback: ((returnCode: Int) -> Void)!
    public var onDisconnectCallback: ((reasonCode: Int) -> Void)!
    public var onPublishCallback: ((messageId: Int) -> Void)!
    public var onMessageCallback: ((mqttMessage: MQTTMessage) -> Void)!
    public var onSubscribeCallback: ((messageId: Int, grantedQos: Array<Int>) -> Void)!
    public var onUnsubscribeCallback: ((messageId: Int) -> Void)!
    internal init(){}
}

@objc(__MosquittoContext)
public class __MosquittoContext: __MQTTCallback {
    public var mosquittoHandler: COpaquePointer = COpaquePointer.null()
    public var isConnected: Bool = false
    internal override init(){}
}

@objc(MQTTMessage)
public class MQTTMessage {
    public let messageId: Int = 0
    public let topic: String = ""
    public let payload: NSData = NSData()
    public let qos: Int = 0
    public let retain: Bool = false
}

public class MQTT {
    public class func invokeMqttConnection(mqttConfig: MQTTConfig) -> MQTTClient {
        let mosquittoContext = __MosquittoContext()
        mosquittoContext.onConnectCallback = mqttConfig.onConnectCallback
        mosquittoContext.onDisconnectCallback = mqttConfig.onDisconnectCallback
        mosquittoContext.onPublishCallback = mqttConfig.onPublishCallback
        mosquittoContext.onMessageCallback = mqttConfig.onMessageCallback
        mosquittoContext.onSubscribeCallback = mqttConfig.onSubscribeCallback
        mosquittoContext.onUnsubscribeCallback = mqttConfig.onUnsubscribeCallback

        // setup mosquittoHandler
        mosquitto_context_setup(mqttConfig.clientId.cCharArray, mqttConfig.cleanSession, mosquittoContext)

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
        
        let mosquittoHandler = mosquittoContext.mosquittoHandler
        let host = mqttConfig.host
        let port = mqttConfig.port
        let keepAlive = mqttConfig.keepAlive
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
            mosquitto_connect(mosquittoHandler, host.cCharArray, port, keepAlive)
            mosquitto_loop_start(mosquittoHandler)
        }
        
        return MQTTClient(mosquittoContext: mosquittoContext)
    }
}

public class MQTTClient {
    private let mosquittoContext: __MosquittoContext
    private let operationQueue: NSOperationQueue
    private var isFinished: Bool
    public var isConnected: Bool {
        return mosquittoContext.isConnected
    }

    internal init(mosquittoContext: __MosquittoContext) {
        self.mosquittoContext = mosquittoContext
        self.operationQueue = NSOperationQueue()
        self.isFinished = false
    }
    
    deinit {
        if(!isFinished) {
            disconnect()
        }
    }
    
    public func publish() {}
    public func subscribe() {}

    public func disconnect() {
        isFinished = true
        let mosquittoContext = self.mosquittoContext
        let operationQueue = self.operationQueue
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
            operationQueue.addOperationWithBlock {
                mosquitto_disconnect(mosquittoContext.mosquittoHandler)
                return
            }
            operationQueue.waitUntilAllOperationsAreFinished()
            mosquitto_loop_stop(mosquittoContext.mosquittoHandler, false)
            mosquitto_context_destroy(mosquittoContext)
        }
    }
}

private extension String {
    var cCharArray: [CChar] {
        return self.cStringUsingEncoding(NSUTF8StringEncoding)!
    }
}