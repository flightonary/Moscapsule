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

public enum ReturnCode: Int {
    case Success = 0
    case Unacceptable_Protocol_Version = 1
    case Identifier_Rejected = 2
    case Broker_Unavailable = 3
    case Unknown = 256

    public var description: String {
        switch self {
        case .Success:
            return "Success"
        case .Unacceptable_Protocol_Version:
            return "Unacceptable_Protocol_Version"
        case .Identifier_Rejected:
            return "Identifier_Rejected"
        case .Broker_Unavailable:
            return "Broker_Unavailable"
        case .Unknown:
            return "Unknown"
        }
    }
}

public enum ReasonCode: Int {
    case Disconnect_Requested = 0
    case Unexpected = 1

    public var description: String {
        switch self {
        case .Disconnect_Requested:
            return "Disconnect_Requested"
        case .Unexpected:
            return "Unexpected"
        }
    }
}

public enum MosqResult: Int {
    case MOSQ_CONN_PENDING = -1
    case MOSQ_SUCCESS = 0
    case MOSQ_NOMEM = 1
    case MOSQ_PROTOCOL = 2
    case MOSQ_INVAL = 3
    case MOSQ_NO_CONN = 4
    case MOSQ_CONN_REFUSED = 5
    case MOSQ_NOT_FOUND = 6
    case MOSQ_CONN_LOST = 7
    case MOSQ_TLS = 8
    case MOSQ_PAYLOAD_SIZE = 9
    case MOSQ_NOT_SUPPORTED = 10
    case MOSQ_AUTH = 11
    case MOSQ_ACL_DENIED = 12
    case MOSQ_UNKNOWN = 13
    case MOSQ_ERRNO = 14
    case MOSQ_EAI = 15
}

public struct Qos {
    public static let At_Most_Once: Int32  = 0  // Fire and Forget, i.e. <=1
    public static let At_Least_Once: Int32 = 1  // Acknowledged delivery, i.e. >=1
    public static let Exactly_Once: Int32  = 2  // Assured delivery, i.e. =1
}

public func moscapsule_init() {
    mosquitto_lib_init()
}

public func moscapsule_cleanup() {
    mosquitto_lib_cleanup()
}

public struct MQTTReconnOpts {
    public let reconnect_delay_s: UInt32
    public let reconnect_delay_max_s: UInt32
    public let reconnect_exponential_backoff: Bool
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

public struct MQTTPublishOpts {
    public let max_inflight_messages: UInt32
    public let message_retry: UInt32
    
    public init(max_inflight_messages: UInt32, message_retry: UInt32) {
        self.max_inflight_messages = max_inflight_messages
        self.message_retry = message_retry
    }
}

public struct MQTTServerCert {
    public let cafile: String?
    public let capath: String?
    
    public init(cafile: String?, capath: String?) {
        self.cafile = cafile
        self.capath = capath
    }
}

public struct MQTTClientCert {
    public let certfile: String
    public let keyfile: String
    public let keyfile_passwd: String?
    
    public init(certfile: String, keyfile: String, keyfile_passwd: String?) {
        self.certfile = certfile
        self.keyfile = keyfile
        self.keyfile_passwd = keyfile_passwd
    }
}

public enum CertReqs: Int32 {
    case SSL_VERIFY_NONE = 0
    case SSL_VERIFY_PEER = 1
}

public struct MQTTTlsOpts {
    public let tls_insecure: Bool
    public let cert_reqs: CertReqs
    public let tls_version: String?
    public let ciphers: String?
    
    public init(tls_insecure: Bool, cert_reqs: CertReqs, tls_version: String?, ciphers: String?) {
        self.tls_insecure = tls_insecure
        self.cert_reqs = cert_reqs
        self.tls_version = tls_version
        self.ciphers = ciphers
    }
}

public struct MQTTPsk {
    public let psk: String
    public let identity: String
    public let ciphers: String?
    
