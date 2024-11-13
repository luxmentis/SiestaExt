import SwiftUI
import Siesta

/**
 Displays the content of the supplied resource(s). Also, by passing the displayRules parameter you can get
 a loading spinner, error display and a Try Again button. See LoadableGroupStatusRule for how you
 control the relative priorities of these.

 See the example apps for examples of how to use this, including in previews.
 
 To build your own loading view and/or error view, implement your own `ResourceViewStyle` and adopt it
 with the view modifier `resourceViewStyle()`.

 Although primarily built for Siesta resources, it's more generally useful - parts of your app might get
 data from places other than Siesta, and you can use it for anything that's Loadable. See Loadable for
 further discussion about that.
 */
 // todo If the resource is an ObservedObject (rather than e.g. a computed property) there's a flash on every api fetch (double flash in fact). Not sure if there's anything we can do about that, and it should(?) be unnecessary (but perhaps this is too restrictive). At least (1) look for it in the sample code and fix and (2) advise against this.
@MainActor
public struct ResourceView<ContentView: View>: View {
    private var contentView: () -> ContentView
    private var loadables: [any Loadable]
    @ObservedObject private var model: LoadableGroupStatusModel
    @Environment(\.resourceViewStyle) private var style

    /**
     With this initialiser, content will be rendered once all resources have data.

     See `LoadableGroupStatusRule` for an explanation of displayRules.
     */
    public init<each R: Loadable, Content: View>(
        _ loadables: repeat each R,
        displayRules: [LoadableGroupStatusRule] = [.allData],
        @ViewBuilder content: @escaping (repeat (each R).Content) -> Content
    ) where ContentView == Content? {

        self.loadables = [any Loadable]()
        _ = (repeat self.loadables.append((each loadables)))

        model = LoadableGroupStatusModel(self.loadables, rules: displayRules)

        var allContent: (repeat (each R).Content)? {
            do {
                return try (repeat (each loadables).state.content.throwingUnwrap())
            }
            catch {
                return nil
            }
        }

        contentView = {
            allContent.map { content(repeat each $0) }
        }
    }

    /**
     By default, the content will be rendered as soon as any of the resources has data.

     Note the only difference between this initialiser and the other is the optionality
     of the parameters to the content block.

     See `LoadableGroupStatusRule` for an explanation of displayRules. Note that the
     difference between [.anyData] (the default) and [.alwaysData] is that in the latter case
     your content will be rendered even when no resources have data.

     Note that using `.allData` doesn't really make sense in this context.
     */
    public init<each R: Loadable>(
        _ loadables: repeat each R,
        displayRules: [LoadableGroupStatusRule] = [.anyData],
        @ViewBuilder content: @escaping (repeat (each R).Content?) -> ContentView
    ) {
        self.loadables = [any Loadable]()
        _ = (repeat self.loadables.append((each loadables)))

        model = LoadableGroupStatusModel(self.loadables, rules: displayRules)

        contentView = {
            content(repeat (each loadables).state.content)
        }
    }

    @ViewBuilder public var body: some View {
        switch model.status {
            case .loading:
                style.anyLoadingView()

            case .error(let error):
                style.anyErrorView(
                    errorMessage: (error as? RequestError)?.userMessage ?? error.localizedDescription,
                    canTryAgain: loadables.contains(where: { $0.isReloadable }),
                    tryAgain: tryAgain
                )

            case .data:
                contentView()

            case nil:
                EmptyView()
        }
    }

    /// Calls loadIfNeeded() on all reloadable resources
    public func tryAgain() {
        loadables.forEach {
            if $0.isReloadable {
                $0.loadIfNeeded()
            }
        }
    }
}

fileprivate extension Optional {
    func throwingUnwrap() throws -> Wrapped {
        switch self {
            case .some(let v): return v
            case .none: throw MissingValue()
        }
    }

    struct MissingValue: Error {}
}

fileprivate extension Array where Element == LoadableGroupStatusRule {
    static let favourData = [LoadableGroupStatusRule.anyData, .loading, .error]
}

#Preview("Error") {
    previewContainer {
        let error = RequestError(response: nil, content: nil, cause: nil, userMessage: "Something really didn't work out, I'm sorry to say")
        return ResourceView(TypedResource<String>.fakeFailure(error), displayRules: .favourData) { _ in EmptyView() }
    }
}

#Preview("Loading") {
    previewContainer {
        ResourceView(TypedResource<String>.fakeLoading(), displayRules: .favourData) { _ in EmptyView() }
    }
}

#Preview("Custom error") {
    previewContainer {
        let error = RequestError(response: nil, content: nil, cause: nil, userMessage: "Something really didn't work out, I'm sorry to say")
        return ResourceView(TypedResource<String>.fakeFailure(error), displayRules: .favourData) { _ in EmptyView() }
            .resourceViewStyle(GarishResourceViewStyle())
    }
}

#Preview("Custom loading") {
    previewContainer {
        ResourceView(TypedResource<String>.fakeLoading(), displayRules: .favourData) { _ in EmptyView() }
            .resourceViewStyle(GarishResourceViewStyle())
    }
}

fileprivate struct GarishResourceViewStyle: ResourceViewStyle {
    func loadingView() -> some View {
        Text("Waiting....")
            .font(.title2)
            .foregroundColor(Color.purple)
    }

    func errorView(errorMessage: String, canTryAgain: Bool, tryAgain: @escaping () -> Void) -> some View {
        Text(errorMessage)
            .font(.title2)
            .foregroundColor(Color.green)

        if canTryAgain {
            Button("Try again", action: tryAgain)
                .foregroundColor(Color.yellow)
        }
    }
}

@ViewBuilder fileprivate func previewContainer(contents: () -> some View) -> some View {
    VStack(alignment: .leading) {
        Text("My thing")
        .font(.title)
        .padding(.bottom)

        contents()

        Spacer()
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding()
}
