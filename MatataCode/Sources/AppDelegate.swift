//
//  AppDelegate.swift
//  MatataCode
//
//  Created by Jean-Daniel Dupas on 29/05/2021.
//

// import os
import Combine
import MatataCore
import CoreBluetooth

import SwiftUI

@main
struct MatataCode: App {

  @StateObject var mgr = MatataCentral()

  // TODO: list of devices that should be displayed in separated windows


  var body: some Scene {
      WindowGroup {
        ContentView(devicesScanner: mgr)
      }
  }
}
