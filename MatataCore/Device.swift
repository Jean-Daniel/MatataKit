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
                // invalidate cached values
                notify = nil
                write = nil
            }
        }
    }

    func handle(payload data: Data) {
        switch (data[0]) {
        case 0x06:
            handleHandshake(payload: data)
        default:
            os_log("Received %d bytes: %@", data.count, data as NSData)
        }
    }
    
    func handle(message msg: String) {
        os_log("Received message: %s", msg)
        
        if msg.hasPrefix("Car:[") {
            sendHandshake()
        }
    }
    
    func sendHandshake() {
        // On connect, start handshake
        guard let write = self.write else {
            os_log("#Error send handshake requested but no write characteristic found")
            return owner.disconnect(device: self)
        }
        // TODO: schedule write on write queue.
        //            os_log("mtu %d", peripheral.maximumWriteValueLength(for: .withResponse))
        peripheral.writeValue(try! IO.encode([0x07, 0x7e, 0x2, 0x2, 0x0, 0x0]), for: write, type: .withResponse)
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
            os_log("#Error failed to parse handshake response: %@", String(describing: error))
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
            sendHandshake()
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
}


public class Bot : Device {
    
}

public class Controller : Device {
    
    @Published
    public private(set) var isInSensorMode: Bool = true
    
    override func handle(payload data: Data) {
        switch (data[0]) {
        case 0x04:
            handleStatus(payload: data)
        default:
            super.handle(payload: data)
        }
    }
    
    private func handleStatus(payload data: Data) {
        if data.count == 3 && data[1] == 0x88 {
            isInSensorMode = data[2] != 0x07
            return
        }
        if data[1] == 0x87 {
            // bot status ?
        }
        os_log("parse status message (%d bytes): %@", data.count, data as NSData)
    }
}