    public init(psk: String, identity: String, ciphers: String?) {
        self.psk = psk
        self.identity = identity
        self.ciphers = ciphers
    }
}

public struct MQTTMessage {
    public let messageId: Int
    public let topic: String
    public let payload: NSData
    public let qos: Int32
    public let retain: Bool

    public var payloadString: String? {
        return NSString(data: payload, encoding: NSUTF8StringEncoding) as? String
    }
}

public final class MQTTConfig {
    public let clientId: String
    public let host: String
    public let port: Int32
    public let keepAlive: Int32
    public var cleanSession: Bool
    public var mqttReconnOpts: MQTTReconnOpts
    public var mqttWillOpts: MQTTWillOpts?
    public var mqttAuthOpts: MQTTAuthOpts?
    public var mqttPublishOpts: MQTTPublishOpts?
    public var mqttServerCert: MQTTServerCert?
    public var mqttClientCert: MQTTClientCert?
    public var mqttTlsOpts: MQTTTlsOpts?
    public var mqttPsk: MQTTPsk?

    public var onConnectCallback: ((returnCode: ReturnCode) -> ())!
    public var onDisconnectCallback: ((reasonCode: ReasonCode) -> ())!
    public var onPublishCallback: ((messageId: Int) -> ())!
    public var onMessageCallback: ((mqttMessage: MQTTMessage) -> ())!
    public var onSubscribeCallback: ((messageId: Int, grantedQos: Array<Int32>) -> ())!
    public var onUnsubscribeCallback: ((messageId: Int) -> ())!
    
    public init(clientId: String, host: String, port: Int32, keepAlive: Int32) {
        self.clientId = clientId
        self.host = host
        self.port = port
        self.keepAlive = keepAlive
        self.cleanSession = true
        mqttReconnOpts = MQTTReconnOpts(reconnect_delay_s: 1, reconnect_delay_max_s: 60 * 30, reconnect_exponential_backoff: true)
    }
}

public final class __MosquittoContext : NSObject {
    public var mosquittoHandler: COpaquePointer = nil
    public var isConnected: Bool = false
    public var onConnectCallback: ((returnCode: Int) -> ())!
    public var onDisconnectCallback: ((reasonCode: Int) -> ())!
    public var onPublishCallback: ((messageId: Int) -> ())!
    public var onMessageCallback: ((message: UnsafePointer<mosquitto_message>) -> ())!
    public var onSubscribeCallback: ((messageId: Int, qosCount: Int, grantedQos: UnsafePointer<Int32>) -> ())!
    public var onUnsubscribeCallback: ((messageId: Int) -> ())!
    public var keyfile_passwd: String = ""
    internal override init(){}
}

public final class MQTT {
    public class func newConnection(mqttConfig: MQTTConfig, connectImmediately: Bool = true) -> MQTTClient {
        let mosquittoContext = __MosquittoContext()
        mosquittoContext.onConnectCallback = onConnectAdapter(mqttConfig.onConnectCallback)
        mosquittoContext.onDisconnectCallback = onDisconnectAdapter(mqttConfig.onDisconnectCallback)
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
        
        // set MQTT Publish Options
        if let mqttPublishOpts = mqttConfig.mqttPublishOpts {
            mosquitto_max_inflight_messages_set(mosquittoContext.mosquittoHandler, mqttPublishOpts.max_inflight_messages)
            mosquitto_message_retry_set(mosquittoContext.mosquittoHandler, mqttPublishOpts.message_retry)
        }

        // set Server/Client Certificate
        if mqttConfig.mqttServerCert != nil || mqttConfig.mqttClientCert != nil {
            let sc = mqttConfig.mqttServerCert
            let cc = mqttConfig.mqttClientCert
            mosquittoContext.keyfile_passwd = cc?.keyfile_passwd ?? ""
            mosquitto_tls_set_bridge(sc?.cafile, sc?.capath, cc?.certfile, cc?.keyfile, mosquittoContext)
        }

