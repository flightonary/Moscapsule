//
//  Moscapsule.swift
//  Moscapsule
//
//  Created by tonary on 2014/11/23.
//  Copyright (c) 2014年 flightonary. All rights reserved.
//

import Foundation

public func initialize() {
    mosquitto_lib_init()
}

public func cleanup() {
    mosquitto_lib_cleanup()
}

public class MqttClient {
    private var mosquittoHandler: COpaquePointer = COpaquePointer.null()

    public convenience init(clientId: String) {
        self.init(clientId: clientId, cleanSession: true)
    }

    public init(clientId: String, cleanSession: Bool) {
        mosquittoHandler = mosquitto_new(clientId.cStringUsingEncoding(NSUTF8StringEncoding)!,
                                         cleanSession, nil)

    }

    deinit {
        if mosquittoHandler != COpaquePointer.null() {
            mosquitto_destroy(mosquittoHandler)
        }
    }
}