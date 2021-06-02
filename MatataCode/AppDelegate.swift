//
//  AppDelegate.swift
//  MatataCode
//
//  Created by Jean-Daniel Dupas on 29/05/2021.
//

import os
import Cocoa
import Combine
import MatataCore
import CoreBluetooth

@main
class AppDelegate: NSObject, NSApplicationDelegate {

    @IBOutlet var window: NSWindow!
    
    @IBOutlet var scanButton: NSButton!
    @IBOutlet var scanningIndicator: NSProgressIndicator!
    
    
    private let mgr = DeviceManager()
    private var _observers = Set<AnyCancellable>()
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        
        // Observer Manager state
        mgr.$state.sink(receiveValue: self.centralStateDidChange).store(in: &_observers)
        
        mgr.$isScanning.sink { [weak self] in
            guard let self = self else { return }
            self.scanButton.title = $0 ? "Stop Scanning" : "Start Scanning"
            if $0 { self.scanningIndicator.startAnimation(nil) } else { self.scanningIndicator.stopAnimation(nil) }
        }.store(in: &_observers)
        
        mgr.$connectedDevices.sink {
            os_log("connected devices: %@", $0)
        }.store(in: &_observers)
    }

    @IBAction
    func toggleScanning(_ sender: Any) {
        if (mgr.isScanning) {
            mgr.stopScanning()
        } else if (mgr.state == .poweredOn) {
            mgr.startScanning()
        }
    }
    
    var counter: UInt8 = 1
    @IBAction
    func sendRainbow(_ sender: NSButton) {
        // try? mgr.connectedDevices.first?.send(payload: [0x18, 0x05, 0x05, 0x01])
        
        guard let device = mgr.connectedDevices.first else { return }
        
        sender.isEnabled = false
        try? device.send(payload: [0x18, 0x06, counter]) { result in
            sender.isEnabled = true
        }
        counter = (counter + 1)
        if counter > 6 { counter = 1 }
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    private func centralStateDidChange(_ state: CBManagerState) {
        scanButton.isEnabled = state == .poweredOn
        
        switch state {
        case .poweredOn:
            // ... so start working with the peripheral
            os_log("CBManager is powered on")
        case .poweredOff:
            os_log("CBManager is not powered on")
            // In a real app, you'd deal with all the states accordingly
            return
        case .resetting:
            os_log("CBManager is resetting")
            // In a real app, you'd deal with all the states accordingly
            return
        case .unauthorized:
            // In a real app, you'd deal with all the states accordingly
            switch mgr.authorization {
            case .denied:
                os_log("You are not authorized to use Bluetooth")
            case .restricted:
                os_log("Bluetooth is restricted")
            default:
                os_log("Unexpected authorization")
            }
            return
        case .unknown:
            os_log("CBManager state is unknown")
            // In a real app, you'd deal with all the states accordingly
            return
        case .unsupported:
            os_log("Bluetooth is not supported on this device")
            // In a real app, you'd deal with all the states accordingly
            return
        @unknown default:
            os_log("A previously unknown central manager state occurred")
            // In a real app, you'd deal with yet unknown cases that might occur in the future
            return
        }
    }

}

