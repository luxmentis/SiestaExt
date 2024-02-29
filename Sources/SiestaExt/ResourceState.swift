import Siesta
import Foundation

/**
Immutable state of a resource at a point in time - used for Combine publishers, but also suitable for other reactive
frameworks such as RxSwift, for which there is an optional Siesta extension.

Note the strong typing. If there is content but it's not of the type specified, `latestError` is populated
with a cause of `RequestError.Cause.WrongContentType`.
*/
public struct ResourceState<T> {
    public let content: T?
    public let latestData: Entity<Any>?
    public let latestError: RequestError?
    public let timestamp: TimeInterval
    public let isLoading: Bool
    public let isRequesting: Bool
    public let isUpToDate: Bool
    public let event: ResourceEvent

    /// Transform state into a different content type
    public func map<Other>(transform: (T) -> Other) -> ResourceState<Other> {
        ResourceState<Other>(
            content: content.map { transform($0) },
            latestData: latestData,
            latestError: latestError,
            timestamp: timestamp,
            isLoading: isLoading,
            isRequesting: isRequesting,
            isUpToDate: isUpToDate,
            event: event)
    }
}

public extension TypedResourceProtocol {
    /// The current state of the resource.
    func state(event: ResourceEvent) -> ResourceState<T> {
        var latestError = resource.latestError
        if latestError == nil && resource.latestData != nil && content == nil {
            latestError = .contentTypeError()
        }

        return ResourceState<T>(
            content: content,
            latestData: resource.latestData,
            latestError: latestError,
            timestamp: resource.timestamp,
            isLoading: resource.isLoading,
            isRequesting: resource.isRequesting,
            isUpToDate: resource.isUpToDate,
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

