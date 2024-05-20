import SwiftUI
import Siesta

// Style: Can't use "any ResourceViewStyle" because when it comes time to render the view
// the compiler doesn't know the type, and complains that View doesn't conform to View.
// So, horribly, we have to make extra initialisers.
//
// What we really want is view modifier based styling (like buttons) but I can't see how
// to implement that without the style's methods returning AnyView. And wouldn't this cause
// problems?

public struct RV2<DataContent: View, Style: ResourceViewStyle>: View {
    @ViewBuilder private var dataContent: () -> DataContent
    @ObservedObject private var model: SimpleResourceStatusModel
    private let style: Style

    @available(iOS 17, macOS 14, *)
    public init<each R: TypedResourceProtocol>(
        _ typedResources: repeat each R,
        statusDisplay: [ResourceStatusModelRule] = [.allData],
        @ViewBuilder content: @escaping (repeat (each R).T?) -> DataContent
    ) where Style == DefaultResourceViewStyle {
        self.init(repeat each typedResources, statusDisplay: statusDisplay, style: .defaultStyle, content: content)
    }

    @available(iOS 17, macOS 14, *)
    public init<each R: TypedResourceProtocol>(
        _ typedResources: repeat each R,
        statusDisplay: [ResourceStatusModelRule] = [.allData],
        style: Style,
        @ViewBuilder content: @escaping (repeat (each R).T?) -> DataContent
    ) {
        var resources = [Resource]()
        _ = (repeat resources.append((each typedResources).resource))
        model = SimpleResourceStatusModel(resources, displayPriority: statusDisplay)

        self.style = style

        dataContent = {
            content(repeat (each typedResources).content)
        }
    }

    @available(iOS 17, macOS 14, *)
    public init<each R: TypedResourceProtocol, Content: View>(
        _ typedResources: repeat each R,
        statusDisplay: [ResourceStatusModelRule] = [.allData],
        @ViewBuilder content: @escaping (repeat (each R).T) -> Content
    ) where Style == DefaultResourceViewStyle, DataContent == Content? {
        self.init(repeat each typedResources, statusDisplay: statusDisplay, style: .defaultStyle, content: content)
    }

    @available(iOS 17, macOS 14, *)
    public init<each R: TypedResourceProtocol, Content: View>(
        _ typedResources: repeat each R,
        statusDisplay: [ResourceStatusModelRule] = [.allData],
        style: Style,
        @ViewBuilder content: @escaping (repeat (each R).T) -> Content
    ) where DataContent == Content? {
        var resources = [Resource]()
        _ = (repeat resources.append((each typedResources).resource))
        model = SimpleResourceStatusModel(resources, displayPriority: statusDisplay)

        var allContent: (repeat (each R).T)? {
            do {
                return try (repeat (each typedResources).content.throwingUnwrap())
            }
            catch {
                return nil
            }
        }

        self.style = style

        dataContent = {
            if let v = allContent {
                return content(repeat each v)
            }
            else {
                return nil
            }
        }
    }


    @ViewBuilder public var body: some View {
        switch model.display {
        case nil:
            EmptyView()

        case .loading:
            style.loadingView()

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

        case .data:
            dataContent()
        }
    }

    /// Calls loadIfNeeded() on all resources
    public func tryAgain() { model.resources.forEach { $0.loadIfNeeded() } }
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