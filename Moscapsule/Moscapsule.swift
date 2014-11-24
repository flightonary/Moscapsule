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

public class MQTTClient {
    
    private struct MQTTCallBacks {
        /// TODO: define callbacks
    }
    
    public let clientId: String
    public let cleanSession: Bool
    private var mqttConnOpts: MQTTConnOpts
    private var mqttWillOpts: MQTTWillOpts?
    private var mqttAuthOpts: MQTTAuthOpts?

    private var mqttCallBacks: MQTTCallBacks
    private var mosquittoHandler: COpaquePointer
    
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
        self.mqttCallBacks = MQTTCallBacks()
        self.operationQueue = NSOperationQueue()
        self.mosquittoHandler = mosquitto_new(clientId.cCharArray, cleanSession, &self.mqttCallBacks)
        assert(self.mosquittoHandler != COpaquePointer.null())
    }
    
    deinit {
        mosquitto_destroy(mosquittoHandler)
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
    
    public func connect(host: String, port: Int32, keepAlive: Int32) {
        operationQueue.addOperationWithBlock {
            // set MQTT Connection Options
            mosquitto_reconnect_delay_set(self.mosquittoHandler,
                self.mqttConnOpts.reconnect_delay_s,
                self.mqttConnOpts.reconnect_delay_max_s,
                self.mqttConnOpts.reconnect_exponential_backoff)

            // set MQTT Will Options
            if let mqttWillOpts = self.mqttWillOpts {
                mosquitto_will_set(self.mosquittoHandler, mqttWillOpts.topic.cCharArray,
                    Int32(mqttWillOpts.payload.length), mqttWillOpts.payload.bytes,
                    mqttWillOpts.qos, mqttWillOpts.retain)
            }

            // set MQTT Authentication Options
            if let mqttAuthOpts = self.mqttAuthOpts {
                mosquitto_username_pw_set(self.mosquittoHandler, mqttAuthOpts.username.cCharArray, mqttAuthOpts.password.cCharArray)
            }
            
            //setCallBack()
            
            mosquitto_connect(self.mosquittoHandler, host.cCharArray, port, keepAlive)
            mosquitto_loop_forever(self.mosquittoHandler, self.mqttConnOpts.timeout_ms, 1)
        }
    }

    public func disconnect() {
        operationQueue.addOperationWithBlock {
            mosquitto_disconnect(self.mosquittoHandler)
            return
        }
    }
    
    private func setCallBack() {
        // This code can compile but does not work because CFunctionPointer<T> can be used to safely pass a C function pointer,
        // received from one C or Objective-C API, to another C or Objective-C API
        // No way to converting swift function or clojure to a C function pointer currently.
        let callbackPointer = UnsafeMutablePointer<ConnectCallBack>.alloc(1)
        callbackPointer.initialize(on_connect)
        let functionPointer = CFunctionPointer<ConnectCallBack>(COpaquePointer(callbackPointer))
        mosquitto_connect_callback_set(self.mosquittoHandler, functionPointer)
        callbackPointer.destroy()
        callbackPointer.dealloc(1)
    }
    
    private let on_connect: ConnectCallBack = { mos, obj, returnCode in
        NSLog("connection return code is \(returnCode)")
    }

    typealias ConnectCallBack = (COpaquePointer, UnsafeMutablePointer<Void>, Int32) -> Void
}

private extension String {
    var cCharArray: [CChar] {
        return self.cStringUsingEncoding(NSUTF8StringEncoding)!
    }
}