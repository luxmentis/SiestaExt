/**
 You supply an array of rules in order of priority. For example, [.loading, .error, .allData] shows a
 spinner whenever you're reloading, while [.error, .allData, .loading] favours showing whatever data you have -
 stale or not.

 There are some convenient rule sets defined on Array<ResourceStatusModelRule> which you might find useful.

 Adapted from SiestaUI (which is only for iOS).
 */
public enum ResourceStatusModelRule: String {
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

public extension Array where Element == ResourceStatusModelRule {
    static let standard = [ResourceStatusModelRule.anyData, .loading, .error]

    static let noError = [ResourceStatusModelRule.loading, .alwaysData]

    static let dataOnly = [ResourceStatusModelRule.alwaysData]
}
