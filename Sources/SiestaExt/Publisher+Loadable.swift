import Combine
import CombineExt

public extension Publisher {
    /**
      Make this publisher Loadable so you can use it in a ResourceView. isLoading will be true until
     either a value or an error is emitted.

     - Parameter isReloadable: if true (the default), load() and loadIfNeeded() will resubscribe to the publisher
     - Returns: a Loadable you can pass to ResourceView
     */
    func loadable(isReloadable: Bool = true) -> LoadablePublisher<Output, Failure> {
        LoadablePublisher(self, isReloadable: isReloadable)
    }
}

/// see Publisher.loadable()
public class LoadablePublisher<Content, E: Error>: Loadable {
    @Published public private(set) var state: SimpleLoadableState<Content, E>

    public let isReloadable: Bool

    private var reloadSubject = PassthroughSubject<Void, Never>()
    private var subs = [AnyCancellable]()

    init<P: Publisher>(_ p: P, isReloadable: Bool) where P.Output == Content, P.Failure == E {
        state = SimpleLoadableState(isLoading: true, content: nil, latestError: nil)
        self.isReloadable = isReloadable

        Publishers.Merge(Just(()), reloadSubject)
        .flatMapLatest { p.materialize() }
        .sink { [weak self] in
            guard let self = self else { return }
            switch $0 {
                case .value(let v):
                    state.content = v
                    state.isLoading = false
                case .failure(let e):
                    state.latestError = e
                    state.isLoading = false
                case .finished: break
            }
        }
        .store(in: &subs)
    }

    public func statePublisher() -> AnyPublisher<LS, Never> { $state.eraseToAnyPublisher() }

    public func loadIfNeeded() { load() }

    public func load() {
        if isReloadable {
            reloadSubject.send(())
        }
    }
}