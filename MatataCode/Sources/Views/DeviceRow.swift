//
//  DeviceView.swift
//  MatataCode
//
//  Created by Jean-Daniel Dupas on 28/12/2021.
//

import SwiftUI
import MatataCore

extension MatataDevice.State {

  var localizedString: LocalizedStringKey {
    switch (self) {
    case .connecting:
      return "connecting…"
    case .connected:
      return "connected"
    case .disconnecting:
      return "disconnecting…"
    case .disconnected:
      return "disconnected"
    }
  }
}

struct DeviceRow<Device: DeviceProtocol>: View {

  @ObservedObject var device: Device

  var body: some View {
    HStack(alignment: .center) {
      Circle()
        .fill()
        .frame(width: 36, height: 36, alignment: .center)
        .overlay(
          Image("matatabot")
            .resizable()
            .scaledToFit()
            .foregroundColor(.accentColor)
            .frame(maxHeight: 24)
        )

      VStack(alignment: .leading, spacing: 2) {
        Text(device.name)
          .font(Font.headline)

        Text(device.state.localizedString)
          .foregroundColor(.secondary)
          .font(Font.subheadline.italic())
      }
      Spacer()
      Button {
        try? device.disconnect(unregister: false)
      } label: {
        Image(systemName: "xmark.circle.fill")
      }
      .opacity(device.state == .connected ? 1 : 0)
      .buttonStyle(.plain)
      .padding(4)
    }.padding(8)
  }
}

struct DeviceRow_Previews: PreviewProvider {
  static var previews: some View {
    DeviceRow(
      device: DesignTimeDevice())
  }
}
