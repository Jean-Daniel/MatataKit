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

    private let mgr = DeviceManager()
    private var _stateObserver: Cancellable?
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        
        // Observer Manager state
        _stateObserver = mgr.$state.sink(receiveValue: self.centralStateDidChange)
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    private func centralStateDidChange(_ state: CBManagerState) {
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

