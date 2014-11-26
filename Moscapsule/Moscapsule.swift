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

/**
  Default values are same as mosquitto library's one.
 */
public struct MQTTConnOpts {
    let timeout_ms: Int32 = 1000
    let reconnect_delay_s: UInt32 = 1
    let reconnect_delay_max_s: UInt32 = 1
    let reconnect_exponential_backoff = false
}

public struct MQTTWillOpts {
    let topic: String
    let payload: NSData
    let qos: Int32
    let retain: Bool
    
    init(topic: String, payload: NSData, qos: Int32, retain: Bool) {
        self.topic = topic
        self.payload = payload
        self.qos = qos
        self.retain = retain
    }

    init(topic: String, payload: String, qos: Int32, retain: Bool) {
        let rawPayload = payload.dataUsingEncoding(NSUTF8StringEncoding)!
        self.init(topic: topic, payload: rawPayload, qos: qos, retain: retain)
    }
}

public struct MQTTAuthOpts {
    let username: String
    let password: String
}

@objc(MQTTMessage)
public class MQTTMessage {
    //    int mid;
    //    char *topic;
    //    void *payload;
    //    int payloadlen;
    //    int qos;
    //    bool retain;
    var messageId: Int32 = 0
}

public class MQTTClient {
    
    public let clientId: String
    public let cleanSession: Bool
    private var mqttConnOpts: MQTTConnOpts
    private var mqttWillOpts: MQTTWillOpts?
    private var mqttAuthOpts: MQTTAuthOpts?

    private var mosquittoContext: MosquittoContext
    //private var mosquittoHandler: COpaquePointer
    
    private let operationQueue: NSOperationQueue

    public convenience init() {
        self.init(clientId: NSUUID().UUIDString)
    }

    public convenience init(clientId: String) {
        self.init(clientId: clientId, cleanSession: true)
    }

    public init(clientId: String, cleanSession: Bool) {
        self.clientId = clientId
        self.cleanSession = cleanSession
        self.mqttConnOpts = MQTTConnOpts()
        self.operationQueue = NSOperationQueue()

        // TODO: Should be mosquittoHandler managed by Unmanaged<COpaquePointer>?
        // TODO: Is reference counter of mqttContext incremented?
        self.mosquittoContext = mosquitto_context_new(clientId.cCharArray, cleanSession)
    }

    deinit {
        NSLog("will mosquitto_destroy")
        mosquitto_context_destroy(mosquittoContext)
    }

    public func setWillOpts(mqttWillOpts: MQTTWillOpts) -> MQTTClient {
        self.mqttWillOpts = mqttWillOpts
        return self
    }
    
    public func setAuthOpts(mqttAuthOpts: MQTTAuthOpts) -> MQTTClient {
        self.mqttAuthOpts = mqttAuthOpts
        return self
    }
    
    public func setConnOpts(mqttConnOpts: MQTTConnOpts) -> MQTTClient {
        self.mqttConnOpts = mqttConnOpts
        return self
    }

    public func setTlsInsecure(beInsecure: Bool) -> MQTTClient {
        mosquitto_tls_insecure_set(mosquittoContext.mosquittoHandler, beInsecure)
        return self
    }
    
    public func connect(host: String, port: Int32, keepAlive: Int32) {
        // set MQTT Connection Options
        mosquitto_reconnect_delay_set(mosquittoContext.mosquittoHandler,
            self.mqttConnOpts.reconnect_delay_s,
            self.mqttConnOpts.reconnect_delay_max_s,
            self.mqttConnOpts.reconnect_exponential_backoff)
        
        // set MQTT Will Options
        if let mqttWillOpts = mqttWillOpts {
            mosquitto_will_set(mosquittoContext.mosquittoHandler, mqttWillOpts.topic.cCharArray,
                Int32(mqttWillOpts.payload.length), mqttWillOpts.payload.bytes,
                mqttWillOpts.qos, mqttWillOpts.retain)
        }
        
        // set MQTT Authentication Options
        if let mqttAuthOpts = mqttAuthOpts {
            mosquitto_username_pw_set(mosquittoContext.mosquittoHandler, mqttAuthOpts.username.cCharArray, mqttAuthOpts.password.cCharArray)
        }
        
        mosquittoContext.onConnectCallback = { returnCode in
            NSLog("Return Code is \(returnCode) (this callback is defined in swift.)")
        }

        mosquittoContext.onDisconnectCallback = { reasonCode in
            NSLog("Reason Code is \(reasonCode) (this callback is defined in swift.)")
        }

        // against circular reference
        let mosquittoHandler = self.mosquittoContext.mosquittoHandler
        let timeout = self.mqttConnOpts.timeout_ms
        operationQueue.addOperationWithBlock {
        //dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
            mosquitto_connect(mosquittoHandler, host.cCharArray, port, keepAlive)
            mosquitto_loop_forever(mosquittoHandler, timeout, 1)
        }
    }
    
    public func disconnect() {
        operationQueue.addOperationWithBlock { [unowned self] in
        //dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
            mosquitto_disconnect(self.mosquittoContext.mosquittoHandler)
            NSLog("done disconnect")
            return
        }
    }
}

private extension String {
    var cCharArray: [CChar] {
        return self.cStringUsingEncoding(NSUTF8StringEncoding)!
    }
}