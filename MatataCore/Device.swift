//
//  Device.swift
//  MatataCore
//
//  Created by Jean-Daniel Dupas on 30/05/2021.
//

import os
import Combine
import Foundation
import DequeModule
import CoreBluetooth

enum RequestError: Error {
  case timeout
  case deviceNotConnected
  case emptyResponse
  case invalidResponse
  case packetTooBig
  case requestFailure
  case invalidParameter // out of range parameter
  case notInSensorMode
  case unsupportedStatus
}

private typealias Continuation = (_ result: Result<Data, Error>) -> Void

/*

 - discover services -> didDiscoverServices
 - discover characteristics -> didDiscoverCharacteristicsFor
 - save characteristics and setNotifyValue(true)
 - receive hello message -> write handshake
 - wait write done and response (with timeout) -> finalize handshake

 - send command
 - start timeout
 - wait write done and response -> stop timeout and forward response
 - on timeout -> disconnect

*/
@MainActor
public class MatataDevice: NSObject, Identifiable, ObservableObject {

  public let id: UUID
  public var name: String { peripheral.name ?? "-" }

  internal let peripheral: CBPeripheral
  private unowned let central: MatataCentral

  private var notify: CBCharacteristic? = nil
  private var write: CBCharacteristic? = nil

  private var timeoutSuspended: Bool = true
  private let timeout: DispatchSourceTimer = DispatchSource.makeTimerSource()

  private var _deviceStateObserver: Cancellable?

  public enum State {
    case connecting // CB connecting state || CB connected and not handshake done
    case connected // CB connected && handshake done
    case disconnecting // CB disconnecting
    case disconnected // CB disconnected
  }

  @Published
  public private(set) var state: State = .disconnected

  private enum HandShakeState {
    case undefined
    case waitingHello
    case waitingHandshakeResponse
    case handshakeDone
  }

  private var handshakeState: HandShakeState = .undefined

  // MARK: -
  init(owner: MatataCentral, peripheral: CBPeripheral) {
    self.id = peripheral.identifier

    self.central = owner
    self.peripheral = peripheral

    super.init()

    peripheral.delegate = self

    timeout.setEventHandler {
      // handle timeout
      self.resume(.failure(RequestError.timeout))
      // send next packet
      self.sendPendingPackets()
    }

    // Track device state and update published state accordingly
    _deviceStateObserver = peripheral.publisher(for: \.state).sink { [weak self] state in
      guard let self = self else { return }
      switch (state) {
      case .connecting:
        self.state = .connecting

      case .connected:
        self.state = self.handshakeState == .handshakeDone ? .connected : .connecting
        if (self.handshakeState == .undefined) {
          self.handshakeState = .waitingHello
          peripheral.discoverServices([Service.UUID])
        }

      case .disconnecting:
        self.onDisconnect(state: .disconnecting)

      case .disconnected:
        self.onDisconnect(state: .disconnected)

      @unknown default:
        fatalError("unknown device state")
      }
    }
  }

  // Called by central before releasing the device.
  internal func invalidate() {
    _deviceStateObserver?.cancel()
    _deviceStateObserver = nil

    peripheral.delegate = nil

    onDisconnect(state: .disconnected)

    timeout.cancel()
  }

  private func onDisconnect(state: State) {
    self.handshakeState = .undefined

    resume(.failure(RequestError.deviceNotConnected))

    packetQueue.forEach { $0.continuation(.failure(RequestError.deviceNotConnected)) }
    packetQueue.removeAll()

    stopTimeoutTimer()

    // invalidate cached values
    notify = nil
    write = nil

    self.state = state
  }

  // MARK: - Message Sending

  private struct Request {
    let packet: Data
    let continuation: Continuation
  }
  private var packetQueue = Deque<Request>()
  private var responseContinuation: Continuation?

  private func resume(_ result: Result<Data, Error>) {
    stopTimeoutTimer()
    if let continuation = responseContinuation {
      responseContinuation = nil
      continuation(result)
    }

    if case .success = result {
      sendPendingPackets()
    }
  }

  public func connect() throws {
    try central.connect(self)
  }

