import SwiftUI
import Siesta

/*
 todo Use cases:
 - Data view is always displayed, but with empty fields if nothing loaded, so that the right amount of space is allocated. This view should be an overlay in that case.
 */
// todo better formatting for stock stuff

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
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }

            case .error(let error):
                VStack(spacing: 10) {
                    Text(error.userMessage)
                    .foregroundColor(.red)

                    Button("Try again") {
                        tryAgain()
                    }
                }
                .padding()

            case .data(let data):
                dataContent(data)
        }
    }
}

public protocol ResourceViewProtocol: View {
    associatedtype DataContent: View
    associatedtype Content: View

    var dataContent: ([Any?]) -> DataContent { get set }
    var model: ResourceStatusModel { get set }
    init(model: ResourceStatusModel, dataContent: @escaping ([Any?]) -> DataContent)
    func content(display: ResourceStatusModel.Display) -> Content
}

extension ResourceViewProtocol {

    public init(resources: [any TypedResourceProtocol], statusDisplay: [ResourceStatusModel.Rule], @ViewBuilder content: @escaping ([Any?]) -> DataContent) {
        self.init(model: ResourceStatusModel(resources, displayPriority: statusDisplay), dataContent: content)
    }

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

    public init<R>(
        _ resource: R,
        statusDisplay: [ResourceStatusModel.Rule] = [.alwaysData],
        @ViewBuilder content: @escaping (R.T?) -> DataContent
    ) where R: TypedResourceProtocol {
        self.init(resources: [resource], statusDisplay: statusDisplay) { data in
            content(data[0] as? R.T)
        }
    }

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

    @ViewBuilder public var body: some View {
        if let display = model.display {
            content(display: display)
        }
    }

    public func tryAgain() { model.resources.forEach { $0.resource.loadIfNeeded() } }
}
