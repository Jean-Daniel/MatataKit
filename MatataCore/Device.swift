//
//  Device.swift
//  MatataCore
//
//  Created by Jean-Daniel Dupas on 30/05/2021.
//

import os
import Combine
import Foundation
import CoreBluetooth

enum RequestError: Error {
    case deviceNotConnected
    case requestFailure
    case notInSensorMode
    case unsupportedStatus
}

/*
Packet lifecycle:
 - send payload
 - wait answer -> call continuation -> send next packet
*/
public class Device: NSObject, Identifiable {
    
    internal let peripheral: CBPeripheral
    private unowned let owner: DeviceManager
    
    private var notify: CBCharacteristic?
    private var write: CBCharacteristic?
    
    // MARK: -
    init(owner: DeviceManager, peripheral: CBPeripheral) {
        self.owner = owner
        self.peripheral = peripheral
        
        super.init()
        
        peripheral.delegate = self
    }
    
    public var id: UUID { peripheral.identifier }

    public enum State {
        case connecting
        case connected
        case disconnected
    }
    
    public internal(set) var state: State = .connecting
    {
        didSet {
            switch (state) {
            case .connecting:
                break
                
            case .connected:
                peripheral.discoverServices([Service.UUID])
                
            case .disconnected:
                peripheral.delegate = nil
                if peripheral.state == .connected, let notify = notify, notify.isNotifying {
                    peripheral.setNotifyValue(false, for: notify)
                }
                responseContinuation = nil
                packetQueue.removeAll()
                // invalidate cached values
                notify = nil
                write = nil
            }
        }
    }

    // MARK: - Message Sending
    
    private var packetQueue = WriteQueue()
    
    // can send if no pending continuation and ready to send.
    private var isReadyToSend: Bool = true
    private var responseContinuation: Continuation?
    
    private var canSend: Bool { isReadyToSend && responseContinuation == nil }
    
    public func send(payload: [UInt8], continuation: @escaping Continuation) throws {
        try send(packet: IO.encode(payload, withLength: true), continuation: continuation)
    }
    
    // internal function
    private func send(packet: Data, continuation: @escaping Continuation) {
        guard peripheral.state == .connected else {
            continuation(.failure(RequestError.deviceNotConnected))
            return
        }
        // push packet in queue and try to send next
        packetQueue.push(packet: packet, continuation: continuation)
        sendPendingPackets()
    }
    
    private func sendPendingPackets() {
        // try to send next pending packet bytes
        guard canSend, !packetQueue.isEmpty, let write = write else { return }
        
        let mtu = peripheral.maximumWriteValueLength(for: .withResponse)
        assert(responseContinuation == nil)
        responseContinuation = packetQueue.send(mtu: mtu) {
            peripheral.writeValue($0, for: write, type: .withResponse)
            // Always wait for callback before sending next packet
            return SendResult(success: true, stop: true)
        }
    }
    
    // MARK: - Request Handling
    func handle(payload: Data) -> Result<Data, Error>? {
        return .success(payload)
    }
    
    func handle(message msg: String) {
        os_log("Received message: %s", msg)
        
        if msg.hasPrefix("Car:[") {
            sendHandshake()
        }
    }
    
    // MARK: - Handshake
    func sendHandshake() {
        send(packet: try! IO.encode([0x07, 0x7e, 0x2, 0x2, 0x0, 0x0])) { result in
            if case .success(let payload) = result {
                self.handleHandshake(payload: payload)
            }
        }
    }
    
    private func handleHandshake(payload data: Data) {
        do {
            switch try Handshake.parse(payload: data) {
            case .ok:
                os_log("Handshake OK")
                return
            case .botNotSupported:
                os_log("#Error Bot must be upgraded")
                break
            case .deviceVersionNotSupported:
                os_log("#Error Device version not supported")
                break
            }
        } catch {
            os_log("#Error failed to parse handshake response: %@ (%@)", String(describing: error), data as NSData)
        }
        owner.disconnect(device: self)
    }
}

extension Device: CBPeripheralDelegate {
    
    /*
     *  The peripheral letting us know when services have been invalidated.
     */
    public func peripheral(_ peripheral: CBPeripheral, didModifyServices invalidatedServices: [CBService]) {
        for service in invalidatedServices where service.uuid == Service.UUID {
            os_log("Transfer service is invalidated - rediscover services")
            peripheral.discoverServices([Service.UUID])
        }
    }
    
    /*
     *  The Transfer Service was discovered
     */
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let error = error {
            os_log("Error discovering services: %s", error.localizedDescription)
            return owner.disconnect(device: self)
        }
        
