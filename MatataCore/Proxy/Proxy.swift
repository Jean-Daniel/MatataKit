//
//  DeviceProxy.swift
//  MatataCore
//
//  Created by Jean-Daniel Dupas on 15/01/2022.
//

import os
import Combine
import Foundation
import CoreBluetooth

@MainActor
public class BluetoothProxy: ObservableObject {

  public enum State {
    case disconnected
    case scanning
    case discovering
    case advertising
    case connected
  }

  internal var upstream: ProxyCentral! = nil
  internal var downstream: ProxyPeripheral! = nil

  @Published public internal(set) var state: State = .disconnected

  public init() {
    upstream = ProxyCentral(self)
    downstream = ProxyPeripheral(self)
  }

  public func start(services: [CBUUID]) {
    guard (state == .disconnected) else { return }
    // Start scanning for device
    upstream.scan(services: services)
  }

  public func stop() {
    disconnect()
  }

  func disconnect() {
    os_log("#Info disconnect()")
    guard state != .disconnected else { return }
    state = .disconnected

    downstream.invalidate()
    upstream.invalidate()
  }
}

// MARK: - Upstream API
extension BluetoothProxy {

  // Upstream peripheral is ready -> start to advertise it
  internal func advertise(name: String, services: [CBService]) {
    guard state == .discovering else {
      os_log("#Warning trying to advertise while state is not discovering")
      return
    }
    state = .advertising
    downstream.advertise(name: name, services: services)
  }


}
