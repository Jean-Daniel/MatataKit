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

public class Device: NSObject, Identifiable {
    
    internal let peripheral: CBPeripheral
    private unowned let owner: DeviceManager
    
    private var notify: CBCharacteristic?
    private var write: CBCharacteristic?
    
    private var packetQueue = WriteQueue()
    
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
                packetQueue.removeAll()
                // invalidate cached values
                notify = nil
                write = nil
            }
        }
    }

    // MARK: - Message Sending
    public func send(payload: [UInt8]) throws {
        try send(packet: IO.encode(payload, withLength: true))
    }
    
    // internal function
    func send(packet: Data) {
        // push packet in queue and try to send next
        packetQueue.push(packet: packet)
        sendPendingPackets()
    }
    
    private func sendPendingPackets() {
        // try to send next pending packet bytes
        guard !packetQueue.isEmpty, let write = write else { return }
        
        let mtu = peripheral.maximumWriteValueLength(for: .withResponse)
        packetQueue.send(mtu: mtu) {
            peripheral.writeValue($0, for: write, type: .withResponse)
            // Always wait for callback before sending next packet
            return SendResult(success: true, stop: true)
        }
    }
    
    // MARK: - Request Handling
    func handle(payload data: Data) {
        switch (data[0]) {
        case 0x06:
            if (data[1] == 0x7e) {
                handleHandshake(payload: data)
            } else {
                handle(response: data)
            }
        default:
            os_log("Received %d bytes: %@", data.count, data as NSData)
        }
    }
    
    // Response payload (starting by 0x06)
    func handle(response data: Data) {
        os_log("Received response of %d bytes: %@", data.count, data as NSData)
    }
    
    func handle(message msg: String) {
        os_log("Received message: %s", msg)
        
        if msg.hasPrefix("Car:[") {
            sendHandshake()
        }
    }
    
    // MARK: - Handshake
    func sendHandshake() {
        send(packet: try! IO.encode([0x07, 0x7e, 0x2, 0x2, 0x0, 0x0]))
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
            handle(payload: payload)
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
        sendPendingPackets()
    }
    
    public func peripheralIsReady(toSendWriteWithoutResponse peripheral: CBPeripheral) {
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
    
    override func handle(payload data: Data) {
        switch (data[0]) {
        case 0x04:
            handleStatus(payload: data)
        default:
            super.handle(payload: data)
        }
    }
    
    private func handleStatus(payload data: Data) {
        if data[1] == 0x87 && data.count == 3 {
            // implies in sensor mode
            if !isInSensorMode {
                isInSensorMode = true
            }
            
            // 0x01 means connected, 0x02 means No Bot.
            isBotConnected = data[2] == 0x01
            os_log("is bot connected: %s (%@)", String(describing: isBotConnected), data as NSData)
            return
        }
        else if data[1] == 0x88 && data.count == 3 {
            
            isInSensorMode = data[2] != 0x07
            
            switch (data[2]) {
            case 0:
                os_log("request success (%@)", data as NSData)
            case 1:
                os_log("request failure (%@)", data as NSData)
            case 7:
                os_log("not in sensor mode (%@)", data as NSData)
            default:
                os_log("unknown status code (%@)", data as NSData)
            }
            
            return
        }
        os_log("parse status message (%d bytes): %@", data.count, data as NSData)
    }
}