        // Loop through the newly filled peripheral.services array, just in case there's more than one.
        guard let peripheralServices = peripheral.services else { return }
        for service in peripheralServices where service.uuid == Service.UUID {
            peripheral.discoverCharacteristics([
                Service.writeCharacteristic,
                Service.notifyCharacteristic
            ], for: service)
        }
    }
    
    /*
     *  The Transfer characteristic was discovered.
     *  Once this has been found, we want to subscribe to it, which lets the peripheral know we want the data it contains.
     */
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        // Deal with errors (if any).
        if let error = error {
            os_log("#Error Error discovering characteristics: %s", error.localizedDescription)
            return owner.disconnect(device: self)
        }
        
        // Again, we loop through the array, just in case and check if it's the right one
        guard let serviceCharacteristics = service.characteristics else { return }
        for characteristic in serviceCharacteristics {
            switch (characteristic.uuid) {
            
            case Service.notifyCharacteristic:
                guard characteristic.properties.contains(.notify) else {
                    os_log("#Error notify characteristic does not has .notify property")
                    return owner.disconnect(device: self)
                }
                self.notify = characteristic
                // Subscribe to notify channel.
                peripheral.setNotifyValue(true, for: characteristic)
                
            case Service.writeCharacteristic:
                guard characteristic.properties.contains(.write) else {
                    os_log("#Error notify characteristic does not has .write property")
                    return owner.disconnect(device: self)
                }
                self.write = characteristic
                
            default:
                os_log("#Warning unsupported characteristic UUID: %@", characteristic.uuid)
                break
            }
        }
        // Sanity check
        guard self.write != nil, self.notify != nil else {
            os_log("#Error missing required characteristics. device not usable")
            return owner.disconnect(device: self)
        }
    }
    
    /*
     *  The peripheral letting us know whether our subscribe/unsubscribe happened or not
     */
    public func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        // Deal with errors (if any)
        if let error = error {
            os_log("Error changing notification state: %s", error.localizedDescription)
            return
        }
        
        // Exit if it's not the transfer characteristic
        guard characteristic.uuid == Service.notifyCharacteristic else {
            os_log("#Warning Notification on unsupported characteristic: %@", characteristic)
            return
        }
        
        if characteristic.isNotifying {
            // Notification has started
            os_log("Notification began on %@", characteristic)
        } else {
            // Notification has stopped, so disconnect from the peripheral
            os_log("Notification stopped on %@. Disconnecting", characteristic)
            owner.disconnect(device: self)
        }
    }
    
    /*
     *   This callback lets us know more data has arrived via notification on the characteristic
     */
    public func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        // Deal with errors (if any)
        if let error = error {
            os_log("Error discovering characteristics: %s", error.localizedDescription)
            return owner.disconnect(device: self)
        }
        
        guard let data = characteristic.value, data.count > 0 else { return }
        
        // 0xfe048702b211
        if data[0] == 0xfe {
            guard let payload = try? IO.decode(data) else {
                os_log("#Error failed to decode packet: %@", data as NSData)
                return
            }
            if let result = handle(payload: payload) {
                os_log("Received payload: %s", String(describing: result))
                responseContinuation?(result)
                responseContinuation = nil
                sendPendingPackets()
            }
        } else {
            guard let message = String(data: data, encoding: .utf8) else {
                os_log("#Error failed to decode packet: %@", data as NSData)
                return
            }
            handle(message: message)
        }
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            os_log("Error sending packet: %s", error.localizedDescription)
            return owner.disconnect(device: self)
        }
        // previous packet sent, try to send more data
        isReadyToSend = true
        sendPendingPackets()
    }
    
    public func peripheralIsReady(toSendWriteWithoutResponse peripheral: CBPeripheral) {
        isReadyToSend = true
        sendPendingPackets()
    }
}


public class Bot : Device {
    
}

public class Controller : Device {
       
    @Published
    public private(set) var isInSensorMode: Bool = true
    
    @Published
    public private(set) var isBotConnected: Bool = false
    
    override func handle(payload: Data) -> Result<Data, Error>? {
        switch (payload[0]) {
        case 0x04:
            return handleStatus(payload: payload)
        default:
            return super.handle(payload: payload)
        }
    }
    
    private func handleStatus(payload: Data) -> Result<Data, Error>? {
        if payload[1] == 0x87 && payload.count == 3 {
            // implies in sensor mode
            if !isInSensorMode {
                isInSensorMode = true
            }
            
            // 0x01 means connected, 0x02 means No Bot.
            isBotConnected = payload[2] == 0x01
            os_log("is bot connected: %s (%@)", String(describing: isBotConnected), payload as NSData)
            // status message handled
            return nil
        }
        else if payload[1] == 0x88 && payload.count == 3 {
            
            isInSensorMode = payload[2] != 0x07
            
            switch (payload[2]) {
            case 0:
                os_log("request success (%@)", payload as NSData)
                return .success(Data())
            case 1:
                os_log("request failure (%@)", payload as NSData)
                return .failure(RequestError.requestFailure)
            case 7:
                os_log("not in sensor mode (%@)", payload as NSData)
                return .failure(RequestError.notInSensorMode)
            default:
                os_log("unknown status code (%@)", payload as NSData)
                return .failure(RequestError.unsupportedStatus)
            }
        }
        os_log("unhandled status message (%d bytes): %@", payload.count, payload as NSData)
        return .success(payload)
    }
}
