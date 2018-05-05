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
    case success = 0
    case unacceptable_protocol_version = 1
    case identifier_rejected = 2
    case broker_unavailable = 3
    case unknown = 256
    
    public var description: String {
        switch self {
        case .success:
            return "Success"
        case .unacceptable_protocol_version:
            return "Unacceptable_Protocol_Version"
        case .identifier_rejected:
            return "Identifier_Rejected"
        case .broker_unavailable:
            return "Broker_Unavailable"
        case .unknown:
            return "Unknown"
        }
    }
}

public enum ReasonCode: Int {
    case disconnect_requested = 0
    case keepAlive_timeout = 1
    
    // Mosquitto confuses ReasonCode with MosqResult.
    // These are possibly returned as ReasonCode in _mosquitto_loop_rc_handle.
    case mosq_protocol = 2
    case mosq_inval = 3
    case mosq_no_conn = 4
    case mosq_conn_refused = 5
    case mosq_not_found = 6
    case mosq_conn_lost = 7
    case mosq_tls = 8
    case mosq_payload_size = 9
    case mosq_not_supported = 10
    case mosq_auth = 11
    case mosq_acl_denied = 12
    case mosq_unknown = 13
    case mosq_errno = 14
    case mosq_eai = 15
    case mosq_err_proxy = 16
    
    case unknown = 256
    
    public var description: String {
        switch self {
        case .disconnect_requested:
            return "Disconnect_Requested"
        case .keepAlive_timeout:
            return "KeepAlive_Timeout"
        case .mosq_no_conn:
            return "MOSQ_NO_CONN"
        case .mosq_conn_lost:
            return "MOSQ_CONN_LOST"
        case .mosq_errno:
            return "MOSQ_ERRNO"
        case .unknown:
            return "Unknown"
        default:
            return self.rawValue.description
        }
    }
}

public enum MosqResult: Int {
    case mosq_conn_pending = -1
    case mosq_success = 0
    case mosq_nomem = 1
    case mosq_protocol = 2
    case mosq_inval = 3
    case mosq_no_conn = 4
    case mosq_conn_refused = 5
    case mosq_not_found = 6
    case mosq_conn_lost = 7
    case mosq_tls = 8
    case mosq_payload_size = 9
    case mosq_not_supported = 10
    case mosq_auth = 11
    case mosq_acl_denied = 12
    case mosq_unknown = 13
    case mosq_errno = 14
    case mosq_eai = 15
    case mosq_err_proxy = 16
}

public struct Qos {
    public static let at_most_once: Int32  = 0  // Fire and Forget, i.e. <=1
    public static let at_least_once: Int32 = 1  // Acknowledged delivery, i.e. >=1
    public static let exactly_once: Int32  = 2  // Assured delivery, i.e. =1
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

	public init(delay: UInt32, max: UInt32, exponentialBackoff: Bool) {
		reconnect_delay_max_s = max
		reconnect_exponential_backoff = exponentialBackoff
		reconnect_delay_s = delay
	}
}

public struct MQTTWillOpts {
    public let topic: String
    public let payload: Data
    public let qos: Int32
    public let retain: Bool
    
    public init(topic: String, payload: Data, qos: Int32, retain: Bool) {
        self.topic = topic
        self.payload = payload
        self.qos = qos
        self.retain = retain
    }
    
