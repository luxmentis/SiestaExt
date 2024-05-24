import Combine

public extension Publisher {

    /// Convenience for Loadable content, when set
    func content() -> AnyPublisher<Output.Content, Failure> where Output: LoadableState {
        compactMap { $0.content }.eraseToAnyPublisher()
    }

    /// Convenience for Loadable content
    func optionalContent() -> AnyPublisher<Output.Content?, Failure> where Output: LoadableState {
        map { $0.content }.eraseToAnyPublisher()
    }
}