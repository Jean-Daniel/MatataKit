//
//  DeviceManager.swift
//  MatataCode
//
//  Created by Jean-Daniel Dupas on 29/12/2021.
//

import Combine
import MatataCore
import CoreBluetooth
import SwiftUI

extension DispatchTimeInterval {
  static let scanDuration: DispatchTimeInterval = .seconds(5)
}

@MainActor
protocol DevicesScanner: ObservableObject {

  associatedtype Device : DeviceProtocol

  static var authorization: CBManagerAuthorization { get }

  var state: CBManagerState { get }

  var isScanning: Bool { get }

  func startScan(for duration: DispatchTimeInterval) throws
  func stopScan()

  func scan(for duration: DispatchTimeInterval) async throws

  var devices: [Device] { get }
}

extension MatataCentral: DevicesScanner {}

@MainActor
protocol DeviceProtocol: ObservableObject, Identifiable {

  var id: UUID { get }
  var name: String { get }
  var state: MatataDevice.State { get }

  func connect() throws
  func disconnect(unregister: Bool) throws
}

extension MatataDevice: DeviceProtocol {

}

// MARK: - Design Time
class DesignTimeScanner : DevicesScanner {
  static var authorization: CBManagerAuthorization = .allowedAlways

  let state: CBManagerState = .poweredOn

  @Published
  private(set) var isScanning: Bool = false

  private var scanTimeout: DispatchWorkItem? = nil
  private var scanListeners = [CheckedContinuation<Void, Never>]()

  func startScan(for duration: DispatchTimeInterval) throws {
    if (isScanning) {
      return
    }

    // If scan operation in progress -> return
    guard scanTimeout == nil else { return }

    // Start scan operation
    isScanning = true

    // schedule timeout after duration
    scanTimeout = DispatchWorkItem { self.stopScan() }
    DispatchQueue.main.asyncAfter(wallDeadline: DispatchWallTime.now() + duration,
                                  execute: scanTimeout!)
  }

  func stopScan() {
    guard let scanTimeout = scanTimeout else { return }
    // cancel timeout
    self.scanTimeout = nil
    scanTimeout.cancel()

    // actually stop the scan
    isScanning = false

    // resume all waiting continuations.
    scanListeners.forEach { $0.resume() }
    scanListeners.removeAll(keepingCapacity: false)
  }
  
  func scan(for duration: DispatchTimeInterval) async throws {
    try startScan(for: duration)

    // wait until stop scan is called
    await withCheckedContinuation { continuation in
      self.scanListeners.append(continuation)
    }
  }

  @Published
  var devices = [DesignTimeDevice]()

  init() {
    self.devices.append(DesignTimeDevice(central: self))
    self.devices.append(DesignTimeDevice(central: self))
  }

  fileprivate func remove(device: DesignTimeDevice) {
    devices.removeAll { $0 === device }
  }
}

class DesignTimeDevice: DeviceProtocol {

  unowned let central: DesignTimeScanner?

  let id: UUID = UUID()

  @Published
  var state: MatataDevice.State

  let name: String = "MatataBot"

  init(central: DesignTimeScanner? = nil, state: MatataDevice.State = .disconnected) {
    self.central = central
    self.state = state
  }

  func connect() throws {
    state = .connected
  }
  
  func disconnect(unregister: Bool) throws {
    state = .disconnected
    if (unregister) {
      central?.remove(device: self)
    }
  }
}
