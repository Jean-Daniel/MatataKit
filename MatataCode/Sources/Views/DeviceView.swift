//
//  DeviceView.swift
//  MatataCode
//
//  Created by Jean-Daniel Dupas on 28/12/2021.
//

import SwiftUI
import Combine
import MatataCore

struct DeviceView<Device: DeviceProtocol>: View {

  @ObservedObject var device: Device

  var body: some View {
      VStack(alignment: .center) {
        VStack(alignment: .center) {
          Text(device.name)
            .font(.title)
          Text(device.state.localizedString)
            .foregroundColor(.secondary)
            .font(.subheadline)
            .italic()
        }
        .padding()
        Spacer()
          .frame(maxWidth: .infinity, maxHeight: .infinity)
          .overlay(DeviceStateOverlay(device: device))
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .onAppear {
        // autoconnect when loading the device view
        try? device.connect()
      }


      .navigationTitle(device.name)
  }
}

struct DeviceStateOverlay<Device: DeviceProtocol>: View {

  @ObservedObject var device: Device

  var body: some View {
    if (device.state != .connected) {
      GeometryReader { geometry in
        ZStack {
          VisualEffectBlur(material: .popover, blendingMode: .withinWindow, state: .followsWindowActiveState)
          VStack {
            ProgressView()
              .progressViewStyle(.circular)
              .opacity(device.state != .disconnected ? 1 : 0)
            Text(device.state.localizedString)
            Button("Connect") {
              try? device.connect()
            }.opacity(device.state == .disconnected ? 1 : 0)
              .disabled(device.state != .disconnected)
          }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        //      .frame(width: state != .connected ? geometry.size.width : 0,
        //             height: state != .connected ? geometry.size.height : 0)
      }
    } else {
      EmptyView()
    }
  }
}

struct DeviceView_Previews: PreviewProvider {
  static var previews: some View {
    DeviceView(device: DesignTimeDevice(state: .disconnected))
  }
}

