import Siesta
import Combine
import CombineExt

/**
 Watches the state of some resources and applies a set of rules to determine what should be displayed to the user.
 See ResourceStatusModel.Rule for how the rules work.
 */
public class ResourceStatusModel: ObservableObject {
    public let resources: [any TypedResourceProtocol]
    public let displayPriority: [Rule]

    @Published var display: Display?

    public enum Display {
        case loading, error(RequestError), data([Any?])
    }

    public init(_ resources: [any TypedResourceProtocol], displayPriority: [Rule]) {
        self.resources = resources
        self.displayPriority = displayPriority

        resources.map { $0.anyResourceStatePublisher() }
        .combineLatest()
        .map { [weak self] in self?.calculateDisplay($0) }
        .assign(to: &$display)
    }

    /// Just for previews
    init(fake: Display?, displayPriority: [Rule]) {
        display = fake
        self.displayPriority = displayPriority
        resources = []
    }

    private func calculateDisplay(_ states: [ResourceState<Any>]) -> Display? {
        for rule in displayPriority {
            switch rule {
                case .loading:
                    if states.contains(where: { $0.isLoading }) { return .loading }

                case .anyData:
                    if states.contains(where: { $0.content != nil }) {
                        return .data(states.map { $0.content })
                    }

                case .allData:
                    if !states.contains(where: { $0.content == nil }) {
                        return .data(states.map { $0.content })
                    }

                case .alwaysData:
                    return .data(states.map { $0.content })

                case .error:
                    if let error = states.compactMap({ $0.latestError }).first {
                        return .error(error)
                    }
            }
        }
        return nil
    }

    /**
     You supply an array of rules in order of priority. For example, [.loading, .error, .allData] shows a
     spinner whenever you're reloading, while [.error, .allData, .loading] favours showing whatever data you have -
     stale or not.

     Adapted from SiestaUI (which is only for iOS).
     */
    public enum Rule: String {
        /// If `Resource.isLoading` is true for any observed resources, enter the **loading** state.
        case loading

        /// If any request passed to `ResourceStatusOverlay.trackManualLoad(_:)` is still in progress,
        /// enter the **loading** state.
        // case manualLoading

        /// If `Resource.latestData` is non-nil for _any_ observed resources, enter the **success** state.
        case anyData

        /// If `Resource.latestData` is non-nil for _all_ observed resources, enter the **success** state.
        case allData

        /// Outputs whatever data is available, regardless of resource state
        case alwaysData

        /// If `Resource.latestError` is non-nil for any observed resources, enter the **error** state.
        /// If multiple observed resources have errors, pick one arbitrarily to show its error message.
        case error
    }
}

public extension Array where Element == ResourceStatusModel.Rule {
    static let standard = [ResourceStatusModel.Rule.anyData, .loading, .error]

    static let noError = [ResourceStatusModel.Rule.loading, .alwaysData]

    static let dataOnly = [ResourceStatusModel.Rule.alwaysData]
}
