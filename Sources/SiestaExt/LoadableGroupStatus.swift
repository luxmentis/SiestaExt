import Combine
import CombineExt

public class LoadableGroupStatusModel: ObservableObject {
    @Published var status: LoadableGroupStatus?

    init(_ loadables: [any Loadable], rules: [LoadableGroupStatusRule]) {
        loadables.map { $0.anyStatePublisher() }
        .combineLatest()
        .map { (states: [SimpleLoadableState]) in states.groupStatus(rules: rules) }
        .assign(to: &$status)
    }
}

public enum LoadableGroupStatusRule: String, Sendable {
    /// If `isLoading` is true for any observed resources, enter the **loading** state.
    case loading

    /// If `hasContent` is non-nil for _any_ observed resources, enter the **success** state.
    case anyData

    /// If `hasContent` is non-nil for _all_ observed resources, enter the **success** state.
    case allData

    /// Always results in .data status, regardless of state
    case alwaysData

    /// If `error` is non-nil for any observed resources, enter the **error** state.
    /// If multiple observed resources have errors, pick one arbitrarily to show its error message.
    case error
}

public extension Array where Element == LoadableGroupStatusRule {
    static let standard: [LoadableGroupStatusRule] = [.anyData, .loading, .error]

    static let noError: [LoadableGroupStatusRule] = [.loading, .alwaysData]

    static let dataOnly: [LoadableGroupStatusRule] = [.alwaysData]
}

public enum LoadableGroupStatus {
    case loading, error(Error), data
}

public extension Array where Element == SimpleLoadableState<Any, Error> {
    func groupStatus(rules: [LoadableGroupStatusRule]) -> LoadableGroupStatus? {
        for rule in rules {
            switch rule {
                case .loading:
                    if contains(where: { $0.isLoading }) { return .loading }

                case .anyData:
                    if contains(where: { $0.content != nil }) { return .data }

                case .allData:
                    if !contains(where: { $0.content == nil }) { return .data }

                case .alwaysData:
                    return .data

                case .error:
                    if let error = compactMap({ $0.latestError }).first { return .error(error) }
            }
        }
        return nil
    }
}
