//
//  Downstream.swift
//  MatataCore
//
//  Created by Jean-Daniel Dupas on 22/01/2022.
//

import os
import Combine
import Foundation
import CoreBluetooth

// MARK: - Peripheral Management
@MainActor
class ProxyPeripheral: NSObject, CBPeripheralManagerDelegate {

  unowned let owner: BluetoothProxy

  var upstream: ProxyCentral { owner.upstream }
  private var _isAdvertisingObserver: Cancellable?

  private var subscriptions = [CBUUID:[CBCentral]]()
  private var characteristics = [CBUUID:CBMutableCharacteristic]()

  private var manager: CBPeripheralManager! = nil

  init(_ owner: BluetoothProxy) {
    self.owner = owner
    super.init()

    manager = CBPeripheralManager(delegate:self, queue: DispatchQueue.main)

    _isAdvertisingObserver = manager.publisher(for: \.isAdvertising).sink { [weak self] isAdvertising in
      if let self = self {
//        Task { @MainActor in
          if (self.owner.state == .advertising || self.owner.state == .connected) {
            self.owner.state = .disconnected
          }
//        }
      }
    }
  }

  internal func invalidate() {
    if (manager.isAdvertising) {
      manager.stopAdvertising()
      manager.removeAllServices()
    }
  }

  internal func advertise(name: String, services: [CBService]) {
    for service in services {
      // ignore Battery Service (not supported)
      if service.uuid.uuidString == "180F" {
          continue
      }
      let svc = CBMutableService(type: service.uuid, primary: true)
      var characteristics = [CBCharacteristic]()
      service.characteristics?.forEach {
        let characteristic = CBMutableCharacteristic(type: $0.uuid, properties: $0.properties, value: $0.value, permissions: [.readable, .writeable])
        //characteristic.descriptors = $0.descriptors?.map({ CBMutableDescriptor(type: $0.uuid, value: $0.value) })
        characteristics.append(characteristic)
        self.characteristics[$0.uuid] = characteristic
      }
      svc.characteristics = characteristics
      manager.add(svc)
    }
    let uuids = services.map { $0.uuid }
    os_log("Start advertising services: %@", uuids)
    manager.startAdvertising([
      CBAdvertisementDataLocalNameKey: name,
      CBAdvertisementDataServiceUUIDsKey : uuids])
  }

  internal func updateValue(_ value: Data, for characteristic: CBCharacteristic) {
    guard let target = characteristics[characteristic.uuid] else { return }
    if (!manager.updateValue(value, for: target, onSubscribedCentrals: nil)) {
      os_log("#Warning write queue full")
      // FIXME: should enqueue request and replay it on delegate call
    }
  }

  internal func responds(to request: CBATTRequest, withResult: CBATTError.Code) {
    manager.respond(to: request, withResult: .success)
  }

