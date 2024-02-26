import Siesta
import Combine
import Foundation

extension Request {
    /**
    Be cautious with these methods - Requests are started when they're created, so we're effectively creating hot observables here.
    Consider using the `Resource.*requestPublisher()` methods, which produce cold observables - requests won't start until subscription time.

    However, if you've been handed a Request and you want to make it reactive, these methods are here for you.

    Publisher for a request that doesn't return data.
    */
    public func publisher() -> AnyPublisher<Void, RequestError> {
        dataPublisher()
    }

    /**
    Publisher for a request that returns data. Strongly typed, like the Resource publishers.

    See also `publisher()`
    */
    public func dataPublisher<T>() -> AnyPublisher<T, RequestError> {
        Future { promise in
            self.onSuccess {
                if let result = () as? T {
                    promise(.success(result))
                }
                else {
                    guard let result: T = $0.typedContent() else {
                        promise(.failure(.contentTypeError()))
                        return
                    }
                    promise(.success(result))
                }
            }

            self.onFailure { promise(.failure($0)) }
        }
        .eraseToAnyPublisher()
    }
}
