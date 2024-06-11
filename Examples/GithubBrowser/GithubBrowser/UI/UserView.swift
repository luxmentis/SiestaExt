import SwiftUI
import Siesta
import SiestaExt

@MainActor
struct UserView: View {
    @State var searchText = ""

    var body: some View {
        VStack(alignment: .leading) {
            if searchText.isEmpty {
                Text("Active Repositories")
                .font(.title)
                .padding()

                RepositoryListView(resource: GitHubAPI.activeRepositories)
            }
            else {
                ResourceView(GitHubAPI.user(searchText), displayRules: [.allData, .loading, .error]) { (user: User) in
                    HStack {
                        AvatarView(user: user)

                        VStack(alignment: .leading) {
                            Text(user.login)
                            if let name = user.name {
                                Text(name)
                            }
                        }
                    }
                    .padding()

                    RepositoryListView(resource: GitHubAPI.repositories(ownedBy: user))
                }
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)

        // todo a bit weird because is makes the toolbar disappear
        .searchable(text: $searchText, prompt: "Github username")

        #if !os(macOS)
            .navigationBarTitleDisplayMode(.inline)
        #endif
    }
}

// MARK: ------------ Previews ------------

extension UserView {
    static var everything: Self {
        var v = Self()
        v._searchText = State(initialValue: "luxmentis")
        return v
    }
    static var noName: Self {
        var v = Self()
        v._searchText = State(initialValue: "ASD")
        return v
    }
}

#Preview("Active") {
    NavigationStack {
        UserView()
    }
}
#Preview("User") {
    NavigationStack {
        UserView.everything
    }
}
#Preview("No name") {
    NavigationStack {
        UserView.noName
    }
}