  public func disconnect(unregister: Bool = false) throws {
    try central.disconnect(self)
    if (unregister) {
        central.unregister(self)
    }
  }

  // call when detect invalid state and should reconnect
  private func reset() {
    try? central.disconnect(self)
    // TODO: reconnect once disconnected
  }

  public func send(payload: [UInt8]) async throws -> Data {
    return try await send(packet: IO.encode(payload, withLength: true))
  }

  // internal function
  private func send(packet: Data) async throws -> Data {
    guard state == .connected else { throw RequestError.deviceNotConnected }

    let mtu = peripheral.maximumWriteValueLength(for: .withResponse)
    guard packet.count <= mtu else { throw RequestError.packetTooBig }

    // push packet in queue and try to send next
    return try await withCheckedThrowingContinuation { continuation in
      packetQueue.append(Request(packet: packet) {
        continuation.resume(with: $0)
      })
      sendPendingPackets()
    }
  }

  private func sendPendingPackets() {
    // try to send next pending packet bytes
    guard responseContinuation == nil, let request = packetQueue.popFirst(), let write = write else { return }

    assert(responseContinuation == nil)

    responseContinuation = request.continuation
    peripheral.writeValue(request.packet, for: write, type: .withResponse)
    os_log("Packet sent (%d bytes): %@", request.packet.count, request.packet as NSData)
    // required because there is no response when sending a bot command when no bot is connected.
    startTimeoutTimer()
  }

  // MARK: - Timeout
  private func startTimeoutTimer() {
    stopTimeoutTimer()

    timeout.schedule(wallDeadline: DispatchWallTime.now() + DispatchTimeInterval.seconds(10))
    timeoutSuspended = false
    timeout.resume()
  }

  private func stopTimeoutTimer() {
    if (!timeoutSuspended) {
      timeoutSuspended = true
      timeout.suspend()
    }
  }

  // MARK: - Request Handling
  func handle(payload: Data) -> Result<Data, Error>? {
    return .success(payload)
  }

  func handle(message msg: String) {
    os_log("Received message: %s", msg)
  }

  // MARK: - Handshake
  private func handleHello() {
    guard handshakeState == .waitingHello else {
      os_log("#Warning hello frame received while not waiting it")
      return
    }
    // make sure to not send if a handshake is already pending.
    handshakeState = .waitingHandshakeResponse

    packetQueue.append(Request(packet: Handshake.packet) { result in
      if case .success(let payload) = result {
        self.handleHandshake(payload: payload)
      }
    })
    sendPendingPackets()
  }

  private func handleHandshake(payload data: Data) {
    do {
      switch try Handshake.parse(payload: data) {
      case .ok:
        os_log("Handshake OK")
        handshakeState = .handshakeDone
        state = .connected
        return
      case .botNotSupported:
        os_log("#Error Bot must be upgraded")
        break
      case .deviceVersionNotSupported:
        os_log("#Error Device version not supported")
        break
      }
    } catch {
      os_log("#Error failed to parse handshake response: %@ (%@)", String(describing: error), data as NSData)
    }
    reset()
  }
}

extension MatataDevice: CBPeripheralDelegate {

  /*
   *  The Transfer Service was discovered
   */
  public func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
    if let error = error {
      os_log("Error discovering services: %s", error.localizedDescription)
      return reset()
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
      return reset()
    }

