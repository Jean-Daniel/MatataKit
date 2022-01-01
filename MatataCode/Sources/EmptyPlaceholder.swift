//
//  EmptyPlaceholder.swift
//  MatataCode
//
//  Created by Jean-Daniel Dupas on 28/12/2021.
//

import SwiftUI

struct EmptyStateViewModifier<EmptyContent>: ViewModifier where EmptyContent: View {
  var isEmpty: Bool
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
                                      emptyContent: @escaping () -> EmptyContent) -> some View where EmptyContent: View {
    modifier(EmptyStateViewModifier(isEmpty: isEmpty, emptyContent: emptyContent))
  }
}
