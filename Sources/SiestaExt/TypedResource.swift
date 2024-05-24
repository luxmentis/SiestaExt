import SwiftUI
import Siesta
import Combine

/**
 A strongly-typed, observable wrapper around Resource.

 You can either:
 - Simply create one and pass it to ResourceView (which will retain it for you).
 - Observe $content or $state; make sure you retain this object if you do that. It makes
   a good @ObservableObject if you're in SwiftUI (although that's optional if you're using
   ResourceView).
 - Use its publisher(s) directly. This object will be retained for you as long as a
   publisher has subscriptions.

 Calls loadIfNeeded when created.

 You can also create fakes, e.g. for SwiftUI previews. This is why resource is an optional.
 */
public class TypedResource<T>: Loadable, ObservableObject, Equatable, Hashable, Identifiable {
    public typealias LS = ResourceState<T>

    public let id = UUID()

    /**
     The latest state of the resource.
     You wouldn't normally expect to set this yourself, but it might be useful for tests/previews.
     */
    @Published public var state: ResourceState<T> {
        didSet { content = state.content }
    }

    /// A convenience for observing content directly. The same as `state.content`.
    @Published public private(set) var content: T?

    /// The wrapped resource. Will be nil for fakes; being optional is a slight inconvenience if you don't care about fakes.
    public private(set) var resource: Resource?

    private var subs = [AnyCancellable]()

    /// The normal case.
    public convenience init(_ resource: Resource) {
        // This initial state is a bit of a cheat, but it's about to happen when we add the observer anyway,
        // and it saves making state an optional.
        self.init(resource: resource, state: resource.state(event: .observerAdded))

        resource.addObserver(owner: self) { [weak self] (_, event) in
            guard let self = self else { return }
            self.state = resource.state(event: event)
        }

        resource.loadIfNeeded()
    }

    fileprivate init(resource: Resource?, state: ResourceState<T>) {
        self.resource = resource
        self.state = state
        content = state.content
    }

    /**
     Special case for when what the server delivers you doesn't match what you want to present to
     the rest of the app in your API class.

     For example, say the API delivers all users at once, but you want the app to be able to ask for
     a single user, you might:
     ```
     func user(id: Int) -> TypedResource<User> {
         allUsersResource.transform { $0.first { $0.id == id } }
     }
     ```

     (You might consider this a dirty hack, in which case don't use it!)

     Provides access to the underlying Resource so you can call loadIfNeeded() it etc. (But of course
     if you access the resource's content directly it won't have been transformed.)
     */
    public func transform<ToType>(transform: @escaping (T?) -> ToType?) -> TypedResource<ToType> {
        TypedResource<ToType>(transforming: self, transform: transform)
    }

    private init<FromType>(transforming underlying: TypedResource<FromType>, transform: @escaping (FromType?) -> T?) {
        resource = underlying.resource
        state = underlying.state.map(transform: transform)
        content = state.content

        underlying.$state.sink { [weak self] in
            guard let self = self else { return }
            self.state = $0.map(transform: transform)
            // Retain underlying for the life of this object (subscribing to a published member does not cause retention):
            _ = underlying
        }
        .store(in: &subs)
    }

    /**
     An alternative to observing $state. Can be more convenient as it retains this object for the life
     of any subscriptions.

     The publisher will never complete. Please dispose of your subscriptions appropriately otherwise you'll have
     a permanent reference to the resource.
     */
    public func statePublisher() -> AnyPublisher<ResourceState<T>, Never> {
        $state
        .handleEvents(receiveOutput: { _ in
            // Retain self for the life of any subscriptions (subscribing to a published member does not cause retention):
            _ = self
        })
        .receive(on: DispatchQueue.main)
        .eraseToAnyPublisher()
    }

    deinit {
        resource?.removeObservers(ownedBy: self)
    }

    /// Type-erased
    public func any() -> TypedResource<Any> {
        TypedResource<Any>(transforming: self) { $0 }
    }

    public static func ==(lhs: TypedResource<T>, rhs: TypedResource<T>) -> Bool {
        lhs.id == rhs.id
    }

    public func hash(into hasher: inout Hasher) {
        id.hash(into: &hasher)
    }

    public var isReloadable: Bool { true }

    public func loadIfNeeded() { resource?.loadIfNeeded() }

    public func load() { resource?.load() }
}

/// Fakes
public extension TypedResource {
    /// A resource with fake data for use in previews. Also available on Optional<TypedResource> as chances are you're passing an optional to your View.
    static func fake(_ content: T?) -> TypedResource<T> { .init(fake: content) }

    /// A fake resource in error state for use in previews. Also available on Optional<TypedResource> as chances are you're passing an optional to your View.
    static func fakeFailure(_ error: RequestError) -> TypedResource<T> { .init(fakeState: .fakeFailure(error)) }

    /// A fake resource in loading state for use in previews. Also available on Optional<TypedResource> as chances are you're passing an optional to your View.
    static func fakeLoading() -> TypedResource<T> { .init(fakeState: .fakeLoading) }

    /// prefer `static func fake()`
    convenience init(fake: T?) {
        self.init(fakeState: .fakeContent(fake))
    }

    /// prefer fake() or fakeLoading() if they suit, otherwise use this for flexibility.
    convenience init(fakeState: ResourceState<T>) {
        self.init(resource: nil, state: fakeState)
    }
}

public extension Optional {
    /// A resource with fake data for use in previews. Defined on Optional<TypedResource> as chances are you're passing an optional to your View.
    static func fake<T>(_ content: T?) -> TypedResource<T> where Wrapped == TypedResource<T> {
        .fake(content)
    }

    /// A fake resource in loading state for use in previews. Defined on Optional<TypedResource> as chances are you're passing an optional to your View.
    static func fakeLoading<T>() -> TypedResource<T> where Wrapped == TypedResource<T> {
        .fakeLoading()
    }
}