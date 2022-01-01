//
//  DeviceList.swift
//  MatataCode
//
//  Created by Jean-Daniel Dupas on 28/12/2021.
//

import SwiftUI
import MatataCore

private enum ScannerStatus {
  case scanning, idle, powerOff
  case unavailable
  case unauthorized

  var title: String {
    switch (self) {
    case .scanning:
      return "scanning…"
    case .idle:
      return ""
    case .powerOff:
      return "powered off"
    case .unavailable:
      return "unavailable"
    case .unauthorized:
      return "unauthorized"
    }
  }

  var isAvailable: Bool {
    switch (self) {
    case .scanning, .idle:
      return true
    default:
      return false
    }
  }
}

private extension DevicesScanner {

  var status: ScannerStatus {
    if (isScanning) {
      return .scanning
    }
    switch (state) {
    case .poweredOn:
      return .idle
    case .poweredOff:
      return .powerOff
    case .unauthorized:
      return .unauthorized
    default:
      return .unavailable
    }
  }
}

struct StatusBar<Scanner: DevicesScanner>: View {

  @ObservedObject var devicesScanner: Scanner

  var body: some View {
    HStack(alignment: .center) {

      Image(devicesScanner.status.isAvailable ? "central_connected" : "central_disconnected")
        .foregroundColor(devicesScanner.status.isAvailable ? .accentColor : .red)
      Text(devicesScanner.status.title)
        .frame(maxWidth: .infinity, alignment: .leading)
        .foregroundColor(.secondary)
        .controlSize(.small)
    }.padding(4)
      .foregroundColor(.blue)
  }

}

struct DeviceList<Scanner: DevicesScanner, Device>: View where Scanner.Device == Device {

  @Binding var selection: Device.ID?

  @ObservedObject var devicesScanner: Scanner

  var body: some View {
    VStack(spacing: 0) {
      List(selection: $selection) {
        Section {
          ForEach(devicesScanner.devices) { device in
            NavigationLink(destination: DeviceView(device: device)) {
              DeviceRow(device: device)
            }
          }.onDelete { indices in
            indices.map { idx in
              devicesScanner.devices[idx]
            }.forEach { device in
              try? device.disconnect(unregister: true)
            }
          }
        } header: {
            Text("Devices")
        }
      }.emptyPlaceholder(devicesScanner.devices.isEmpty) {
        EmptyDeviceList(devicesScanner: devicesScanner)
      }
      .listStyle(.sidebar)
      .navigationTitle("Devices")
      //      .refreshable {
      //        await deviceManager.startScanning(for: .seconds(10))
      //      }
      StatusBar(devicesScanner: devicesScanner)
    }
  }
}

struct EmptyDeviceList<Scanner: DevicesScanner>: View {

  @ObservedObject var devicesScanner: Scanner

  var body: some View {
    if (devicesScanner.isScanning) {
      HStack(spacing: 12) {
        ProgressView()
          .controlSize(.small)
        Text("Scanning…")
      }
    } else {
      VStack {
        Text("No Devices")
        Button("Start Scanning") {
          try? devicesScanner.startScan(for: .seconds(10))
        }
      }
    }
  }
}

struct DeviceList_Previews: PreviewProvider {

  @State
  static var selection: DesignTimeDevice.ID?

  static var previews: some View {
    DeviceList(selection: $selection,
               devicesScanner: DesignTimeScanner())
  }
}
