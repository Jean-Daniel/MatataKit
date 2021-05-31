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
        case deviceVersionNotSupported
    }

    static func parse(payload: Data) throws -> Response {
        guard payload.count == 5, payload[1] == 0x7e else { throw IO.Error.invalidData }
        
        if payload[3] != 0 {
            return .botNotSupported // Please upgrade the MatataBot which is connected to this MatataCon
        }
        if payload[4] != 0 {
            return .deviceVersionNotSupported // The firmware version does not match the version supported by the extension
        }
        return .ok
    }
}
