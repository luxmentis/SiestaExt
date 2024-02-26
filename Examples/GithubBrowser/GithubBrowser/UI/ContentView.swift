import SwiftUI
import Siesta

struct ContentView: View {
    @ObservedObject var api = GitHubAPI

    var body: some View {
        NavigationStack {
            UserView()
            .toolbar {
                if api.isAuthenticated {
                    Button("Log out") {
                        api.logOut()
                    }
                }
                else {
                    NavigationLink("Log in", destination: LoginView())
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
