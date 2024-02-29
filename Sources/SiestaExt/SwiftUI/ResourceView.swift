import SwiftUI
import Siesta

/**
 Displays the content of the supplied resource(s). Also, by passing the statusDisplay parameter you'll get
 a progress spinner, error display and a Try Again button. See ResourceStatusModel.Rule for how you
 control the relative priorities of these.

 You might wish to implement the rendering of status information yourself, in which case you should write
 your own version of this struct. You won't have much code to write as most of the useful functionality
 is factored out, so you get to reuse it. Just copy this implementation to get started.
 */
public struct ResourceView<DataContent: View>: ResourceViewProtocol {
    public var dataContent: ([Any?]) -> DataContent
    @ObservedObject public var model: ResourceStatusModel

    public init(model: ResourceStatusModel, dataContent: @escaping ([Any?]) -> DataContent) {
        self.model = model
        self.dataContent = dataContent
    }

    @ViewBuilder public func content(display: ResourceStatusModel.Display) -> some View {
        switch display {
            case .loading:
                VStack() {
                    ProgressView()
                }
                .frame(maxWidth: .infinity)

            case .error(let error):
                VStack(spacing: 20) {
                    Text(error.userMessage)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.red)
                    .frame(maxWidth: 300)

                    Button("Try again") {
                        tryAgain()
                    }
                }
                .frame(maxWidth: .infinity)

            case .data(let data):
                dataContent(data)
        }
    }
}

/// Implement this if writing your own ResourceView. Just copy ResourceView's implementation as a starting point.
public protocol ResourceViewProtocol: View {
    associatedtype DataContent: View
    associatedtype Content: View

    var dataContent: ([Any?]) -> DataContent { get set }
    var model: ResourceStatusModel { get set }
    init(model: ResourceStatusModel, dataContent: @escaping ([Any?]) -> DataContent)
    func content(display: ResourceStatusModel.Display) -> Content
}

extension ResourceViewProtocol {

    /// Displays the content of the resource if it's loaded, otherwise nothing unless you supply statusDisplay.
    public init<R, C: View>(
        _ resource: R,
        statusDisplay: [ResourceStatusModel.Rule] = [ResourceStatusModel.Rule.allData],
        @ViewBuilder content: @escaping (R.T) -> C
    ) where R: TypedResourceProtocol, DataContent == Group<C?> {

        self.init(resources: [resource], statusDisplay: statusDisplay) { data in
            Group {
                if let data = data[0] as? R.T {
                    content(data)
                }
            }
        }
    }

    /// Use this version if you want to display something of your own when your data isn't loaded yet. If using statusDisplay, make sure you use compatible rules - probably [.error, .alwaysData].
    public init<R>(
        _ resource: R,
        statusDisplay: [ResourceStatusModel.Rule] = [.alwaysData],
        @ViewBuilder content: @escaping (R.T?) -> DataContent
    ) where R: TypedResourceProtocol {
        self.init(resources: [resource], statusDisplay: statusDisplay) { data in
            content(data[0] as? R.T)
        }
    }

    /// Displays the content of both resources once they're both loaded.
    public init<R1, R2, C: View>(
        _ resource1: R1,
        _ resource2: R2,
        statusDisplay: [ResourceStatusModel.Rule] = [.allData],
        @ViewBuilder content: @escaping (R1.T, R2.T) -> C
    ) where R1: TypedResourceProtocol, R2: TypedResourceProtocol, DataContent == Group<C?> {
        self.init(resources: [resource1, resource2], statusDisplay: statusDisplay) { data in
            Group {
                if let v1 = data[0] as? R1.T, let v2 = data[1] as? R2.T {
                    content(v1, v2)
                }
            }
        }
    }

    /// Displays the content of all resources once they're all loaded.
    public init<R1, R2, R3, C: View>(
        _ resource1: R1,
        _ resource2: R2,
        _ resource3: R3,
        statusDisplay: [ResourceStatusModel.Rule] = [.allData],
        @ViewBuilder content: @escaping (R1.T, R2.T, R3.T) -> C
    ) where R1: TypedResourceProtocol, R2: TypedResourceProtocol, R3: TypedResourceProtocol, DataContent == Group<C?> {
        self.init(resources: [resource1, resource2, resource3], statusDisplay: statusDisplay) { data in
            Group {
                if let v1 = data[0] as? R1.T, let v2 = data[1] as? R2.T, let v3 = data[2] as? R3.T {
                    content(v1, v2, v3)
                }
            }
        }
    }

    /// The ultimate in flexibility - loads as many resources as you like, and renders content regardless of whether loaded (dependent on statusDisplay if you pass that of course). You pay for flexibility by having to cast to the data types you want.
    public init(resources: [any TypedResourceProtocol], statusDisplay: [ResourceStatusModel.Rule], @ViewBuilder content: @escaping ([Any?]) -> DataContent) {
        self.init(model: ResourceStatusModel(resources, displayPriority: statusDisplay), dataContent: content)
    }

    @ViewBuilder public var body: some View {
        if let display = model.display {
            content(display: display)
        }
    }

    /// Calls loadIfNeeded() on all resources
    public func tryAgain() { model.resources.forEach { $0.resource.loadIfNeeded() } }
}


#Preview("Error") {
    previewContainer {
        ResourceView(model: ResourceStatusModel(fake: .error(RequestError(response: nil, content: nil, cause: nil, userMessage: "Something really didn't work out, I'm sorry to say")), displayPriority: .standard)) { _ in EmptyView() }
    }
}

#Preview("Loading") {
    previewContainer {
        ResourceView(model: ResourceStatusModel(fake: .loading, displayPriority: .standard)) { _ in EmptyView() }
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
    .buttonStyle(.borderedProminent)
}
