import SwiftUI
import Siesta

/**
 An ObservableObject that publishes a resource's state. Makes a good @ObservedObject if you want to
 operate at that level.
 */
public class ObservableResource<T>: ObservableObject, Equatable, Hashable {
    let resource: any TypedResourceProtocol<T>
    @Published public private(set) var state: ResourceState<T>?

    public init(_ resource: any TypedResourceProtocol<T>) {
        self.resource = resource

        resource.resource.addObserver(owner: self) { [weak self] (_, event) in
            guard let self = self else { return }
            self.state = self.resource.state(event: event)
        }
    }

    deinit {
        resource.resource.removeObservers(ownedBy: self)
    }

    public static func ==(lhs: ObservableResource, rhs: ObservableResource) -> Bool { lhs.resource.resource == rhs.resource.resource }

    public func hash(into hasher: inout Hasher) { resource.resource.hash(into: &hasher) }
}


public extension TypedResourceProtocol {
    func observable() -> ObservableResource<T> {
        .init(self)
    }
}

