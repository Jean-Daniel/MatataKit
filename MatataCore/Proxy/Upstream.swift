//
//  Upstream.swift
//  MatataCore
//
//  Created by Jean-Daniel Dupas on 22/01/2022.
//

import os
import Combine
import Foundation
import CoreBluetooth
import DequeModule

// MARK: - Central Management
@MainActor
class ProxyCentral: NSObject, CBCentralManagerDelegate {

  unowned let owner: BluetoothProxy
  var downstream: ProxyPeripheral { owner.downstream }

  private var _isScanningObserver: Cancellable?

  private var builder: ServiceBuilder? = nil
  private var peripheral: CBPeripheral? = nil
  private var characteristics = [CBUUID:CBCharacteristic]()
  private var centralManager: CBCentralManager! = nil

  private var readRequests = Deque<CBATTRequest>()
  private var writeRequests = Deque<CBATTRequest>()

  init(_ owner: BluetoothProxy) {
    self.owner = owner
    super.init()

    centralManager = CBCentralManager(delegate:self, queue: DispatchQueue.main)

    _isScanningObserver = centralManager.publisher(for: \.isScanning).sink { [weak self] isScanning in
      if let self = self {
//        Task { @MainActor in
          if (!isScanning && self.owner.state == .scanning) {
            self.owner.state = .disconnected
          } else if (isScanning && self.owner.state == .disconnected) {
            self.owner.state = .scanning
          }
//        }
      }
    }
  }

  internal func invalidate() {
    if (centralManager.isScanning) {
      centralManager.stopScan()
    }

    peripheral.flatMap {
      centralManager.cancelPeripheralConnection($0)
      peripheral = nil
    }

    writeRequests.removeAll(keepingCapacity: false)
    readRequests.removeAll(keepingCapacity: false)
    builder = nil
  }

  func scan(services: [CBUUID]) {
    guard (centralManager.state == .poweredOn) else { return }

    centralManager.scanForPeripherals(withServices: services, options: nil)
  }

  internal func setNotify(enabled: Bool, for characteristic: CBUUID) {
    guard let characteristic = characteristics[characteristic] else { return }
    peripheral?.setNotifyValue(enabled, for: characteristic)
  }

  internal func read(request: CBATTRequest) {
    guard let characteristic = characteristics[request.characteristic.uuid] else { return }
    peripheral?.readValue(for: characteristic)
  }

  internal func write(requests: [CBATTRequest]) {
    for request in requests {
      guard let characteristic = characteristics[request.characteristic.uuid],
            let value = request.value
      else { continue }

      os_log("write value for %@: %@", characteristic.uuid, value as NSData)
      if characteristic.properties.contains(.write) {
        writeRequests.append(request)
        peripheral?.writeValue(value, for: characteristic, type: .withResponse)
      } else {
        peripheral?.writeValue(value, for: characteristic, type: .withoutResponse)
        downstream.responds(to: request, withResult: .success)
      }
    }
  }

  // MARK: Delegate
  func centralManagerDidUpdateState(_ central: CBCentralManager) {
    if (central.state != .poweredOn) {
      os_log("central off: %d", central.state.rawValue)
      owner.disconnect()
    } else {
      os_log("central powered on !")
    }
  }

  func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
    guard owner.state == .scanning else { return }

    // switch to discovering state and stop scanning
    owner.state = .discovering
    central.stopScan()

    self.peripheral = peripheral
    // connect to the device
    central.connect(peripheral, options: nil)
  }

  func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
    // start peripheral services discovery
    guard self.peripheral === peripheral else { return }
    peripheral.delegate = self
    peripheral.discoverServices(nil)
  }

  func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
    owner.disconnect()
  }

  func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
    owner.disconnect()
  }
}


// MARK: - Peripheral
extension ProxyCentral: CBPeripheralDelegate {

  private func checkReadiness() {
    if (builder?.isReady == true) {
      // TODO: create service mutable copy and start advertising
      os_log("peripheral discovery done: “%@”", peripheral?.name ?? "")
      if let services = peripheral?.services {
        os_log("Services: ")
        for service in services {
          os_log(" - %@: { is primary: %@ }", service.uuid, service.isPrimary ? "yes": "no")
          if let characteristics = service.characteristics, !characteristics.isEmpty {
            os_log("    characteristics:")
            for characteristic in characteristics {
              os_log("      - %@: { properties: %@, value: %@ }", characteristic.uuid,
                     String(describing: characteristic.properties),
                     characteristic.value?.description ?? "-")
              if let descriptors = characteristic.descriptors, !descriptors.isEmpty {
                os_log("        descriptors:")
                for descriptor in descriptors {
                  os_log("          - %@ (%@)", descriptor.uuid, descriptor.uuid.data as NSData)
                }
              }
            }
          }
        }
        owner.advertise(name: peripheral?.name ?? "", services: services)
      }
      builder = nil
    }
  }

