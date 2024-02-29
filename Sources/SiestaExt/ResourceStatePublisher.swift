import Combine
import Siesta

public struct ResourceStatePublisher<T>: Publisher {
    public typealias Output = ResourceState<T>
    public typealias Failure = Never

    public let publisher: any Publisher<Output, Failure>

    public func receive<S>(subscriber: S) where S: Subscriber, Never == S.Failure, ResourceState<T> == S.Input {
        publisher.receive(subscriber: subscriber)
    }
}

extension Publisher {

    /// See ``TypedResourceProtocol.contentPublisher()``
    public func content<T>() -> AnyPublisher<T, Failure> where Output == ResourceState<T> {
        compactMap { $0.content }.eraseToAnyPublisher()
    }

    /// See ``TypedResourceProtocol.optionalContentPublisher()``
    public func optionalContent<T>() -> AnyPublisher<T?, Failure> where Output == ResourceState<T> {
        compactMap { $0.content }.eraseToAnyPublisher()
    }
}