  func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
    // ignore, and handle only state changes from CBCentralManager
  }

  func peripheralManagerDidStartAdvertising(_ peripheral: CBPeripheralManager, error: Error?) {
    // on error -> abort startup
    if let error = error {
      os_log("#Error service advertising failed with error: %@", error as NSError)
      return owner.disconnect()
    }
    os_log("Did start advertising")
  }

  /**
   *  @method peripheralManager:didAddService:error:
   *
   *  @param peripheral   The peripheral manager providing this information.
   *  @param service      The service that was added to the local database.
   *  @param error        If an error occurred, the cause of the failure.
   *
   *  @discussion         This method returns the result of an @link addService: @/link call. If the service could
   *                      not be published to the local database, the cause will be detailed in the <i>error</i> parameter.
   *
   */
  func peripheralManager(_ peripheral: CBPeripheralManager, didAdd service: CBService, error: Error?) {
    // on error -> abort startup
    if let error = error {
      os_log("#Error add service (%@) did failed with error: %@", service.uuid.data as NSData, error as NSError)
      return owner.disconnect()
    }

    os_log("Did add service: %@", service)
  }

  /**
   *  @method peripheralManager:central:didSubscribeToCharacteristic:
   *
   *  @param peripheral       The peripheral manager providing this update.
   *  @param central          The central that issued the command.
   *  @param characteristic   The characteristic on which notifications or indications were enabled.
   *
   *  @discussion             This method is invoked when a central configures <i>characteristic</i> to notify or indicate.
   *                          It should be used as a cue to start sending updates as the characteristic value changes.
   *
   */
  func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didSubscribeTo characteristic: CBCharacteristic) {
    os_log("did subscribe to")
    if subscriptions.keys.contains(characteristic.uuid) {
      subscriptions[characteristic.uuid]?.append(central)
    } else {
      subscriptions[characteristic.uuid] = [central]
      upstream.setNotify(enabled: true, for: characteristic.uuid)
    }
  }

  /**
   *  @method peripheralManager:central:didUnsubscribeFromCharacteristic:
   *
   *  @param peripheral       The peripheral manager providing this update.
   *  @param central          The central that issued the command.
   *  @param characteristic   The characteristic on which notifications or indications were disabled.
   *
   *  @discussion             This method is invoked when a central removes notifications/indications from <i>characteristic</i>.
   *
   */
  func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didUnsubscribeFrom characteristic: CBCharacteristic) {
    os_log("did unsubscribe from")
    if let index = subscriptions[characteristic.uuid]?.firstIndex(of: central) {
      if index == 0 && subscriptions[characteristic.uuid]?.count == 1 {
        subscriptions.removeValue(forKey: characteristic.uuid)
        upstream.setNotify(enabled: false, for: characteristic.uuid)
      } else {
        subscriptions[characteristic.uuid]?.remove(at: index)
      }
    } else {

    }
  }

  /**
   *  @method peripheralManager:didReceiveReadRequest:
   *
   *  @param peripheral   The peripheral manager requesting this information.
   *  @param request      A <code>CBATTRequest</code> object.
   *
   *  @discussion         This method is invoked when <i>peripheral</i> receives an ATT request for a characteristic with a dynamic value.
   *                      For every invocation of this method, @link respondToRequest:withResult: @/link must be called.
   *
   *  @see                CBATTRequest
   *
   */
  func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveRead request: CBATTRequest) {
    // TODO: forward requests to upstream and on response, call peripheral.respond(to: , withResult: )
    os_log("#Warning read request not supported")
    manager.respond(to: request, withResult: .success)
  }

  /**
   *  @method peripheralManager:didReceiveWriteRequests:
   *
   *  @param peripheral   The peripheral manager requesting this information.
   *  @param requests     A list of one or more <code>CBATTRequest</code> objects.
   *
   *  @discussion         This method is invoked when <i>peripheral</i> receives an ATT request or command for one or more characteristics with a dynamic value.
   *                      For every invocation of this method, @link respondToRequest:withResult: @/link should be called exactly once. If <i>requests</i> contains
   *                      multiple requests, they must be treated as an atomic unit. If the execution of one of the requests would cause a failure, the request
   *                      and error reason should be provided to <code>respondToRequest:withResult:</code> and none of the requests should be executed.
   *
   *  @see                CBATTRequest
   *
   */
  func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveWrite requests: [CBATTRequest]) {
    // forward requests to upstream and on response, call peripheral.respond(to: , withResult: )
    upstream.write(requests: requests)
  }

  /**
   *  @method peripheralManagerIsReadyToUpdateSubscribers:
   *
   *  @param peripheral   The peripheral manager providing this update.
   *
   *  @discussion         This method is invoked after a failed call to @link updateValue:forCharacteristic:onSubscribedCentrals: @/link, when <i>peripheral</i> is again
   *                      ready to send characteristic value updates.
   *
   */
  func peripheralManagerIsReady(toUpdateSubscribers peripheral: CBPeripheralManager) {

  }

  /**
   *  @method peripheralManager:didPublishL2CAPChannel:error:
   *
   *  @param peripheral   The peripheral manager requesting this information.
   *  @param PSM      The PSM of the channel that was published.
   *  @param error    If an error occurred, the cause of the failure.
   *
   *  @discussion         This method is the response to a  @link publishL2CAPChannel: @/link call.  The PSM will contain the PSM that was assigned for the published
   *            channel
   *
   */
  func peripheralManager(_ peripheral: CBPeripheralManager, didPublishL2CAPChannel PSM: CBL2CAPPSM, error: Error?) {

  }


  /**
   *  @method peripheralManager:didUnublishL2CAPChannel:error:
   *
   *  @param peripheral   The peripheral manager requesting this information.
   *  @param PSM      The PSM of the channel that was published.
   *  @param error    If an error occurred, the cause of the failure.
   *
   *  @discussion         This method is the response to a  @link unpublishL2CAPChannel: @/link call.
   *
   */
  func peripheralManager(_ peripheral: CBPeripheralManager, didUnpublishL2CAPChannel PSM: CBL2CAPPSM, error: Error?) {

  }


  /**
   *  @method peripheralManager:didOpenL2CAPChannel:error:
   *
   *  @param peripheral     The peripheral manager requesting this information.
   *  @param channel          A <code>CBL2CAPChannel</code> object.
   *  @param error    If an error occurred, the cause of the failure.
   *
   *  @discussion      This method returns the result of establishing an incoming L2CAP channel , following publishing a channel using @link publishL2CAPChannel: @link call.
   *
   */
  func peripheralManager(_ peripheral: CBPeripheralManager, didOpen channel: CBL2CAPChannel?, error: Error?) {

  }
}

