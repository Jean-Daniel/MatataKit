//
//  ViewTask.swift
//  MatataCode
//
//  Created by Jean-Daniel Dupas on 31/12/2021.
//

import SwiftUI

struct AsyncTaskViewModifier<T>: ViewModifier {

  let operation: @Sendable () async throws -> T
  @State private var block: Task<T, Error>? = nil

  func body(content: Content) -> some View {
    content.onAppear {
      if (block == nil) {
        block = Task(operation: operation)
      }
    }
    .onDisappear {
      block?.cancel()
      block = nil
    }
  }
}

struct AsyncWhenViewModifier<T>: ViewModifier {

  let shouldRun: Bool
  let operation: @Sendable () async throws -> T
  @State private var task: Task<T, Error>? = nil

  func body(content: Content) -> some View {
    content.onChange(of: shouldRun) { newValue in
      task?.cancel()
      task = nil
      if (newValue) {
        task = Task(operation: operation)
      }
    }
    .onDisappear {
      task?.cancel()
      task = nil
    }
  }
}

extension View {
  func async<T>(_ operation: @escaping @Sendable () async throws -> T) -> some View {
    modifier(AsyncTaskViewModifier(operation: operation))
  }

  func async<T>(when condition: Bool, operation: @escaping @Sendable () async throws -> T) -> some View {
    modifier(AsyncWhenViewModifier(shouldRun: condition, operation: operation))
  }

}