        // set TLS Options
        if let mqttTlsOpts = mqttConfig.mqttTlsOpts {
            mosquitto_tls_insecure_set(mosquittoContext.mosquittoHandler, mqttTlsOpts.tls_insecure)
            mosquitto_tls_opts_set_bridge(mqttTlsOpts.cert_reqs.rawValue, mqttTlsOpts.tls_version, mqttTlsOpts.ciphers, mosquittoContext)
        }

        // set PSK
        if let mqttPsk = mqttConfig.mqttPsk {
            mosquitto_tls_psk_set_bridge(mqttPsk.psk, mqttPsk.identity, mqttPsk.ciphers, mosquittoContext)
        }

        // start MQTTClient
        let mqttClient = MQTTClient(mosquittoContext: mosquittoContext, clientId: mqttConfig.clientId)
        if connectImmediately {
            mqttClient.connectToHost(mqttConfig.host, port: mqttConfig.port, keepAlive: mqttConfig.keepAlive)
        }

        return mqttClient
    }

    private class func onConnectAdapter(callback: ((ReturnCode) -> ())!) -> ((returnCode: Int) -> ())! {
        return callback == nil ? nil : { (rawReturnCode: Int) in
            callback(ReturnCode(rawValue: rawReturnCode) ?? ReturnCode.Unknown)
        }
    }

    private class func onDisconnectAdapter(callback: ((ReasonCode) -> ())!) -> ((reasonCode: Int) -> ())! {
        return callback == nil ? nil : { (rawReasonCode: Int) in
            callback(ReasonCode(rawValue: rawReasonCode) ?? ReasonCode.Unexpected)
        }
    }

    private class func onMessageAdapter(callback: ((MQTTMessage) -> ())!) -> ((UnsafePointer<mosquitto_message>) -> ())! {
        return callback == nil ? nil : { (rawMessage: UnsafePointer<mosquitto_message>) in
            let message = rawMessage.memory
            // If there are issues with topic string, drop message on the floor
            if let topic = String.fromCString(message.topic) {
                let payload = NSData(bytes: message.payload, length: Int(message.payloadlen))
                let mqttMessage = MQTTMessage(messageId: Int(message.mid), topic: topic, payload: payload, qos: message.qos, retain: message.retain)
                callback(mqttMessage)
            }
        }
    }

    private class func onSubscribeAdapter(callback: ((Int, Array<Int32>) -> ())!) -> ((Int, Int, UnsafePointer<Int32>) -> ())! {
        return callback == nil ? nil : { (messageId: Int, qosCount: Int, grantedQos: UnsafePointer<Int32>) in
            var grantedQosList = [Int32](count: qosCount, repeatedValue: Qos.At_Least_Once)
            let _ = Array(0..<qosCount).reduce(grantedQos) { (qosPointer, index) in
                grantedQosList[index] = qosPointer.memory
                return qosPointer.successor()
            }
            callback(messageId, grantedQosList)
        }
    }
}

public final class MQTTClient {
    public let clientId: String
    private let mosquittoContext: __MosquittoContext
    private let serialQueue: NSOperationQueue = {
        let queue = NSOperationQueue()
        queue.name = "MQTT Client Operation Queue"
        queue.maxConcurrentOperationCount = 1
        return queue
    }()
    
    public private(set) var isRunning: Bool
    
    public var isConnected: Bool {
        return self.mosquittoContext.isConnected
    }
    
    private func addRequestToQueue(operation: (__MosquittoContext) -> ()) {
        let mosqContext = self.mosquittoContext
        operation(mosqContext)
    }

    internal init(mosquittoContext: __MosquittoContext, clientId: String) {
        self.mosquittoContext = mosquittoContext
        self.clientId = clientId
        self.isRunning = false
    }
    
    deinit {
        disconnect()
        addRequestToQueue { mosqContext in
            mosquitto_context_cleanup(mosqContext)
        }
    }

