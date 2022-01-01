//
//  DeviceView.swift
//  MatataCode
//
//  Created by Jean-Daniel Dupas on 28/12/2021.
//

import SwiftUI
import MatataCore

struct DeviceRow<Device: DeviceProtocol>: View {

  @ObservedObject var device: Device

  var body: some View {
    HStack(alignment: .center) {
      Image("Bot")
        .resizable()
        .scaledToFit()
        .foregroundColor(.accentColor)
        .frame(maxHeight: 32)
      VStack(alignment: .leading) {
        Text(device.name)
          .font(Font.headline)
        
        Text(device.id.uuidString)
          .foregroundColor(.secondary)
          .font(Font.subheadline.italic())
      }
      Spacer()
      Button {
        try? device.disconnect(unregister: false)
      } label: {
        Image(systemName: "bolt.horizontal.circle.fill")
      }
      .buttonStyle(.plain)
    }.padding()
  }
}

struct DeviceRow_Previews: PreviewProvider {
  static var previews: some View {
    DeviceRow(
      device: DesignTimeDevice())
  }
}
