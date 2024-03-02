import SwiftUI
import Combine

/**
 A view that's rendered whenever a publisher has output. Not directly Siesta-related, but it's useful.
 */
@MainActor
public struct PublisherView<P: Publisher, Content: View>: View where P.Failure == Never {
    let publisher: P
    let content: (P.Output?) -> Content
    @State private var data: P.Output?

    public init<C: View>(_ publisher: P, @ViewBuilder content: @escaping (P.Output) -> C)  where Content == Group<C?> {
        self.publisher = publisher
        self.content = { (data: P.Output?) in
            Group {
                if let data {
                    content(data)
                }
            }
        }
    }

    public init(_ publisher: P, @ViewBuilder content: @escaping (P.Output?) -> Content) {
        self.publisher = publisher
        self.content = content
    }

    @ViewBuilder public var body: some View {
        content(data)
        .onReceive(publisher) {
            data = $0
        }
    }
}
