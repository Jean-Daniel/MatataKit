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
  case denied, restricted
  case unavailable

  var title: LocalizedStringKey {
    switch (self) {
    case .scanning:
      return "scanning…"
    case .idle:
      return ""
    case .powerOff:
      return "bluetooth off"
    case .unavailable:
      return "bluetooth unavailable"
    case .denied:
      return "bluetooth access denied"
    case .restricted:
      return "bluetooth restricted"
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
      switch (Self.authorization) {
      case .restricted:
        return .restricted
      case .notDetermined, .denied, .allowedAlways:
        return .denied
      @unknown default:
        return .denied
      }
    default:
      return .unavailable
    }
  }
}

struct StatusBar<Scanner: DevicesScanner>: View {

  @ObservedObject var devicesScanner: Scanner

  var body: some View {
    HStack(alignment: .center) {

      Image(devicesScanner.status.isAvailable ? "bluetooth.on" : "bluetooth.off")
        .foregroundColor(devicesScanner.status.isAvailable ? .accentColor : nil)
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
          ForEach(devicesScanner.devices, id: \.id) { device in
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
            Label("Devices", systemImage: "cpu")
        }
      }.emptyPlaceholder(devicesScanner.devices.isEmpty) {
        EmptyDeviceList(devicesScanner: devicesScanner)
      }.onDeleteCommand {
        let device = devicesScanner.devices.first {
          $0.id == selection
        }
        try? device?.disconnect(unregister: true)
      }
      .listStyle(.automatic)
      .navigationTitle("Devices")
      //      .refreshable {
      //        await deviceManager.startScanning(for: .scanDuration)
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
          try? devicesScanner.startScan(for: .scanDuration)
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
