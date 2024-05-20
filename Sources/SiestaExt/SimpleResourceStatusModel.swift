import Siesta
import Combine
import CombineExt

/**
 Watches the state of some resources and applies a set of rules to determine what should be displayed to the user.
 See ResourceStatusModelRule for how the rules work.
 */
public class SimpleResourceStatusModel: ObservableObject {
    public let resources: [Resource]
    public let displayPriority: [ResourceStatusModelRule]

    @Published var display: Display?

    public enum Display {
        case loading, error(RequestError), data
    }

    public init(_ resources: [Resource], displayPriority: [ResourceStatusModelRule]) {
        self.resources = resources
        self.displayPriority = displayPriority

        resources.map {
            $0.typed(Any.self).statePublisher()
        }
        .combineLatest()
        .map { [weak self] in
            self?.calculateDisplay($0)
        }
        .assign(to: &$display)
    }

    /// Just for previews
    init(fake: Display?, displayPriority: [ResourceStatusModelRule]) {
        display = fake
        self.displayPriority = displayPriority
        resources = []
    }

    private func calculateDisplay(_ states: [ResourceState<Any>]) -> Display? {
        for rule in displayPriority {
            switch rule {
                case .loading:
                    if states.contains(where: { $0.isLoading }) {
                        return .loading
                    }

                case .anyData:
                    if states.contains(where: { $0.content != nil }) {
                        return .data
                    }

                case .allData:
                    if !states.contains(where: { $0.content == nil }) {
                        return .data
                    }

                case .alwaysData:
                    return .data

                case .error:
                    if let error = states.compactMap({ $0.latestError }).first {
                        return .error(error)
                    }
            }
        }
        return nil
    }
}