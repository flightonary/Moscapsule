import XCTest
import Network
import Moscapsule


//
// These are fragile tests!!
// I know it's a bad practice but I'm not going to fix it.
//
class MoscapsuleTests: XCTestCase {
    
    var initFlag = false
    
    private static var _brokerReachable: Bool?
    private static func isBrokerReachable() -> Bool {
        if let cached = _brokerReachable { return cached }
        let semaphore = DispatchSemaphore(value: 0)
        var reachable = false
        let conn = NWConnection(host: "test.mosquitto.org", port: 1883, using: .tcp)
        conn.stateUpdateHandler = { state in
            switch state {
            case .ready:
                reachable = true
                semaphore.signal()
            case .failed, .cancelled:
                semaphore.signal()
            default:
                break
            }
        }
        conn.start(queue: .global())
        _ = semaphore.wait(timeout: .now() + 3)
        conn.cancel()
        _brokerReachable = reachable
        return reachable
    }

    override func setUpWithError() throws {
        try super.setUpWithError()
        try XCTSkipUnless(MoscapsuleTests.isBrokerReachable(), "test.mosquitto.org:1883 unreachable — skipping")
        if !initFlag {
            initFlag = true
            moscapsule_init()
        }
    }

    override func tearDown() {
        super.tearDown()
    }

    func testConnectToMQTTServer() {
        let clientId = "connect_test 1234567890abcdef"
        //XCTAssertTrue(clientId.characters.count > Int(MOSQ_MQTT_ID_MAX_LENGTH))
        let mqttConfig = MQTTConfig(clientId: clientId, host: "test.mosquitto.org", port: 1883, keepAlive: 60)
        
        mqttConfig.onConnectCallback = { returnCode in
            NSLog("Return Code is \(returnCode.description) (this callback is declared in swift.)")
        }
        mqttConfig.onDisconnectCallback = { reasonCode in
            NSLog("Reason Code is \(reasonCode.description) (this callback is declared in swift.)")
        }
        
        let mqttClient = MQTT.newConnection(mqttConfig)
        sleep(2)
        XCTAssertTrue(mqttClient.isConnected)
        mqttClient.disconnect()
        sleep(2)
        XCTAssertFalse(mqttClient.isConnected)
    }
    
    func testReconnect() {
        let clientId = "reconnect_test 1234"
        let mqttConfig = MQTTConfig(clientId: clientId, host: "test.mosquitto.org", port: 1883, keepAlive: 60)
        let mqttClient = MQTT.newConnection(mqttConfig, connectImmediately: false)
        XCTAssertFalse(mqttClient.isConnected)
        // first connecting
        mqttClient.connectTo(host: "test.mosquitto.org", port: 1883, keepAlive: 60)
        sleep(5)
        XCTAssertTrue(mqttClient.isConnected)
        // disconnecting
        mqttClient.disconnect()
        sleep(5)
        XCTAssertFalse(mqttClient.isConnected)
        // reconnecting again
        mqttClient.reconnect { mosqResult in
            print(mosqResult)
        }
        sleep(5)
        XCTAssertTrue(mqttClient.isConnected)
    }
    
    func testReconnectInRunning() {
        let clientId = "reconnect_test"
        let mqttConfig = MQTTConfig(clientId: clientId, host: "test.mosquitto.org", port: 1883, keepAlive: 60)
        let mqttClient = MQTT.newConnection(mqttConfig, connectImmediately: false)
        
        // first connecting
        mqttClient.connectTo(host: "test.mosquitto.org", port: 1883, keepAlive: 60)
        sleep(3)
        XCTAssertTrue(mqttClient.isConnected)
        // reconnecting again
        mqttClient.reconnect { mosqResult in
            print(mosqResult)
        }
        sleep(3)
        mqttClient.connectTo(host: "test.mosquitto.org", port: 1883, keepAlive: 60) { mosqResult in
            print(mosqResult)
        }
        sleep(3)
        XCTAssertTrue(mqttClient.isConnected)
    }
    
