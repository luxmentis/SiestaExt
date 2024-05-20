import SwiftUI
import Siesta

public protocol ResourceViewStyle {
    associatedtype LoadingView: View
    associatedtype ErrorView: View

    @ViewBuilder
    func loadingView() -> LoadingView

    @ViewBuilder
    func errorView(error: RequestError, tryAgain: @escaping () -> Void) -> ErrorView
}

public struct DefaultResourceViewStyle: ResourceViewStyle {
}

public extension ResourceViewStyle where Self == DefaultResourceViewStyle {
    static var defaultStyle: DefaultResourceViewStyle { DefaultResourceViewStyle() }
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
    func errorView(error: RequestError, tryAgain: @escaping () -> Void) -> some View {
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
    }
}