  /**
   *  @method peripheral:didModifyServices:
   *
   *  @param peripheral      The peripheral providing this update.
   *  @param invalidatedServices  The services that have been invalidated
   *
   *  @discussion      This method is invoked when the @link services @/link of <i>peripheral</i> have been changed.
   *            At this point, the designated <code>CBService</code> objects have been invalidated.
   *            Services can be re-discovered via @link discoverServices: @/link.
   */
  func peripheral(_ peripheral: CBPeripheral, didModifyServices invalidatedServices: [CBService]) {
    os_log("#Warning dynamic service update not supported: %@", invalidatedServices)
  }

  /**
   *  @method peripheral:didDiscoverServices:
   *
   *  @param peripheral  The peripheral providing this information.
   *  @param error    If an error occurred, the cause of the failure.
   *
   *  @discussion      This method returns the result of a @link discoverServices: @/link call. If the service(s) were read successfully, they can be retrieved via
   *            <i>peripheral</i>'s @link services @/link property.
   *
   */
  func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
    if let error = error {
      os_log("#Error service discovery did failed: %@", error as NSError)
      return
    }

    guard let services = peripheral.services else {
      // no service -> nothing to advertise
      owner.disconnect()
      return
    }

    builder = ServiceBuilder()

    for service in services {
      builder?.addCharacteristicsRequest(service)
      peripheral.discoverCharacteristics(nil, for: service)

      builder?.addIncludedServicesRequest(service)
      peripheral.discoverIncludedServices(nil, for: service)
    }
  }


  /**
   *  @method peripheral:didDiscoverIncludedServicesForService:error:
   *
   *  @param peripheral  The peripheral providing this information.
   *  @param service    The <code>CBService</code> object containing the included services.
   *  @param error    If an error occurred, the cause of the failure.
   *
   *  @discussion      This method returns the result of a @link discoverIncludedServices:forService: @/link call. If the included service(s) were read successfully,
   *            they can be retrieved via <i>service</i>'s <code>includedServices</code> property.
   */
  func peripheral(_ peripheral: CBPeripheral, didDiscoverIncludedServicesFor service: CBService, error: Error?) {
    builder?.removeIncludedServicesRequest(service)
    defer { checkReadiness() }

    if let error = error {
      os_log("#Error included service discovery did failed: %@", error as NSError)
      return
    }

    guard let services = service.includedServices else { return }

    for service in services {
      builder?.addCharacteristicsRequest(service)
      peripheral.discoverCharacteristics(nil, for: service)
    }
  }


  /**
   *  @method peripheral:didDiscoverCharacteristicsForService:error:
   *
   *  @param peripheral  The peripheral providing this information.
   *  @param service    The <code>CBService</code> object containing the characteristic(s).
   *  @param error    If an error occurred, the cause of the failure.
   *
   *  @discussion      This method returns the result of a @link discoverCharacteristics:forService: @/link call. If the characteristic(s) were read successfully,
   *            they can be retrieved via <i>service</i>'s <code>characteristics</code> property.
   */
  func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
    builder?.removeCharacteristicsRequest(service)
    defer { checkReadiness() }

    if let error = error {
      os_log("#Error characteristics discovery did failed: %@", error as NSError)
      return
    }

    guard let characteristics = service.characteristics else { return }
    for characteristic in characteristics {
      self.characteristics[characteristic.uuid] = characteristic

      builder?.addDescriptorsRequest(characteristic)
      peripheral.discoverDescriptors(for: characteristic)
    }
  }

  /**
   *  @method peripheral:didDiscoverDescriptorsForCharacteristic:error:
   *
   *  @param peripheral    The peripheral providing this information.
   *  @param characteristic  A <code>CBCharacteristic</code> object.
   *  @param error      If an error occurred, the cause of the failure.
   *
   *  @discussion        This method returns the result of a @link discoverDescriptorsForCharacteristic: @/link call. If the descriptors were read successfully,
   *              they can be retrieved via <i>characteristic</i>'s <code>descriptors</code> property.
   */
  func peripheral(_ peripheral: CBPeripheral, didDiscoverDescriptorsFor characteristic: CBCharacteristic, error: Error?) {
    builder?.removeDescriptorsRequest(characteristic)
    defer { checkReadiness() }

    if let error = error {
      os_log("#Error descriptors discovery did failed: %@", error as NSError)
      return
    }
  }

  /**
   *  @method peripheral:didUpdateValueForCharacteristic:error:
   *
   *  @param peripheral    The peripheral providing this information.
   *  @param characteristic  A <code>CBCharacteristic</code> object.
   *  @param error      If an error occurred, the cause of the failure.
   *
   *  @discussion        This method is invoked after a @link readValueForCharacteristic: @/link call, or upon receipt of a notification/indication.
   */
  func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
    // TODO: forward value to downstream
    guard let value = characteristic.value else { return }
    downstream.updateValue(value, for: characteristic)
    os_log("did Update value for %@: %@", characteristic.uuid, characteristic.value! as NSData)
  }


  /**
   *  @method peripheral:didWriteValueForCharacteristic:error:
   *
   *  @param peripheral    The peripheral providing this information.
   *  @param characteristic  A <code>CBCharacteristic</code> object.
   *  @param error      If an error occurred, the cause of the failure.
   *
   *  @discussion        This method returns the result of a {@link writeValue:forCharacteristic:type:} call, when the <code>CBCharacteristicWriteWithResponse</code> type is used.
   */
  func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
    // TODO: forward value to downstream
    guard let index = writeRequests.lastIndex(where: { $0.characteristic.uuid == characteristic.uuid}) else {
      return
    }
    let request = writeRequests.remove(at: index)
    downstream.responds(to: request, withResult: error == nil ? .success : .unlikelyError)
  }


  /**
   *  @method peripheral:didUpdateNotificationStateForCharacteristic:error:
   *
   *  @param peripheral    The peripheral providing this information.
   *  @param characteristic  A <code>CBCharacteristic</code> object.
   *  @param error      If an error occurred, the cause of the failure.
   *
   *  @discussion        This method returns the result of a @link setNotifyValue:forCharacteristic: @/link call.
   */
  func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
    // TODO: if ready to notify -> send pending notifications

  }

  /**
   *  @method peripheral:didUpdateValueForDescriptor:error:
   *
   *  @param peripheral    The peripheral providing this information.
   *  @param descriptor    A <code>CBDescriptor</code> object.
   *  @param error      If an error occurred, the cause of the failure.
   *
   *  @discussion        This method returns the result of a @link readValueForDescriptor: @/link call.
   */
  func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor descriptor: CBDescriptor, error: Error?) {
    // TODO: forward value to downstream
    
  }


  /**
   *  @method peripheral:didWriteValueForDescriptor:error:
   *
   *  @param peripheral    The peripheral providing this information.
   *  @param descriptor    A <code>CBDescriptor</code> object.
   *  @param error      If an error occurred, the cause of the failure.
   *
   *  @discussion        This method returns the result of a @link writeValue:forDescriptor: @/link call.
   */
  func peripheral(_ peripheral: CBPeripheral, didWriteValueFor descriptor: CBDescriptor, error: Error?) {
    // TODO: forward result to downstream

  }


  /**
   *  @method peripheralIsReadyToSendWriteWithoutResponse:
   *
   *  @param peripheral   The peripheral providing this update.
   *
   *  @discussion         This method is invoked after a failed call to @link writeValue:forCharacteristic:type: @/link, when <i>peripheral</i> is again
   *                      ready to send characteristic value updates.
   *
   */
  func peripheralIsReady(toSendWriteWithoutResponse peripheral: CBPeripheral) {
    // TODO: forward pending write without responses

  }

  func peripheral(_ peripheral: CBPeripheral, didOpen channel: CBL2CAPChannel?, error: Error?) {
     // TODO: start to read channel input stream and write content to downstream

  }
}

