//
//  DeviceView.swift
//  MatataCode
//
//  Created by Jean-Daniel Dupas on 28/12/2021.
//

import SwiftUI
import MatataCore

struct DeviceView<Device: DeviceProtocol>: View {

  @ObservedObject var device: Device

  var body: some View {
    HStack(alignment: .center) {
      Image("Bot-head")
      Text(device.name)
      Spacer()
      Button {
        try? device.disconnect(unregister: false)
      } label: {
        Image(systemName: "xmark.circle.fill")
      }
      .buttonStyle(.plain)
    }.padding()
  }
}

struct DeviceView_Previews: PreviewProvider {
  static var previews: some View {
    DeviceView(
      device: DesignTimeDevice())
  }
}
