import Siesta
import Combine
import Foundation

/**
Combine extensions for Resource.

For usage examples see `CombineSpec.swift`.
*/
extension TypedResourceProtocol {
    /**
    The changing state of the resource, corresponding to the resource's events.

    Note that content is typed; you'll get an error (in `latestError`) if your resource doesn't produce
    the type you specify.

    Subscribing to this publisher triggers a call to `loadIfNeeded()`, which is probably what you want.

    As with non-reactive Siesta, you'll immediately get an event (`observerAdded`) describing the current
    state of the resource.

    The publisher will never complete. Please dispose of your subscriptions appropriately otherwise you'll have
    a permanent reference to the resource.

    Events are published on the main thread.
    */
    public func statePublisher() -> ResourceStatePublisher<T> {
        resource.loadIfNeeded()

        let observableResource = observable()

        let p = observableResource.$state
        .compactMap { $0 }
        .handleEvents(receiveOutput: { _ in
            // Retain observableResource for the life of any subscriptions (subscribing to a published member does not cause retention):
            _ = observableResource
        })
        .receive(on: DispatchQueue.main)

        return ResourceStatePublisher(publisher: p)
    }

    /// Just the content, when present. See also `statePublisher()`.
    public func contentPublisher() -> AnyPublisher<T, Never> {
        statePublisher().content()
    }

    /// The content, if it's present, otherwise nil. You'll get output from this for every event.
    /// See also `statePublisher()`.
    public func optionalContentPublisher() -> AnyPublisher<T?, Never> {
        statePublisher().optionalContent()
    }

    public func anyResourceStatePublisher() -> ResourceStatePublisher<Any> {
        ResourceStatePublisher(publisher: statePublisher().map { $0.map { $0 } })
    }
}

// MARK: - Requests

extension Resource {
    /**
    These methods produce cold observables - the request isn't started until subscription time. This will often be what
    you want, and you should at least consider preferring these methods over the Request publishers.

    Publisher for a request that doesn't return data.
    */
    public func requestPublisher(createRequest: @escaping (Resource) -> Request) -> AnyPublisher<Void, RequestError> {
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
    public func dataRequestPublisher<T>(createRequest: @escaping (Resource) -> Request) -> AnyPublisher<T, RequestError> {
        Deferred {
            Just(())
            .receive(on: DispatchQueue.main)
            .setFailureType(to: RequestError.self)
            .flatMap { _ in createRequest(self).dataPublisher() }
        }
        .eraseToAnyPublisher()
    }
}
