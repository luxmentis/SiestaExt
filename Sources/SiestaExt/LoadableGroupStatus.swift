import Combine
import CombineExt

/**
 Watches the state of some resources and applies a set of rules to determine what should be displayed to the user.
 See `LoadableGroupStatusRule` for how the rules work.
 */
public class LoadableGroupStatusModel: ObservableObject {
    /// The overall status of the group; this would determine what should be displayed to the user.
    /// Optional because it's possible for no rules to match the current state
    @Published var status: LoadableGroupStatus?

    init(_ loadables: [any Loadable], rules: [LoadableGroupStatusRule]) {
        loadables.map { $0.anyStatePublisher() }
        .combineLatest()
        .map { (states: [SimpleLoadableState]) in states.groupStatus(rules: rules) }
        .assign(to: &$status)
    }
}

/**
 These rules are used in a prioritised list to determine the overall display status of the group.
 For example:
 
 [.loading, .error, .allData]: indicates loading if any resources are loading, or else an error if
 any have had an error, otherwise data if all resources have it
 
 [.allData, .loading, .error]: prioritise showing data (once we have it all), even if it's out of date
 
 [.anyData, .loading, .error]: similar, but allows us to show data to the user before everything is loaded
 
 [.anyData, .error]: don't show a loading spinner - just data or errors
 
 And so on - a flexible system. There are no predefined rule lists, as what you want will depend very
 much on your use case.
 */
public enum LoadableGroupStatusRule: String, Sendable {
    /// If `isLoading` is true for any observed resources, enter the **loading** state.
    case loading

    /// If `content` is non-nil for _any_ observed resources, enter the **data** state.
    case anyData

    /// If `content` is non-nil for _all_ observed resources, enter the **data** state.
    case allData

    /// Always results in .data status, regardless of resource state
    case alwaysData

    /// If `error` is non-nil for any observed resources, enter the **error** state.
    /// If multiple observed resources have errors, pick one arbitrarily to show its error message.
    case error
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
