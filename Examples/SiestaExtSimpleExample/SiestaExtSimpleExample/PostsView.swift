import SwiftUI
import SiestaExt

/**
 Displays a list of post titles.

 This is concise and fully-functional, but you probably want previews as well. See PostView
 for an example of that.
 */
struct PostsView: View {
    @EnvironmentObject var api: APIClient

    var body: some View {
        NavigationStack {
            ResourceView(api.posts(), displayRules: [.allData, .loading, .error]) {
                List($0) {
                    NavigationLink($0.title, destination: PostView(post: $0))
                }
            }
        }
    }
}
