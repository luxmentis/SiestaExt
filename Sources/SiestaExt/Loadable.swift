import Combine

/**
 The Siesta resource's loading/content/error/reload paradigm is a generally useful one. Parts of your
 app might load failable and/or non-immediate data from places other than Siesta - possibly not even
 from the network - and it would be a shame to lose ResourceView and co when your data comes from a
 different source.

 The Loadable and LoadableState protocols generalise the basics of Siesta's resource paradigm. If you can
 represent your loading data as Loadable(s), you can display it using ResourceView.

 Perhaps the most obvious example of this is a Combine Publisher. If you can supply one of those, you
 have nothing more to do - see Publisher.loadable().

 Otherwise, create your own task-specific implementations of Loadable and LoadableState (or use
 SimpleLoadableState).
 */
public protocol Loadable<LS> {
    associatedtype LS: LoadableState
    /// For convenience
    typealias Content = LS.Content

    /// current state
    var state: LS { get }

    /// State over time. It's a shame Swift won't let us specify @Published in a protocol and we need
    /// to implement this separately. Your implementation might just return $state if you go that way.
    func statePublisher() -> AnyPublisher<LS, Never>

    /// As per Siesta's Resource.loadIfNeeded(). Yours might just call load() if there's no distinction.
    func loadIfNeeded()

    /// Try loading again. The default implementation does nothing.
    func load()

    /// Whether load() and loadAsNeeded() are possible in your implementation. For example, ResourceView
    /// won't display a Try Again button if nothing is reloadable.
    var isReloadable: Bool { get }
}

public extension Loadable {
    /// type-erased state publisher
    func anyStatePublisher() -> AnyPublisher<SimpleLoadableState<Any, Error>, Never> {
        statePublisher().map { $0.any }.eraseToAnyPublisher()
    }

    /**
     Content when it's not nil. Retains this object for the life of any subscriptions. Never fails.
     */
    func contentPublisher() -> AnyPublisher<Content, Never> {
        statePublisher().content()
    }

    /**
     An alternative to observing $content. Can be more convenient as it retains this object for the life
     of any subscriptions. Never fails.
     */
    func optionalContentPublisher() -> AnyPublisher<Content?, Never> {
        statePublisher().optionalContent()
    }

    /**
     Outputs content when available, but fails as soon as latestError is set (regardless of whether there
     is content).
     */
    func failingContentPublisher() -> AnyPublisher<Content, LS.E> {
        statePublisher()
        .tryCompactMap {
            if let error = $0.latestError { throw error }
            return $0.content
        }
        .mapError { $0 as! LS.E }
        .eraseToAnyPublisher()
    }

    /// Default implementation; does nothing.
    func loadIfNeeded() {}

    /// Default implementation; does nothing.
    func load() {}
}

public protocol LoadableState<Content> {
    associatedtype Content
    associatedtype E: Error
    var isLoading: Bool { get }
    var content: Content? { get }
    var latestError: E? { get }
}

/// Simple data structure implementing LoadableState.
public struct SimpleLoadableState<Content, E>: LoadableState {
    public var isLoading: Bool
    public var content: Content?
    public var latestError: Error?
}

public extension LoadableState {
    /// type-erased
    var any: SimpleLoadableState<Any, Error> {
        SimpleLoadableState(isLoading: isLoading, content: content, latestError: latestError)
    }
}