    public init(topic: String, payload: String, qos: Int32, retain: Bool) {
        let rawPayload = payload.data(using: .utf8)!
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
    case ssl_verify_none = 0
    case ssl_verify_peer = 1
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
    public let payload: Data?
    public let qos: Int32
    public let retain: Bool
    
    public init(messageId: Int, topic: String, payload: Data?, qos: Int32, retain: Bool) {
        self.messageId = messageId
        self.topic = topic
        self.payload = payload
        self.qos = qos
        self.retain = retain
    }
    
    public var payloadString: String? {
        guard let payload = payload else {
            return nil
        }
        
        let encodingsToTry: [String.Encoding] = [
            .utf8, .ascii, .utf16, .utf16BigEndian,
            .utf16LittleEndian, .utf32, .utf32BigEndian,
            .utf32LittleEndian, .nextstep, .japaneseEUC,
            .isoLatin1, .symbol, .nonLossyASCII, .shiftJIS,
            .isoLatin2, .unicode, .windowsCP1250, .windowsCP1251,
            .windowsCP1252, .windowsCP1253, .windowsCP1254,
            .iso2022JP, .macOSRoman
        ]
        
        for encoding in encodingsToTry {
            if let string = String(data: payload, encoding: encoding) {
                return string
            }
        }
        
        let hexString = (payload as Data).map { String(format: "%02.2hhx", $0) }.joined()
        return hexString
    }
}

public enum MQTTProtocol: Int32 {
  case v3_1 = 0
  case v3_1_1 = 1
}

public final class MQTTConfig {
    public let clientId: String
    public let host: String
    public let port: Int32
    public let keepAlive: Int32
    public let protocolVersion: MQTTProtocol
    public var cleanSession: Bool
    public var mqttReconnOpts: MQTTReconnOpts?
    public var mqttWillOpts: MQTTWillOpts?
    public var mqttAuthOpts: MQTTAuthOpts?
    public var mqttPublishOpts: MQTTPublishOpts?
    public var mqttServerCert: MQTTServerCert?
    public var mqttClientCert: MQTTClientCert?
    public var mqttTlsOpts: MQTTTlsOpts?
    public var mqttPsk: MQTTPsk?
    
    public var onConnectCallback: ((_ returnCode: ReturnCode) -> ())!
    public var onDisconnectCallback: ((_ reasonCode: ReasonCode) -> ())!
    public var onPublishCallback: ((_ messageId: Int) -> ())!
    public var onMessageCallback: ((_ mqttMessage: MQTTMessage) -> ())!
    public var onSubscribeCallback: ((_ messageId: Int, _ grantedQos: Array<Int32>) -> ())!
    public var onUnsubscribeCallback: ((_ messageId: Int) -> ())!
    
    public init(clientId: String, host: String, port: Int32, keepAlive: Int32, protocolVersion: MQTTProtocol = .v3_1) {
        self.clientId = clientId
        self.host = host
        self.port = port
        self.keepAlive = keepAlive
        self.protocolVersion = protocolVersion
        self.cleanSession = true
        mqttReconnOpts = MQTTReconnOpts(delay: 1, max: 60 * 30, exponentialBackoff: true)
    }
}

public final class __MosquittoContext : NSObject {
    @objc public var mosquittoHandler: OpaquePointer? = nil
    @objc public var isConnected: Bool = false
    @objc public var onConnectCallback: ((_ returnCode: Int) -> ())!
    @objc public var onDisconnectCallback: ((_ reasonCode: Int) -> ())!
    @objc public var onPublishCallback: ((_ messageId: Int) -> ())!
    @objc public var onMessageCallback: ((_ message: UnsafePointer<mosquitto_message>) -> ())!
    @objc public var onSubscribeCallback: ((_ messageId: Int, _ qosCount: Int, _ grantedQos: UnsafePointer<Int32>) -> ())!
    @objc public var onUnsubscribeCallback: ((_ messageId: Int) -> ())!
    @objc public var keyfile_passwd: String = ""
    internal override init(){}
}

public final class MQTT {
    public class func newConnection(_ mqttConfig: MQTTConfig, connectImmediately: Bool = true) -> MQTTClient {
        let mosquittoContext = __MosquittoContext()
        mosquittoContext.onConnectCallback = onConnectAdapter(mqttConfig.onConnectCallback)
        mosquittoContext.onDisconnectCallback = onDisconnectAdapter(mqttConfig.onDisconnectCallback)
        mosquittoContext.onPublishCallback = mqttConfig.onPublishCallback
        mosquittoContext.onMessageCallback = onMessageAdapter(mqttConfig.onMessageCallback)
        mosquittoContext.onSubscribeCallback = onSubscribeAdapter(mqttConfig.onSubscribeCallback)
        mosquittoContext.onUnsubscribeCallback = mqttConfig.onUnsubscribeCallback

