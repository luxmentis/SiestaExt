import Siesta
import Foundation

/**
Immutable state of a resource at a point in time - used for Combine publishers, but also suitable for other reactive
frameworks such as RxSwift, for which there is an optional Siesta extension.

Note the strong typing. If there is content but it's not of the type specified, `latestError` is populated
with a cause of `RequestError.Cause.WrongContentType`.
*/
public struct ResourceState<T>: LoadableState {
    public let content: T?
    public let latestData: Entity<Any>?
    public let latestError: RequestError?
    public let timestamp: TimeInterval
    public let isLoading: Bool
    public let isRequesting: Bool
    public let isUpToDate: Bool
    public let event: ResourceEvent

    public init(content: T?, latestData: Entity<Any>?, latestError: RequestError?, timestamp: TimeInterval, isLoading: Bool, isRequesting: Bool, isUpToDate: Bool, event: ResourceEvent) {
        self.content = content
        self.latestData = latestData
        self.latestError = latestError
        self.timestamp = timestamp
        self.isLoading = isLoading
        self.isRequesting = isRequesting
        self.isUpToDate = isUpToDate
        self.event = event
    }

    /// Transform state into a different content type
    public func map<Other>(transform: (T?) -> Other?) -> ResourceState<Other> {
        ResourceState<Other>(
            content: transform(content),
            latestData: latestData,
            latestError: latestError,
            timestamp: timestamp,
            isLoading: isLoading,
            isRequesting: isRequesting,
            isUpToDate: isUpToDate,
            event: event)
    }

    public static var fakeLoading: Self {
        .init(content: nil, latestData: nil, latestError: nil, timestamp: Date.timeIntervalSinceReferenceDate, isLoading: true, isRequesting: true, isUpToDate: false, event: .requested)
    }

    public static func fakeFailure(_ error: RequestError) -> Self {
        .init(content: nil, latestData: nil, latestError: error, timestamp: Date.timeIntervalSinceReferenceDate, isLoading: false, isRequesting: false, isUpToDate: false, event: .requested)
    }

    public static func fakeContent(_ value: T?) -> Self {
        .init(content: value, latestData: value.map { Entity<Any>(response: nil, content: $0) }, latestError: nil, timestamp: Date.timeIntervalSinceReferenceDate, isLoading: false, isRequesting: false, isUpToDate: true, event: .newData(.network))
    }
}

public extension Resource {
    /// The current state of the resource.
    func state<T>(event: ResourceEvent) -> ResourceState<T> {
        let content: T? = typedContent()

        var latestError = latestError
        if latestError == nil && latestData != nil && content == nil {
            latestError = .contentTypeError()
        }

        return ResourceState<T>(
            content: content,
            latestData: latestData,
            latestError: latestError,
            timestamp: timestamp,
            isLoading: isLoading,
            isRequesting: isRequesting,
            isUpToDate: isUpToDate,
            event: event
        )
    }
}

extension RequestError {
    static func contentTypeError() -> RequestError {
        RequestError(
            userMessage: "The server return an unexpected response type",
            cause: RequestError.Cause.WrongContentType())
    }
}

extension RequestError.Cause {
    public struct WrongContentType: Error {
        public init() {}
    }
}

