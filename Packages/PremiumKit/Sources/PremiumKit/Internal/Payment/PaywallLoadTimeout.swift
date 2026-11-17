import Foundation

/// Bounds the caller's wait, not the lifetime of a non-cooperative SDK operation.
/// Operations must return values only; publishing belongs to the winning caller.
@MainActor
func withPaywallLoadTimeout<Value>(
    seconds: Double,
    operation: @escaping @MainActor () async throws -> Value
) async throws -> Value {
    let delivery = PaywallLoadDelivery<Value>()
    return try await withTaskCancellationHandler {
        try await withCheckedThrowingContinuation { continuation in
            delivery.install(continuation)
            let worker = Task { @MainActor in
                do {
                    try Task.checkCancellation()
                    delivery.finish(.success(try await operation()))
                } catch {
                    delivery.finish(.failure(error))
                }
            }
            let timer = Task.detached {
                do {
                    try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
                    delivery.finish(.failure(PaywallLoadError.timeout(seconds: seconds)))
                } catch {
                    // The winner cancels the timer.
                }
            }
            delivery.install(tasks: [worker, timer])
        }
    } onCancel: {
        delivery.finish(.failure(CancellationError()))
    }
}

/// Cancellation can arrive before continuation/task installation. Keep the first
/// result under the lock, then resume/cancel outside it (including late installs).
private final class PaywallLoadDelivery<Value>: @unchecked Sendable {
    private let lock = NSLock()
    private var result: Result<Value, Error>?
    private var continuation: CheckedContinuation<Value, Error>?
    private var tasks: [Task<Void, Never>] = []

    func install(_ continuation: CheckedContinuation<Value, Error>) {
        lock.lock()
        let result = self.result
        if result == nil {
            self.continuation = continuation
        }
        lock.unlock()
        if let result {
            continuation.resume(with: result)
        }
    }

    func install(tasks: [Task<Void, Never>]) {
        lock.lock()
        let finished = result != nil
        if !finished {
            self.tasks = tasks
        }
        lock.unlock()
        if finished {
            for task in tasks {
                task.cancel()
            }
        }
    }

    func finish(_ result: Result<Value, Error>) {
        lock.lock()
        guard self.result == nil else {
            lock.unlock()
            return
        }
        self.result = result
        let continuation = self.continuation
        let tasks = self.tasks
        self.continuation = nil
        self.tasks = []
        lock.unlock()
        continuation?.resume(with: result)
        for task in tasks {
            task.cancel()
        }
    }
}
