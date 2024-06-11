import SwiftUI
import Siesta

public protocol ResourceViewStyle: Sendable {
    associatedtype LoadingView: View
    associatedtype ErrorView: View
    
    @ViewBuilder
    func loadingView() -> LoadingView

    @ViewBuilder
    func errorView(errorMessage: String, canTryAgain: Bool, tryAgain: @escaping () -> Void) -> ErrorView
}

public extension ResourceViewStyle {

    @ViewBuilder
    func loadingView() -> some View {
        VStack {
            ProgressView()
        }
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    func errorView(errorMessage: String, canTryAgain: Bool, tryAgain: @escaping () -> Void) -> some View {
        VStack(spacing: 20) {
            Text(errorMessage)
            .multilineTextAlignment(.center)
            .foregroundColor(.red)
            .frame(maxWidth: 300)

            if canTryAgain {
                Button("Try again") {
                    tryAgain()
                }
            }
        }
        .frame(maxWidth: .infinity)
    }
}

extension ResourceViewStyle {
    func anyLoadingView() -> AnyView {
        AnyView(loadingView())
    }
    
    func anyErrorView(errorMessage: String, canTryAgain: Bool, tryAgain: @escaping () -> Void) -> AnyView {
        AnyView(errorView(errorMessage: errorMessage, canTryAgain: canTryAgain, tryAgain: tryAgain))
    }
}

public struct DefaultResourceViewStyle: ResourceViewStyle {
}

public extension ResourceViewStyle where Self == DefaultResourceViewStyle {
    static var defaultStyle: DefaultResourceViewStyle { DefaultResourceViewStyle() }
}

public extension EnvironmentValues {
    var resourceViewStyle: any ResourceViewStyle {
        get { self[ResourceViewStyleKey.self] }
        set { self[ResourceViewStyleKey.self] = newValue }
    }
}

private struct ResourceViewStyleKey: EnvironmentKey {
    static let defaultValue: any ResourceViewStyle = DefaultResourceViewStyle()
}

public extension View {
    func resourceViewStyle<S: ResourceViewStyle>(_ style: S) -> some View {
        environment(\.resourceViewStyle, style)
    }
}