        let protocolVersion: Int32
        switch mqttConfig.protocolVersion {
        case .v3_1:
            protocolVersion = MQTT_PROTOCOL_V31
        case .v3_1_1:
            protocolVersion = MQTT_PROTOCOL_V311
        }

        // setup mosquittoHandler
        mosquitto_context_setup(mqttConfig.clientId.cCharArray, mqttConfig.cleanSession, mosquittoContext, protocolVersion)
        // set MQTT Reconnection Options
		if let options = mqttConfig.mqttReconnOpts {
			mosquitto_reconnect_delay_set(mosquittoContext.mosquittoHandler,
										  options.reconnect_delay_s,
										  options.reconnect_delay_max_s,
										  options.reconnect_exponential_backoff)
		} else {
			mosquitto_reconnect_disable(mosquittoContext.mosquittoHandler)
		}
		
        // set MQTT Will Options
        if let mqttWillOpts = mqttConfig.mqttWillOpts {
            mqttWillOpts.payload.withUnsafeBytes { p -> Void in
                mosquitto_will_set(mosquittoContext.mosquittoHandler, mqttWillOpts.topic.cCharArray,
                                   Int32(mqttWillOpts.payload.count), p,
                                   mqttWillOpts.qos, mqttWillOpts.retain)
            }
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
            mqttClient.connectTo(host: mqttConfig.host, port: mqttConfig.port, keepAlive: mqttConfig.keepAlive)
        }
        
        return mqttClient
    }
    
    private class func onConnectAdapter(_ callback: ((ReturnCode) -> ())!) -> ((_ returnCode: Int) -> ())! {
        return callback == nil ? nil : { (rawReturnCode: Int) in
            callback(ReturnCode(rawValue: rawReturnCode) ?? ReturnCode.unknown)
        }
    }
    
    private class func onDisconnectAdapter(_ callback: ((ReasonCode) -> ())!) -> ((_ reasonCode: Int) -> ())! {
        return callback == nil ? nil : { (rawReasonCode: Int) in
            callback(ReasonCode(rawValue: rawReasonCode) ?? ReasonCode.unknown)
        }
    }
    
    private class func onMessageAdapter(_ callback: ((MQTTMessage) -> ())!) -> ((UnsafePointer<mosquitto_message>) -> ())! {
        return callback == nil ? nil : { (rawMessage: UnsafePointer<mosquitto_message>) in
            let message = rawMessage.pointee
            // If there are issues with topic string, drop message on the floor
            let topic = String(cString: message.topic)
            let payload: Data? = message.payload != nil ?
                Data(bytes: message.payload, count: Int(message.payloadlen)) : nil
            let mqttMessage = MQTTMessage(messageId: Int(message.mid), topic: topic, payload: payload, qos: message.qos, retain: message.retain)
            callback(mqttMessage)
        }
    }
    
    private class func onSubscribeAdapter(_ callback: ((Int, Array<Int32>) -> ())!) -> ((Int, Int, UnsafePointer<Int32>) -> ())! {
        return callback == nil ? nil : { (messageId: Int, qosCount: Int, grantedQos: UnsafePointer<Int32>) in
            var grantedQosList = [Int32](repeating: Qos.at_least_once, count: qosCount)
            let _ = Array(0..<qosCount).reduce(grantedQos) { (qosPointer, index) in
                grantedQosList[index] = qosPointer.pointee
                return qosPointer.successor()
            }
            callback(messageId, grantedQosList)
        }
    }
}

public final class MQTTClient {
    public let clientId: String
    private let mosquittoContext: __MosquittoContext
    private let serialQueue: OperationQueue
    public private(set) var isRunning: Bool
    
    public var isConnected: Bool {
        return self.mosquittoContext.isConnected
    }
    
    private func addRequestToQueue(operation: @escaping (__MosquittoContext) -> ()) {
        let mosqContext = self.mosquittoContext
        serialQueue.addOperation {
            operation(mosqContext)
        }
    }
    