    func testPublishAndSubscribe() {
        let mqttConfigPub = MQTTConfig(clientId: "pub", host: "test.mosquitto.org", port: 1883, keepAlive: 60)
        var published = false
        let payload = "ほげほげ"
        let topic = "/moscapsule/testPublishAndSubscribe"
        mqttConfigPub.onPublishCallback = { messageId in
            NSLog("published (mid=\(messageId))")
            published = true
        }

        let mqttConfigSub = MQTTConfig(clientId: "sub", host: "test.mosquitto.org", port: 1883, keepAlive: 60)
        var subscribed = false
        var received = false
        mqttConfigSub.onSubscribeCallback = { (messageId, grantedQos) in
            NSLog("subscribed (mid=\(messageId),grantedQos=\(grantedQos))")
            subscribed = true
        }
        mqttConfigSub.onMessageCallback = { mqttMessage in
            received = true
            NSLog("MQTT Message received: payload=\(String(describing: mqttMessage.payloadString))")
            XCTAssertEqual(mqttMessage.payloadString!, payload, "Received message must be the same as published one!!")
        }
        
        let mqttClientPub = MQTT.newConnection(mqttConfigPub)
        let mqttClientSub = MQTT.newConnection(mqttConfigSub)
        mqttClientSub.subscribe(topic, qos: 2)
        sleep(2)
        mqttClientPub.publish(string: payload, topic: topic, qos: 2, retain: false)
        sleep(2)

        XCTAssertTrue(published)
        XCTAssertTrue(subscribed)
        XCTAssertTrue(received)

        mqttClientPub.disconnect()
        mqttClientSub.disconnect()
    }
    
    func testPublish() {
        let mqttConfigPub = MQTTConfig(clientId: "pub", host: "test.mosquitto.org", port: 1883, keepAlive: 60)
        var published = false
        let payload = "my message"
        let topic = "/moscapsule/testPublish"
        mqttConfigPub.onPublishCallback = { messageId in
            NSLog("published (mid=\(messageId))")
            published = true
        }
        
        let mqttClientPub = MQTT.newConnection(mqttConfigPub)
        mqttClientPub.publish(string: payload, topic: topic, qos: 0, retain: false)
        sleep(2)
        XCTAssertTrue(published)
        published = false
        
        mqttClientPub.publish(string: payload, topic: topic, qos: 1, retain: false)
        sleep(2)
        XCTAssertTrue(published)
        published = false
        
        mqttClientPub.publish(string: payload, topic: topic, qos: 2, retain: false)
        sleep(2)
        XCTAssertTrue(published)
        published = false
        
        let data = Data(bytes: [0x00, 0x01, 0x00, 0x00])
        mqttClientPub.publish(data, topic: topic, qos: 2, retain: false)
        sleep(2)
        XCTAssertTrue(published)
        published = false
        
        mqttClientPub.disconnect()
    }
    
    func testUnsubscribe() {
        let mqttConfig = MQTTConfig(clientId: "unsubscribe_test", host: "test.mosquitto.org", port: 1883, keepAlive: 60)
        var subscribed = false
        var unsubscribed = false
        mqttConfig.onSubscribeCallback = { (messageId, grantedQos) in
            NSLog("subscribed (mid=\(messageId),grantedQos=\(grantedQos))")
            subscribed = true
        }
        mqttConfig.onUnsubscribeCallback = { messageId in
            NSLog("unsubscribed (mid=\(messageId))")
            unsubscribed = true
        }
        
        let mqttClient = MQTT.newConnection(mqttConfig)
        mqttClient.subscribe("testTopic", qos: 2)
        sleep(2)
        mqttClient.unsubscribe("testTopic")
        sleep(2)
        
        XCTAssertTrue(subscribed)
        XCTAssertTrue(unsubscribed)
        mqttClient.disconnect()
    }
    
    func testAutoDisconnect() {
        var disconnected: Bool = false

        let closure = { () -> Void in
            let mqttConfig = MQTTConfig(clientId: "auto_disconnect_test", host: "test.mosquitto.org", port: 1883, keepAlive: 60)
            mqttConfig.onDisconnectCallback = { reasonCode in
                disconnected = true
            }
            let _ = MQTT.newConnection(mqttConfig)
        }
        closure()
        sleep(3)
        
        XCTAssertTrue(disconnected)
    }

