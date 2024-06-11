import SwiftUI
import Siesta

/**
 Displays the content of the supplied Resource(s). Also, by passing the displayRules parameter you'll get
 a loading spinner, error display and a Try Again button. See LoadableGroupStatusRule for how you
 control the relative priorities of these.

 See the example apps for examples of how to use this, including in previews.
 
 To build your own loading view and/or error view, implement your own `ResourceViewStyle` and adopt it
 with the view modifier `resourceViewStyle()`.

 Although originally built for Siesta resources, it's more generally useful - parts of your app might get
 data from places other than Siesta, and you can use it for anything that's Loadable. See Loadable for
 further discussion about that.
 */
@MainActor
public struct ResourceView<DataContent: View>: View {
    private var dataContent: () -> DataContent
    private var loadables: [any Loadable]
    @ObservedObject private var model: LoadableGroupStatusModel
    @Environment(\.resourceViewStyle) private var style

    /// Displays the content of the resource if it's loaded, otherwise nothing unless you supply statusDisplay.
    public init<L, C: View>(
        _ loadable: L,
        displayRules: [LoadableGroupStatusRule] = [.allData],
        @ViewBuilder content: @escaping (L.Content) -> C
    ) where L: Loadable, DataContent == Group<C?> {

        self.init([loadable], displayRules: displayRules) {
            Group {
                if let data = loadable.state.content {
                    content(data)
                }
            }
        }
    }

    /// Use this version if you want to display something of your own when your data isn't loaded yet. If using statusDisplay, make sure you use compatible rules - probably [.error, .alwaysData].
    public init<L>(
        _ loadable: L,
        displayRules: [LoadableGroupStatusRule] = [.alwaysData],
        @ViewBuilder content: @escaping (L.Content?) -> DataContent
    ) where L: Loadable {
        self.init([loadable], displayRules: displayRules) {
            content(loadable.state.content)
        }
    }

    /// Displays the content of both resources once they're both loaded.
    public init<L1, L2, C: View>(
        _ loadable1: L1,
        _ loadable2: L2,
        displayRules: [LoadableGroupStatusRule] = [.allData],
        @ViewBuilder content: @escaping (L1.Content, L2.Content) -> C
    ) where L1: Loadable, L2: Loadable, DataContent == Group<C?> {
        self.init([loadable1, loadable2], displayRules: displayRules) {
            Group {
                if let v1 = loadable1.state.content, let v2 = loadable2.state.content {
                    content(v1, v2)
                }
            }
        }
    }

    /// Displays the content of all resources once they're all loaded.
    public init<L1, L2, L3, C: View>(
        _ loadable1: L1,
        _ loadable2: L2,
        _ loadable3: L3,
        displayRules: [LoadableGroupStatusRule] = [.allData],
        @ViewBuilder content: @escaping (L1.Content, L2.Content, L3.Content) -> C
    ) where L1: Loadable, L2: Loadable, L3: Loadable, DataContent == Group<C?> {
        self.init([loadable1, loadable2, loadable3], displayRules: displayRules) {
            Group {
                if let v1 = loadable1.state.content, let v2 = loadable2.state.content, let v3 = loadable3.state.content {
                    content(v1, v2, v3)
                }
            }
        }
    }

    public init(_ loadables: [any Loadable], displayRules: [LoadableGroupStatusRule], dataContent: @escaping () -> DataContent) {
        self.loadables = loadables
        self.dataContent = dataContent
        model = LoadableGroupStatusModel(loadables, rules: displayRules)
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
                dataContent()

            case nil:
                EmptyView()
        }
    }

    /// Calls loadIfNeeded() on all resources
    public func tryAgain() {
        loadables.forEach {
            if $0.isReloadable {
                $0.loadIfNeeded()
            }
        }
    }
}


#Preview("Error") {
    previewContainer {
        let error = RequestError(response: nil, content: nil, cause: nil, userMessage: "Something really didn't work out, I'm sorry to say")
        return ResourceView([TypedResource<String>.fakeFailure(error)], displayRules: .standard) { EmptyView() }
    }
}

#Preview("Loading") {
    previewContainer {
        ResourceView([TypedResource<String>.fakeLoading()], displayRules: .standard) { EmptyView() }
    }
}

#Preview("Custom error") {
    previewContainer {
        let error = RequestError(response: nil, content: nil, cause: nil, userMessage: "Something really didn't work out, I'm sorry to say")
        return ResourceView([TypedResource<String>.fakeFailure(error)], displayRules: .standard) { EmptyView() }
            .resourceViewStyle(GarishResourceViewStyle())
    }
}

#Preview("Custom loading") {
    previewContainer {
        ResourceView([TypedResource<String>.fakeLoading()], displayRules: .standard) { EmptyView() }
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
