//
//  MatataProxyApp.swift
//  MatataProxy
//
//  Created by Jean-Daniel Dupas on 19/01/2022.
//

import SwiftUI
import MatataCore

@main
struct MatataProxyApp: App {

  @StateObject var proxy = BluetoothProxy()

  var body: some Scene {
    WindowGroup {
      ContentView(proxy: proxy)
    }
  }
}
