//
//  MatataCore.swift
//  MatataCore
//
//  Created by Jean-Daniel Dupas on 29/05/2021.
//

import CoreBluetooth

public enum Service {}

public extension Service {
    static let UUID = CBUUID(string: "6E400001-B5A3-F393-E0A9-E50E24DCCA9E")
    
    // characteristics
    static let writeCharacteristic = CBUUID(string: "6E400002-B5A3-F393-E0A9-E50E24DCCA9E")
    static let notifyCharacteristic = CBUUID(string: "6E400003-B5A3-F393-E0A9-E50E24DCCA9E")
    // static func handshake() -> Data { Data([0xfe, 0x07, 0x7e, 0x2, 0x2, 0x0, 0x0, 0x97, 0x77]) }
}