    // Again, we loop through the array, just in case and check if it's the right one
    guard let serviceCharacteristics = service.characteristics else { return }
    for characteristic in serviceCharacteristics {
      switch (characteristic.uuid) {

      case Service.notifyCharacteristic:
        guard characteristic.properties.contains(.notify) else {
          os_log("#Error notify characteristic does not has .notify property")
          return reset()
        }
        self.notify = characteristic
        // Subscribe to notify channel.
        peripheral.setNotifyValue(true, for: characteristic)

      case Service.writeCharacteristic:
        guard characteristic.properties.contains(.write) else {
          os_log("#Error write characteristic does not has .write property")
          return reset()
        }
        self.write = characteristic

      default:
        os_log("#Warning unsupported characteristic UUID: %@", characteristic.uuid)
        break
      }
    }
    // Sanity check
    guard self.write != nil, self.notify != nil else {
      os_log("#Error missing required characteristics. device not usable")
      return reset()
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
      os_log("Notification began on %@", characteristic.uuid)
    } else {
      // Notification has stopped, so disconnect from the peripheral
      os_log("Notification stopped on %@. Disconnecting", characteristic.uuid)
      reset()
    }
  }

  /*
   *   This callback lets us know more data has arrived via notification on the characteristic
   */
  public func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
    // Deal with errors (if any)
    if let error = error {
      os_log("Error update value for characteristic: %s", error.localizedDescription)
      return reset()
    }

    guard let data = characteristic.value, data.count > 0 else {
      return reset()
    }

    // 0xfe048702b211
    if data[0] == 0xfe {
      guard let payload = try? IO.decode(data) else {
        os_log("#Error failed to decode packet: %@", data as NSData)
        resume(.failure(RequestError.invalidResponse))
        return reset()
      }

      // if this is a status message, it should not be handle as a response
      if let result = handle(payload: payload) {
        os_log("Received payload: %s", String(describing: result))
        resume(result)
      }
    } else {
      guard let message = String(data: data, encoding: .utf8) else {
        os_log("#Error failed to decode packet: %@", data as NSData)
        resume(.failure(RequestError.invalidResponse))
        return
      }
      os_log("Received message: %s", message)

      if message.hasPrefix("Car:[") {
        handleHello()
      } else {
        handle(message: message)
      }
    }
  }

  public func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
    if let error = error {
      os_log("Error sending packet: %s", error.localizedDescription)
      return reset()
    }
    os_log("peripheral did write value")
    // waiting reply, do not try to send next packet yet.
  }

  public func peripheralIsReady(toSendWriteWithoutResponse peripheral: CBPeripheral) {
    os_log("peripheral ready to send write without response")
    sendPendingPackets()
  }

  /*
   *  The peripheral letting us know when services have been invalidated.
   */
  public func peripheral(_ peripheral: CBPeripheral, didModifyServices invalidatedServices: [CBService]) {
    if invalidatedServices.contains(where: { $0.uuid == Service.UUID }) {
      os_log("Service invalidated -> disconnect")
      reset()
    }
  }

}

public class Bot : MatataDevice {

}

public class Controller : MatataDevice {

  @Published
  public private(set) var isInSensorMode: Bool = true

  @Published
  public private(set) var isBotConnected: Bool = false

  override func handle(payload: Data) -> Result<Data, Error>? {
    switch (payload[0]) {
    case 0x04:
      return handleStatus(payload: payload)
    default:
      return super.handle(payload: payload)
    }
  }

  private func handleStatus(payload: Data) -> Result<Data, Error>? {
    if payload[1] == 0x87 && payload.count == 3 {
      // implies in sensor mode
      if !isInSensorMode {
        isInSensorMode = true
      }

      if isBotConnected != (payload[2] == 0x01) {
        // 0x01 means connected, 0x02 means No Bot.
        isBotConnected.toggle()
        // FIXME: if the last command is a bot command and bot is not connected -> return failure
        os_log("is bot connected: %s (%@)", String(describing: isBotConnected), payload as NSData)
      }
      // status message handled
      return nil
    }
    else if payload[1] == 0x88 && payload.count == 3 {

      isInSensorMode = payload[2] != 0x07

      switch (payload[2]) {
      case 0:
        os_log("request success")
        return .success(Data())
      case 1:
        os_log("request failure")
        return .failure(RequestError.requestFailure)
      case 3:
        // may be trigger by send play_treble command (0x71)
        os_log("unsupported command ?")
        return .failure(RequestError.unsupportedStatus)
      case 4:
        os_log("invalid parameter")
        return .failure(RequestError.invalidParameter)
      case 7:
        os_log("not in sensor mode")
        return .failure(RequestError.notInSensorMode)
      default:
        os_log("unknown status code (%@)", payload as NSData)
        return .failure(RequestError.unsupportedStatus)
      }
    }
    os_log("unhandled status message (%d bytes): %@", payload.count, payload as NSData)
    return .success(payload)
  }
}
