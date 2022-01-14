//
//  ContentView.swift
//  Yorp
//
//  Created by Jean-Daniel Dupas on 26/12/2021.
//

import SwiftUI
import MatataCore

struct ContentView<Scanner: DevicesScanner, Device>: View where Scanner.Device == Device {
  
  @State
  var selection: Device.ID?
  
  @ObservedObject var devicesScanner: Scanner
  
  var body: some View {
    NavigationView {
      DeviceList(selection: $selection,
                 devicesScanner: devicesScanner)
        .frame(minWidth: 250)
        .async(when: devicesScanner.state == .poweredOn) {
          try? await devicesScanner.scan(for: .scanDuration)
        }
      EmptyView()
    }
  }
}

struct ContentView_Previews: PreviewProvider {
  
  static var previews: some View {
    ContentView(
      devicesScanner: DesignTimeScanner())
  }
}
