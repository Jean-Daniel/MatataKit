//
//  Coder.swift
//  MatataCore
//
//  Created by Jean-Daniel Dupas on 29/05/2021.
//

import Foundation

public enum IO {}

public extension IO {
    
    enum Error: Swift.Error {
        case noData
        case invalidHeader
        
        case invalidCRC
        case invalidData
        case unexpectedEnd
    }
    
    private static func crc16(_ iArr: [UInt8]) -> UInt16 {
        var var3: UInt16 = 0xffff;
        for i2 in iArr {
            var3 = var3.byteSwapped ^ UInt16(i2);
            var3 = var3 ^ (var3 & 255) >> 4;
            var3 = var3 ^ (var3 << 12);
            var3 = var3 ^ (var3 & 255) << 5;
        }
        return var3;
    }
    
    static func encode(_ data: [UInt8]) throws -> [UInt8] {
        if (data.isEmpty) {
            throw Error.noData
        }
        
        let crc16 = crc16(data)
        // append CRC16 to input data
        var checkedData = data
        checkedData.append(UInt8(crc16 >> 8))
        checkedData.append(UInt8(crc16 & 0xff))
        
        var encoded = [UInt8]()
        encoded.append(254) // header
        for value in checkedData {
            if (value == 254) {
                encoded.append(253)
                encoded.append(222)
            } else if (value == 253) {
                encoded.append(253)
                encoded.append(221)
            } else {
                encoded.append(value)
            }
        }
        return encoded;
    }
    
    static func decode(_ data: [UInt8]) throws -> [UInt8] {
        if (data.isEmpty) {
            throw Error.noData
        }
        if (data[0] != 254) {
            throw Error.invalidHeader
        }
        
        // decode data
        var payload = [UInt8]()
        var iter = data.dropFirst().makeIterator()
        while let value = iter.next() {
            if value == 253 {
                guard let next = iter.next() else { throw Error.unexpectedEnd }
                switch (next) {
                case 222:
                    payload.append(254)
                case 221:
                    payload.append(253)
                default:
                    throw Error.invalidData
                }
            } else {
                payload.append(value)
            }
        }
        
        guard payload.count > 2 else { throw Error.invalidData }
        // extract CRC
        let crc: UInt16 = UInt16(payload.popLast()!) | (UInt16(payload.popLast()!) << 8)
        // check CRC
        guard crc16(payload) == crc else { throw Error.invalidCRC }
        
        return payload
    }
    
}
