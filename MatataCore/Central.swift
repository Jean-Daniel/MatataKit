//
//  MatataCentral.swift
//  MatataCore
//
//  Created by Jean-Daniel Dupas on 30/05/2021.
//

import os
import Combine
import Foundation
import CoreBluetooth

public class DeviceManager: NSObject {
    
    private var devices = [UUID:Device]()
    private var centralManager: CBCentralManager!
    
    @Published
    public private(set) var state: CBManagerState  = .unknown
    
    public var authorization: CBManagerAuthorization { centralManager.authorization }

    @available(macOS 10.15, *)
    public class var authorization: CBManagerAuthorization { CBManager.authorization }
    
    @Published
    public private(set) var isScanning: Bool = false
    
    private var _isScanningObserver: Cancellable?
    
    // TODO: publish connected devices
    
    
    public override init() {
        super.init()
        // keep it simple by using main queue for event dispatch
        centralManager = CBCentralManager(delegate:self, queue: DispatchQueue.main)
        // Expose central manager scanning state
        _isScanningObserver = centralManager.publisher(for: \.isScanning).assign(to: \.isScanning, on: self)
    }
    
    // MARK: Scan Management
    public func startScanning() {
        guard centralManager.state == .poweredOn, !centralManager.isScanning else {
            return
        }
        
        centralManager.scanForPeripherals(withServices: [Service.UUID], options: nil)
    }
    
    public func stopScanning() {
        guard centralManager.state == .poweredOn else {
            return
        }
        centralManager.stopScan()
    }

    // MARK: Devices Lifecycle
    private func connect(peripheral: CBPeripheral) {
        // skip duplicated
        guard devices[peripheral.identifier] == nil else {
            os_log("Discovered duplicated peripheral: %s (%s)", String(describing: peripheral.name), peripheral.identifier.description)
            return
        }
        
        os_log("Discovered %s", String(describing: peripheral.name))
            
        // Save a local copy of the peripheral, so CoreBluetooth doesn't get rid of it.
        devices[peripheral.identifier] = Device(owner: self, peripheral: peripheral)
        // And finally, connect to the peripheral.
        centralManager.connect(peripheral, options: nil)
    }
    
    internal func disconnect(device: Device) {
        disconnect(deviceId: device.id)
    }
    
    internal func disconnect(deviceId: UUID) {
        guard let device = devices.removeValue(forKey: deviceId) else { return }
        
        device.state = .disconnected
        centralManager.cancelPeripheralConnection(device.peripheral)
    }

}

extension DeviceManager: CBCentralManagerDelegate {
    /*
     *  centralManagerDidUpdateState is a required protocol method.
     *  Usually, you'd check for other states to make sure the current device supports LE, is powered on, etc.
     *  In this instance, we're just using it to wait for CBCentralManagerStatePoweredOn, which indicates
     *  the Central is ready to be used.
     */
    public func centralManagerDidUpdateState(_ central: CBCentralManager) {
        self.state = central.state
        
        if central.state.rawValue < CBManagerState.poweredOn.rawValue {
            isScanning = false
            
            // invalidate all devices.
            devices.values.forEach { $0.state = .disconnected }
            devices.removeAll()
        } else {
            // on powered on -> refresh connected devices
            let connectedPeripherals = centralManager.retrieveConnectedPeripherals(withServices: [Service.UUID])
            for connected in connectedPeripherals where devices[connected.identifier] == nil {
                connect(peripheral: connected)
            }
        }
    }
    
    /*
     *  This callback comes whenever a peripheral that is advertising the transfer serviceUUID is discovered.
     *  We check the RSSI, to make sure it's close enough that we're interested in it, and if it is,
     *  we start the connection process
     */
    public func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral,
                        advertisementData: [String: Any], rssi RSSI: NSNumber) {
        // Reject if the signal strength is too low to attempt data transfer.
        // Change the minimum RSSI value depending on your app’s use case.
        guard RSSI.intValue >= -90
            else {
                os_log("Discovered perhiperal not in expected range, at %d", RSSI.intValue)
                return
        }
        
        connect(peripheral: peripheral)
    }

    /*
     *  We've connected to the peripheral, now we need to discover the services and characteristics to find the 'transfer' characteristic.
     */
    public func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        os_log("Peripheral Connected")
        devices[peripheral.identifier]?.state = .connected
    }
    
    /*
     *  Once the disconnection happens, we need to clean up our local copy of the peripheral
     */
    public func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        guard let device = devices[peripheral.identifier] else { return }
        os_log("Peripheral Disconnected: %s (%s)", device.id.description, String(describing: error))
        disconnect(device: device)
    }
    
    /*
     *  If the connection fails for whatever reason, we need to deal with it.
     */
    public func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        os_log("Failed to connect to %@. %s", peripheral, String(describing: error))
        disconnect(deviceId: peripheral.identifier)
    }
}
