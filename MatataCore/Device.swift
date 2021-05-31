//
//  Device.swift
//  MatataCore
//
//  Created by Jean-Daniel Dupas on 30/05/2021.
//

import os
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
                if let notify = notify, notify.isNotifying {
                    peripheral.setNotifyValue(false, for: notify)
                }
            }
        }
    }
    
    /*
     *  Call this when things either go wrong, or you're done with the connection.
     *  This cancels any subscriptions if there are any, or straight disconnects if not.
     *  (didUpdateNotificationStateForCharacteristic will cancel the connection if a subscription is involved)
     */
//    internal func invalidate() {
//       owner.disconnect(device: self)
//    }
    
//    private var _connected: Bool = false
//    internal func onConnect() {
//        if (!_connected) {
//            _connected = true
//            os_log("connected: %s", peripheral.name ?? "-")
//            peripheral.discoverServices([MatataService.UUID])
//        }
//    }
}

extension Device: CBPeripheralDelegate {
    
}
