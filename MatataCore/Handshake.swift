//
//  Handshake.swift
//  MatataCore
//
//  Created by Jean-Daniel Dupas on 29/05/2021.
//

import Foundation

public enum Handshake {}

public extension Handshake {
    
    enum Response {
        case ok
        case botNotSupported
        case deviceNotSupported
        case controllerNotInSensorMode
        case deviceVersionNotSupported
    }

    static func parse(response: [UInt8]) throws -> Response {
        let payload = try IO.decode(response)
        if (payload.count == 5) {
            if payload[1] == 126 {
                if payload[3] != 0 {
                    return .botNotSupported // Please upgrade the MatataBot which is connected to this MatataCon
                }
                if payload[4] != 0 {
                    return .deviceVersionNotSupported // The firmware version does not match the version supported by the extension
                }
                return .ok
            }
        } else if payload == [0x4, 0x88, 0x7] {
            return .controllerNotInSensorMode // The matatacon is not in sensor mode
        }
        return .deviceNotSupported // The firmware version does not match the version supported by the extension
    }
}