    public func publish(payload: NSData, topic: String, qos: Int32, retain: Bool, requestCompletion: ((MosqResult, Int) -> ())? = nil) {
        addRequestToQueue { mosqContext in
            var messageId: Int32 = 0
            let mosqReturn = mosquitto_publish(mosqContext.mosquittoHandler, &messageId, topic.cCharArray, Int32(payload.length), payload.bytes, qos, retain)
            requestCompletion?(MosqResult(rawValue: Int(mosqReturn)) ?? MosqResult.MOSQ_UNKNOWN, Int(messageId))
        }
    }

    public func publishString(payload: String, topic: String, qos: Int32, retain: Bool, requestCompletion: ((MosqResult, Int) -> ())? = nil) {
        if let payloadData = (payload as NSString).dataUsingEncoding(NSUTF8StringEncoding) {
            publish(payloadData, topic: topic, qos: qos, retain: retain, requestCompletion: requestCompletion)
        }
    }

    public func subscribe(topic: String, qos: Int32, requestCompletion: ((MosqResult, Int) -> ())? = nil) {
        addRequestToQueue { mosqContext in
            var messageId: Int32 = 0
            let mosqReturn = mosquitto_subscribe(mosqContext.mosquittoHandler, &messageId, topic.cCharArray, qos)
            requestCompletion?(MosqResult(rawValue: Int(mosqReturn)) ?? MosqResult.MOSQ_UNKNOWN, Int(messageId))
        }
    }

    public func unsubscribe(topic: String, requestCompletion: ((MosqResult, Int) -> ())? = nil) {
        addRequestToQueue { mosqContext in
            var messageId: Int32 = 0
            let mosqReturn = mosquitto_unsubscribe(mosqContext.mosquittoHandler, &messageId, topic.cCharArray)
            requestCompletion?(MosqResult(rawValue: Int(mosqReturn)) ?? MosqResult.MOSQ_UNKNOWN, Int(messageId))
        }
    }

    public func connectToHost(host: String, port: Int32, keepAlive: Int32, requestCompletion: ((MosqResult) -> ())? = nil) {
        self.isRunning = true
        addRequestToQueue { mosqContext in
            // mosquitto_connect should be call before mosquitto_loop_start.
            let mosqReturn = mosquitto_connect(mosqContext.mosquittoHandler, host, port, keepAlive)
            mosquitto_loop_start(mosqContext.mosquittoHandler)
            requestCompletion?(MosqResult(rawValue: Int(mosqReturn)) ?? MosqResult.MOSQ_UNKNOWN)
        }
    }

    public func reconnect(requestCompletion: ((MosqResult) -> ())? = nil) {
        self.isRunning = true
        addRequestToQueue { mosqContext in
            // mosquitto_reconnect should be call before mosquitto_loop_start.
            let mosqReturn = mosquitto_reconnect(mosqContext.mosquittoHandler)
            mosquitto_loop_start(mosqContext.mosquittoHandler)
            requestCompletion?(MosqResult(rawValue: Int(mosqReturn)) ?? MosqResult.MOSQ_UNKNOWN)
        }
    }

    public func disconnect(requestCompletion: ((MosqResult) -> ())? = nil) {
        self.isRunning = false
        addRequestToQueue { mosqContext in
            let mosqReturn = mosquitto_disconnect(mosqContext.mosquittoHandler)
            // Stopping loop is necessary to reconnect again.
            mosquitto_loop_stop(mosqContext.mosquittoHandler, false)
            requestCompletion?(MosqResult(rawValue: Int(mosqReturn)) ?? MosqResult.MOSQ_UNKNOWN)
        }
    }

    public func awaitRequestCompletion() {
        serialQueue.waitUntilAllOperationsAreFinished()
    }

    public var socket: Int32? {
        let sock = mosquitto_socket(mosquittoContext.mosquittoHandler)
        return (sock == -1 ? nil : sock)
    }
}

private extension String {
    var cCharArray: [CChar] {
        return self.cStringUsingEncoding(NSUTF8StringEncoding)!
    }
}
