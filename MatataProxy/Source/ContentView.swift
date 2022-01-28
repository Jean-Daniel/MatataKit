//
//  ContentView.swift
//  MatataProxy
//
//  Created by Jean-Daniel Dupas on 19/01/2022.
//

import SwiftUI
import MatataCore

extension BluetoothProxy.State {

  var localizedString: String {
    switch (self) {
    case .disconnected:
      return "disconnected"
    case .scanning:
      return "scanning"
    case .discovering:
      return "discovering"
    case .advertising:
      return "advertising"
    case .connected:
      return "connected"
    }
  }
}

struct ContentView: View {

  @ObservedObject var proxy: BluetoothProxy

  var body: some View {
    VStack {
      Text(proxy.state.localizedString)
      Button("Connect") {
        proxy.start(services: [Service.UUID])
      }.disabled(proxy.state != .disconnected)
    }
      .padding()
  }
}

struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    ContentView(proxy: BluetoothProxy())
  }
}
