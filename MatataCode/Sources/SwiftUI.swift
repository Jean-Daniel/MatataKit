//
//  SwiftUI.swift
//  MatataCode
//
//  Created by Jean-Daniel Dupas on 02/01/2022.
//

import SwiftUI

extension Image {

  #if canImport(AppKit)
  init(named name: NSImage.Name) {
    guard let image = NSImage(named: name) else {
      self.init(name)
      return
    }
    self.init(nsImage: image)
  }
  #endif

}

struct EmptyStateViewModifier<EmptyContent>: ViewModifier where EmptyContent: View {
  let isEmpty: Bool
  let emptyContent: () -> EmptyContent

  func body(content: Content) -> some View {
    if isEmpty {
      VStack {
        emptyContent()
      }.frame(maxHeight: .infinity)
    }
    else {
      content
    }
  }
}

extension View {
  func emptyPlaceholder<EmptyContent>(_ isEmpty: Bool,
                                      @ViewBuilder emptyContent: @escaping () -> EmptyContent) -> some View where EmptyContent: View {
    modifier(EmptyStateViewModifier(isEmpty: isEmpty, emptyContent: emptyContent))
  }
}