    func testCompletion() {
        let mqttConfig = MQTTConfig(clientId: "completion_test", host: "test.mosquitto.org", port: 1883, keepAlive: 60)
        mqttConfig.onPublishCallback = { messageId in
            NSLog("published (mid=\(messageId))")
        }
        mqttConfig.onSubscribeCallback = { (messageId, grantedQos) in
            NSLog("subscribed (mid=\(messageId),grantedQos=\(grantedQos))")
        }
        mqttConfig.onUnsubscribeCallback = { messageId in
            NSLog("unsubscribed (mid=\(messageId))")
        }
        var published = false
        var subscribed = false
        var unsubscribed = false

        let mqttClient = MQTT.newConnection(mqttConfig)
        mqttClient.publish(string: "msg", topic: "topic", qos: 2, retain: false) { mosqReturn, messageId in
            published = true
            NSLog("publish completion: mosq_return=\(mosqReturn.rawValue) messageId=\(messageId)")
        }
        mqttClient.awaitRequestCompletion()
        XCTAssertTrue(published)

        mqttClient.subscribe("testTopic", qos: 2) { mosqReturn, messageId in
            subscribed = true
            NSLog("subscribe completion: mosq_return=\(mosqReturn.rawValue) messageId=\(messageId)")
        }
        mqttClient.awaitRequestCompletion()
        XCTAssertTrue(subscribed)

        mqttClient.unsubscribe("testTopic") { mosqReturn, messageId in
            unsubscribed = true
            NSLog("unsubscribe completion: mosq_return=\(mosqReturn.rawValue) messageId=\(messageId)")
        }
        mqttClient.awaitRequestCompletion()
        XCTAssertTrue(unsubscribed)

        sleep(3)
        mqttClient.disconnect()
    }

    func testServerCertificate() {
        let mqttConfig = MQTTConfig(clientId: "server_cert_test", host: "test.mosquitto.org", port: 8883, keepAlive: 60)
        mqttConfig.onConnectCallback = { returnCode in
            NSLog("Return Code is \(returnCode.description) (this callback is declared in swift.)")
        }

#if SWIFT_PACKAGE
        let bundleURL = URL(fileURLWithPath: Bundle.module.path(forResource: "cert", ofType: "bundle")!)
#else
        let bundleURL = URL(fileURLWithPath: Bundle(for: type(of: self)).path(forResource: "cert", ofType: "bundle")!)
#endif
        let certFile = bundleURL.appendingPathComponent("mosquitto.org.crt").path

        mqttConfig.mqttServerCert = MQTTServerCert(cafile: certFile, capath: nil)
        //mqttConfig.mqttTlsOpts = MQTTTlsOpts(tls_insecure: true, cert_reqs: .SSL_VERIFY_NONE, tls_version: nil, ciphers: nil)

        let mqttClient = MQTT.newConnection(mqttConfig)
        sleep(10) // so long time needed...
        XCTAssertTrue(mqttClient.isConnected)
        mqttClient.disconnect()
        sleep(2)
        XCTAssertFalse(mqttClient.isConnected)
        XCTAssertFalse(mqttClient.isRunning)
    }
    
    func testAbnormalOperation() {
        let clientId = "reconnect_test 1234"
        let topic = "/moscapsule/testAbnormalOperation"
        let payload = "payload"
        let mqttConfig = MQTTConfig(clientId: clientId, host: "test.mosquitto.org", port: 1883, keepAlive: 60)
        let mqttClient = MQTT.newConnection(mqttConfig, connectImmediately: false)
        
        // do pub/sub in no-runnning state
        mqttClient.subscribe(topic, qos: 2)
        mqttClient.publish(string: payload, topic: topic, qos: 2, retain: false)

        // first connecting
        mqttClient.connectTo(host: "test.mosquitto.org", port: 1883, keepAlive: 60)
        // disconnecting
        mqttClient.disconnect()
        sleep(2)
        XCTAssertFalse(mqttClient.isRunning)
        
        // do pub/sub in no-runnning state
        mqttClient.subscribe(topic, qos: 2)
        mqttClient.publish(string: payload, topic: topic, qos: 2, retain: false)
    }
}
