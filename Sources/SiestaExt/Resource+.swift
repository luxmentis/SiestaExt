import Siesta
import Combine
import Foundation

/**
Combine extensions for Resource.

For usage examples see `CombineSpec.swift`.
*/
public extension Resource {

    /// Request with a json request body. Nothing to do with Combine, but everyone needs this.
    func request<T>(_ method: Siesta.RequestMethod, json: T, jsonEncoder: JSONEncoder = JSONEncoder(), requestMutation: @escaping Siesta.Resource.RequestMutation = { _ in }) throws -> Request where T: Encodable {
        let data = try jsonEncoder.encode(json)
        return request(method, data: data, contentType: "application/json", requestMutation: requestMutation)
    }

    /// A strongly typed wrapper.
    func typed<T>() -> TypedResource<T> {
        .init(self)
    }

    /// A strongly typed wrapper. This version is useful if type inference is failing you.
    func typed<T>(_ type: T.Type) -> TypedResource<T> {
        .init(self)
    }

    /**
    The changing state of the resource, corresponding to the resource's events.

    Subscribing to this publisher triggers a call to `loadIfNeeded()`, which is probably what you want.

    As usual in Siesta, you'll immediately get an event (`observerAdded`) describing the current
    state of the resource.

    The publisher will never complete. Please dispose of your subscriptions appropriately otherwise you'll have
    a permanent reference to the resource.

    Events are published on the main thread.
    */
    func statePublisher<T>() -> AnyPublisher<ResourceState<T>, Never> {
        typed(T.self).statePublisher()
    }

    /// Just the content, when present. See also `statePublisher()`.
    func contentPublisher<T>() -> AnyPublisher<T, Never> {
        statePublisher().content()
    }

    /// The content, if it's present, otherwise nil. You'll get output from this for every event.
    /// See also `statePublisher()`.
    func optionalContentPublisher<T>() -> AnyPublisher<T?, Never> {
        statePublisher().optionalContent()
    }
}


// MARK: - Requests

public extension Resource {
    /**
    These methods produce cold observables - the request isn't started until subscription time. This will often be what
    you want, and you should at least consider preferring these methods over the Request publishers.

    Publisher for a request that doesn't return data.
    */
    func requestPublisher(createRequest: @escaping (Resource) -> Request) -> AnyPublisher<Void, RequestError> {
        Deferred {
            Just(())
            .receive(on: DispatchQueue.main)
            .setFailureType(to: RequestError.self)
            .flatMap { _ in createRequest(self).publisher() }
        }
        .eraseToAnyPublisher()
    }

    /**
    Publisher for a request that returns data. Strongly typed, like the Resource publishers.

    See also `requestPublisher()`
    */
    func dataRequestPublisher<T>(createRequest: @escaping (Resource) -> Request) -> AnyPublisher<T, RequestError> {
        Deferred {
            Just(())
            .receive(on: DispatchQueue.main)
            .setFailureType(to: RequestError.self)
            .flatMap { _ in createRequest(self).dataPublisher() }
        }
        .eraseToAnyPublisher()
    }
}
