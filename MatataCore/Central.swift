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

// using class until we get a clean way to get a ref to a value stored in a Map
private class Peripheral {
  let device: MatataDevice

  init(_ device: MatataDevice) {
    self.device = device
  }
}

enum MatataCentralError: Error {
  case deviceBusy
  case invalidState
  case unregistredDevice
}

@MainActor
public class MatataCentral: NSObject, ObservableObject {

  private var centralManager: CBCentralManager!

  private var _peripherals = [UUID:Peripheral]()

  // MARK: - Authorization
#if os(macOS)
  public var authorization: CBManagerAuthorization { centralManager.authorization }
#endif

  @available(macOS 10.15, *)
  public class var authorization: CBManagerAuthorization { CBManager.authorization }

  // MARK: State
  @Published
  public private(set) var state: CBManagerState = .unknown

  @Published
  public private(set) var devices = [MatataDevice]()


  // MARK: - Device Scanning

  private var _isScanningObserver: Cancellable?

  @Published
  public private(set) var isScanning: Bool = false {
    didSet {
      // Make sure to stop scan operation when the underlying value change
      if !isScanning {
        stopScan()
      }
    }
  }

  public override init() {
    super.init()
    // keep it simple by using main queue for event dispatch
    centralManager = CBCentralManager(delegate:self, queue: DispatchQueue.main)

    // Forward central manager scanning state
    _isScanningObserver = centralManager.publisher(for: \.isScanning).sink { [weak self] isScanning in
      if let self = self {
        Task { @MainActor in
          self.isScanning = isScanning
        }
      }
    }
  }

  // MARK: Scan Management

  private var scanTimeout: DispatchWorkItem? = nil
  private var scanListeners = [CheckedContinuation<Void, Never>]()

  /// Start Scan Operation.
  /// If a scan is alreayd running, duration is ignored.
  /// The scan operation is stopped:
  ///  - after duration.
  ///  - if state change.
  ///  - when stop scan called.
  public func startScan(for duration: DispatchTimeInterval) throws {
    guard centralManager.state == .poweredOn else {
      throw MatataCentralError.invalidState
    }
    // If scan operation in progress -> return
    guard scanTimeout == nil else { return }

    // Start scan operation
    centralManager.scanForPeripherals(withServices: [Service.UUID], options: nil)

    // schedule timeout after duration
    scanTimeout = DispatchWorkItem { self.stopScan() }
    DispatchQueue.main.asyncAfter(wallDeadline: DispatchWallTime.now() + duration,
                                  execute: scanTimeout!)
  }

  /// Stop running scan operation.
  public func stopScan() {
    guard let scanTimeout = scanTimeout else { return }
    // cancel timeout
    self.scanTimeout = nil
    scanTimeout.cancel()

    // actually stop the scan
    if (centralManager.isScanning) {
        centralManager.stopScan()
    }

    // resume all waiting continuations.
    scanListeners.forEach { $0.resume() }
    scanListeners.removeAll(keepingCapacity: false)
  }

  /// Scan for devices during a number of seconds.
  public func scan(for duration: DispatchTimeInterval) async throws {
    try startScan(for: duration)

    await withTaskCancellationHandler {
      Task { @MainActor in
        stopScan()
      }
    } operation: {
      // wait until stop scan is called
      await withCheckedContinuation { continuation in
        self.scanListeners.append(continuation)
      }
    }
  }

  // MARK: Devices Lifecycle
  private func register(_ peripheral: CBPeripheral) {
    // skip duplicated
    guard _peripherals[peripheral.identifier] == nil else {
      os_log("Discovered duplicated peripheral: %s (%s)", String(describing: peripheral.name), peripheral.identifier.description)
      return
    }

    os_log("Peripheral Connected")

    let device: MatataDevice
    switch (peripheral.name) {
    case "MatataBot":
      device = Bot(owner: self, peripheral: peripheral)
    case "MatataCon":
      device = Controller(owner: self, peripheral: peripheral)
    default:
      os_log("#Warning unsupported device name: %s", peripheral.name ?? "(null)")
      device = MatataDevice(owner: self, peripheral: peripheral)
    }
    _peripherals[peripheral.identifier] = Peripheral(device)
    // export discovered devices
    devices = _peripherals.values.map(\.device)
  }

