//
//  Time.swift
//  MatataCore
//
//  Created by Jean-Daniel Dupas on 29/12/2021.
//

import Dispatch

public struct Duration {
  public let µs: UInt64

  public var ns: UInt64 { µs * 1_000 }
  public var ms: UInt64 { µs / 1_000 }
  public var seconds: UInt { UInt(µs / 1_000_000) }

  public static func seconds(_ value: UInt) -> Duration {
    return Duration(µs: UInt64(value * 1_000_000))
  }
}

extension Task where Success == Never, Failure == Never {
  static func sleep(for duration: Duration) async throws {
    try await sleep(nanoseconds: duration.ns)
  }
}

/// Run a new task that will fail after `delay`.
/// You should ensure that the task run here responds to a cancellation event as soon as possible.
public func withTimeout<T>(
    delay: Duration,
    priority: TaskPriority? = nil,
    run task: @escaping @Sendable () async throws -> T
) async throws -> T {

  // Create a group to run the task and a timer in parallel, and see what finish first.
  return try await withThrowingTaskGroup(of: T.self) { group in
    // Schedule timeout timer
    group.addTask(priority: priority) {
      try await Task.sleep(for: delay)
      throw CancellationError()
    }

    // Schedule actual task that should run with timeout
    group.addTask(priority: priority, operation: task)

    // Make sure everything is cancel if needed
    defer { group.cancelAll() }

    guard let result = await group.nextResult() else {
      throw CancellationError()
    }

    switch result {
      // failure may be that timeout is reached or the operation throws
    case .failure(let error):
      throw error
      // only reached if `task` ends before timeout
    case .success(let result):
      return result
    }
  }
}