private class ServiceBuilder {

  private var _discoverCharacteristics = NSMutableOrderedSet()
  private var _discoverIncludedServices = NSMutableOrderedSet()

  // Characteristics
  private var _discoverDescriptors = NSMutableOrderedSet()

  var isReady: Bool {
    _discoverCharacteristics.count == 0
    && _discoverIncludedServices.count == 0
    && _discoverDescriptors.count == 0
  }

  func addCharacteristicsRequest(_ service: CBService) {
    _discoverCharacteristics.add(service.uuid)
  }

  func removeCharacteristicsRequest(_ service: CBService) {
    _discoverCharacteristics.remove(service.uuid)
  }

  func addIncludedServicesRequest(_ service: CBService) {
    _discoverIncludedServices.add(service.uuid)
  }

  func removeIncludedServicesRequest(_ service: CBService) {
    _discoverIncludedServices.remove(service.uuid)
  }

  func addDescriptorsRequest(_ characteristic: CBCharacteristic) {
    _discoverDescriptors.add(characteristic.uuid)
  }

  func removeDescriptorsRequest(_ characteristic: CBCharacteristic) {
    _discoverDescriptors.remove(characteristic.uuid)
  }

}

private extension CBService {

  func asMutableService() -> CBMutableService {
    let copy = CBMutableService(type: uuid, primary: isPrimary)
    copy.includedServices = includedServices
    copy.characteristics = characteristics
    return copy
  }
}