  internal func unregister(_ device: MatataDevice) {
    guard let peripheral = _peripherals.removeValue(forKey: device.id) else { return }

    // invalidate internal state
    peripheral.device.invalidate()

    // Make sure it is not connected
    if peripheral.device.peripheral.state != .disconnected {
      centralManager.cancelPeripheralConnection(peripheral.device.peripheral)
    }

    // update published devices
    devices = _peripherals.values.map(\.device)
  }

  internal func connect(_ device: MatataDevice) throws {
    guard _peripherals[device.id] != nil else {
      throw MatataCentralError.unregistredDevice
    }

    switch (device.peripheral.state) {
    case .connecting, .connected:
      return
    case .disconnecting:
      throw MatataCentralError.deviceBusy
    case .disconnected:
      break
    @unknown default:
      throw MatataCentralError.deviceBusy
    }

    // Request connection
    centralManager.connect(device.peripheral, options: nil)
  }

  internal func disconnect(_ device: MatataDevice) throws {
    // if the peripheral is not present in the cache -> noop
    guard _peripherals[device.id] != nil else {
      throw MatataCentralError.unregistredDevice
    }

    switch (device.peripheral.state) {
    case .disconnecting, .disconnected:
      return
    case .connecting:
      throw MatataCentralError.deviceBusy
    case .connected:
      break
    @unknown default:
      throw MatataCentralError.deviceBusy
    }

    // And try to connect to the peripheral.
    centralManager.cancelPeripheralConnection(device.peripheral)
  }
}

extension MatataCentral: CBCentralManagerDelegate {
  /*
   *  centralManagerDidUpdateState is a required protocol method.
   *  Usually, you'd check for other states to make sure the current device supports LE, is powered on, etc.
   *  In this instance, we're just using it to wait for CBCentralManagerStatePoweredOn, which indicates
   *  the Central is ready to be used.
   */
  public func centralManagerDidUpdateState(_ central: CBCentralManager) {
    self.state = central.state

    if central.state.rawValue < CBManagerState.poweredOn.rawValue {
      _peripherals.values.forEach {
        $0.device.invalidate()
      }
      _peripherals.removeAll(keepingCapacity: false)
      devices = []
    } else {
      // on powered on -> refresh connected devices
      let connectedPeripherals = centralManager.retrieveConnectedPeripherals(withServices: [Service.UUID])
      for connected in connectedPeripherals where _peripherals[connected.identifier] == nil {
        os_log("Reconnect %s", connected.name ?? "-")
        register(connected)
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
      os_log("Discovered peripheral not in expected range, at %d", RSSI.intValue)
      return
    }

    os_log("Discovered %s", peripheral.name ?? "-")
    register(peripheral)
  }

  /*
   *  We've connected to the peripheral, now we need to discover the services and characteristics to find the 'transfer' characteristic.
   */
  public func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
    guard let peripheral = _peripherals[peripheral.identifier] else {
      return
    }
    os_log("Peripheral %s Connected", peripheral.device.id.description)
  }

  /*
   *  If the connection fails for whatever reason, we need to deal with it.
   */
  public func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
    guard let peripheral = _peripherals[peripheral.identifier] else { return }
    os_log("Failed to connect to %s (%s)", peripheral.device.id.description, String(describing: error))
    // TODO: peripheral.device.error = error
  }

  /*
   *  Once the disconnection happens, we need to clean up our local copy of the peripheral
   */
  public func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
    guard let peripheral = _peripherals[peripheral.identifier] else { return }
    os_log("Peripheral Disconnected: %s (%s)", peripheral.device.id.description, String(describing: error))
  }
}
