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

public class MQTTConfig {
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
        // MQTT client ID is restricted to 23 characters in the MQTT v3.1 spec
        self.clientId = { max in
            (clientId as NSString).length <= max ? clientId : clientId.substringToIndex(advance(clientId.startIndex, max))
        }(23)
        self.host = host
        self.port = port
        self.keepAlive = keepAlive
        cleanSession = true
        mqttReconnOpts = MQTTReconnOpts()
    }
}

@objc(__MosquittoContext)
public class __MosquittoContext {
    public var mosquittoHandler: COpaquePointer = COpaquePointer.null()
    public var isConnected: Bool = false
    public var onConnectCallback: ((returnCode: Int) -> Void)!
    public var onDisconnectCallback: ((reasonCode: Int) -> Void)!
    public var onPublishCallback: ((messageId: Int) -> Void)!
    public var onMessageCallback: ((message: UnsafePointer<mosquitto_message>) -> Void)!
    public var onSubscribeCallback: ((messageId: Int, qosCount: Int, grantedQos: UnsafePointer<Int32>) -> Void)!
    public var onUnsubscribeCallback: ((messageId: Int) -> Void)!
    internal init(){}
}

public class MQTTMessage {
    public let messageId: Int
    public let topic: String
    public let payload: NSData
    public let qos: Int
    public let retain: Bool
    
    public var payloadString: String? {
        return NSString(data: payload, encoding: NSUTF8StringEncoding)
    }

    internal init(messageId: Int, topic: String, payload: NSData, qos: Int, retain: Bool) {
        self.messageId = messageId
        self.topic = topic
        self.payload = payload
        self.qos = qos
        self.retain = retain
    }
}

public class MQTT {
    public class func invokeMqttConnection(mqttConfig: MQTTConfig) -> MQTTClient {
        let mosquittoContext = __MosquittoContext()
        mosquittoContext.onConnectCallback = mqttConfig.onConnectCallback
        mosquittoContext.onDisconnectCallback = mqttConfig.onDisconnectCallback
        mosquittoContext.onPublishCallback = mqttConfig.onPublishCallback
        mosquittoContext.onMessageCallback = onMessageAdapter(mqttConfig.onMessageCallback)
        mosquittoContext.onSubscribeCallback = onSubscribeAdapter(mqttConfig.onSubscribeCallback)
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
        
        // start MQTTClient
        let mqttClient = MQTTClient(mosquittoContext: mosquittoContext)
        let host = mqttConfig.host
        let port = mqttConfig.port
        let keepAlive = mqttConfig.keepAlive
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
            mosquitto_connect(mosquittoContext.mosquittoHandler, host.cCharArray, port, keepAlive)
            mosquitto_loop_start(mosquittoContext.mosquittoHandler)
            mqttClient.operationQueue.suspended = false
        }
        
        return mqttClient
    }

    private class func onMessageAdapter(callback: ((MQTTMessage) -> Void)!) -> ((UnsafePointer<mosquitto_message>) -> Void)! {
        return callback == nil ? nil : { (message: UnsafePointer<mosquitto_message>) in
            let msg = message.memory
            let topic = String.fromCString(msg.topic)!
            let payload = NSData(bytes: msg.payload, length: Int(msg.payloadlen))
            let mqttMessage = MQTTMessage(messageId: Int(msg.mid), topic: topic, payload: payload, qos: Int(msg.qos), retain: msg.retain)
            callback(mqttMessage)
        }
    }

    private class func onSubscribeAdapter(callback: ((Int, Array<Int>) -> Void)!) -> ((Int, Int, UnsafePointer<Int32>) -> Void)! {
        return callback == nil ? nil : { (messageId: Int, qosCount: Int, grantedQos: UnsafePointer<Int32>) in
            var grantedQosList = [Int](count: qosCount, repeatedValue: 0)
            Array(0..<qosCount).reduce(grantedQos) { (qosPointer, index) in
                grantedQosList[index] = Int(qosPointer.memory)
                return qosPointer.successor()
            }
            callback(messageId, grantedQosList)
        }
    }
}

public class MQTTClient {
    private let mosquittoContext: __MosquittoContext
    internal let operationQueue: NSOperationQueue
    private var isFinished: Bool
    public var isConnected: Bool {
        return mosquittoContext.isConnected
    }

    internal init(mosquittoContext: __MosquittoContext) {
        self.mosquittoContext = mosquittoContext
        self.operationQueue = NSOperationQueue()
        self.isFinished = false
        
        self.operationQueue.name = "MQTT Client Operation Queue"
        self.operationQueue.suspended = true
    }
    
    deinit {
        disconnect()
    }

    public func publish(payload: NSData, topic: String, qos: Int32, retain: Bool) {
        synchronized { mosquittoContext, operationQueue in
            operationQueue.addOperationWithBlock {
                var messageId: Int32 = 0
                mosquitto_publish(mosquittoContext.mosquittoHandler, &messageId, topic.cCharArray, Int32(payload.length), payload.bytes, qos, retain)
            }
        }
    }

    public func publishString(payload: String, topic: String, qos: Int32, retain: Bool) {
        if let payloadData = (payload as NSString).dataUsingEncoding(NSUTF8StringEncoding) {
            self.publish(payloadData, topic: topic, qos: qos, retain: retain)
        }
    }

    public func subscribe(topic: String, qos: Int32) {
        synchronized { mosquittoContext, operationQueue in
            operationQueue.addOperationWithBlock {
                var messageId: Int32 = 0
                mosquitto_subscribe(mosquittoContext.mosquittoHandler, &messageId, topic.cCharArray, qos)
            }
        }
    }

    public func unsubscribe(topic: String) {
        synchronized { mosquittoContext, operationQueue in
            operationQueue.addOperationWithBlock {
                var messageId: Int32 = 0
                mosquitto_unsubscribe(mosquittoContext.mosquittoHandler, &messageId, topic.cCharArray)
            }
        }
    }

    public func disconnect() {
        synchronized { mosquittoContext, operationQueue in
            self.isFinished = true
            operationQueue.addOperationWithBlock {
                mosquitto_disconnect(mosquittoContext.mosquittoHandler)
                return
            }
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
                operationQueue.waitUntilAllOperationsAreFinished()
                mosquitto_loop_stop(mosquittoContext.mosquittoHandler, false)
                mosquitto_context_cleanup(mosquittoContext)
            }
        }
    }

    private func synchronized(operation: (__MosquittoContext, NSOperationQueue) -> Void) {
        objc_sync_enter(self)
        if (!isFinished) {
            operation(self.mosquittoContext, self.operationQueue)
        }
        objc_sync_exit(self)
    }
}

private extension String {
    var cCharArray: [CChar] {
        return self.cStringUsingEncoding(NSUTF8StringEncoding)!
    }
}