    internal init(mosquittoContext: __MosquittoContext, clientId: String) {
        self.mosquittoContext = mosquittoContext
        self.clientId = clientId
        self.isRunning = false
        self.serialQueue = OperationQueue()
        self.serialQueue.name = "MQTT Client Operation Queue (\(clientId))"
        self.serialQueue.maxConcurrentOperationCount = 1
    }
    
    deinit {
        disconnect()
        addRequestToQueue { mosqContext in
            mosquitto_context_cleanup(mosqContext)
        }
    }
    
    public func publish(_ payload: Data, topic: String, qos: Int32, retain: Bool, requestCompletion: ((MosqResult, Int) -> ())? = nil) {
        addRequestToQueue { mosqContext in
            var messageId: Int32 = 0
            let bytes = Array(payload)
            let mosqReturn = mosquitto_publish(mosqContext.mosquittoHandler, &messageId, topic.cCharArray, Int32(payload.count), bytes, qos, retain)
            requestCompletion?(MosqResult(rawValue: Int(mosqReturn)) ?? MosqResult.mosq_unknown, Int(messageId))
        }
    }
    
    public func publish(string payload: String, topic: String, qos: Int32, retain: Bool, requestCompletion: ((MosqResult, Int) -> ())? = nil) {
        if let payloadData = payload.data(using: .utf8) {
            publish(payloadData, topic: topic, qos: qos, retain: retain, requestCompletion: requestCompletion)
        }
    }
    
    public func subscribe(_ topic: String, qos: Int32, requestCompletion: ((MosqResult, Int) -> ())? = nil) {
        addRequestToQueue { mosqContext in
            var messageId: Int32 = 0
            let mosqReturn = mosquitto_subscribe(mosqContext.mosquittoHandler, &messageId, topic.cCharArray, qos)
            requestCompletion?(MosqResult(rawValue: Int(mosqReturn)) ?? MosqResult.mosq_unknown, Int(messageId))
        }
    }
    
    public func unsubscribe(_ topic: String, requestCompletion: ((MosqResult, Int) -> ())? = nil) {
        addRequestToQueue { mosqContext in
            var messageId: Int32 = 0
            let mosqReturn = mosquitto_unsubscribe(mosqContext.mosquittoHandler, &messageId, topic.cCharArray)
            requestCompletion?(MosqResult(rawValue: Int(mosqReturn)) ?? MosqResult.mosq_unknown, Int(messageId))
        }
    }
    
    public func connectTo(host: String, port: Int32, keepAlive: Int32, requestCompletion: ((MosqResult) -> ())? = nil) {
        self.isRunning = true
        addRequestToQueue { mosqContext in
            // mosquitto_connect should be called before mosquitto_loop_start.
            let mosqReturn = mosquitto_connect(mosqContext.mosquittoHandler, host, port, keepAlive)
            mosquitto_loop_start(mosqContext.mosquittoHandler)
            requestCompletion?(MosqResult(rawValue: Int(mosqReturn)) ?? MosqResult.mosq_unknown)
        }
    }
    
    public func reconnect(_ requestCompletion: ((MosqResult) -> ())? = nil) {
        self.isRunning = true
        addRequestToQueue { mosqContext in
            // mosquitto_reconnect should be called before mosquitto_loop_start.
            let mosqReturn = mosquitto_reconnect(mosqContext.mosquittoHandler)
            mosquitto_loop_start(mosqContext.mosquittoHandler)
            requestCompletion?(MosqResult(rawValue: Int(mosqReturn)) ?? MosqResult.mosq_unknown)
        }
    }
    
    public func disconnect(_ requestCompletion: ((MosqResult) -> ())? = nil) {
        guard isRunning == true
            else { requestCompletion?(.mosq_success); return }
        
        self.isRunning = false
        addRequestToQueue { mosqContext in
            let mosqReturn = mosquitto_disconnect(mosqContext.mosquittoHandler)
            mosquitto_loop_stop(mosqContext.mosquittoHandler, false)
            requestCompletion?(MosqResult(rawValue: Int(mosqReturn)) ?? MosqResult.mosq_unknown)
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
        return self.cString(using: .utf8)!
    }
}
