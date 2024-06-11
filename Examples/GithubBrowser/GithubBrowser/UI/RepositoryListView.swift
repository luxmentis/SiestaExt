import SwiftUI
import Siesta
import SiestaExt
import Combine

@MainActor
struct RepositoryListView: View {
    @ObservedObject var resource: TypedResource<[Repository]>

    var body: some View {
        ResourceView(resource, displayRules: [.allData, .loading]) { (repositories: [Repository]) in
            List(repositories, id: \.url) { repo in
                NavigationLink(destination: RepositoryView(owner: repo.owner.login, name: repo.name)) {
                    HStack {
                        AvatarView(user: repo.owner)

                        Text("\(repo.owner.login)/\(repo.name)")
                        .lineLimit(1)

                        Spacer()

                        if let count = repo.starCount {
                            Text("\(count) ★")
                        }
                    }
                }
            }
            .listStyle(.plain)
        }
    }
}

#Preview {
    NavigationStack {
        RepositoryListView(resource: .init(fake: [
            .init(url: "https://api.github.com/repos/luxmentis/SiestaExt", name: "SiestaExt", starCount: 2, owner: .init(login: "luxmentis", repositoriesURL: "https://api.github.com/users/luxmentis/repos", avatarURL: "https://avatars.githubusercontent.com/u/382791?v=4", name: nil), description: "SwiftUI and Combine additions to Siesta", homepage: nil, languagesURL: "https://api.github.com/repos/luxmentis/SiestaExt/languages", contributorsURL: "https://api.github.com/repos/luxmentis/SiestaExt/contributors"),
            .init(url: "https://api.github.com/repos/luxmentis/Banana", name: "Banana", starCount: 123, owner: .init(login: "luxmentis", repositoriesURL: "https://api.github.com/users/luxmentis/repos", avatarURL: "https://avatars.githubusercontent.com/u/382791?v=4", name: nil), description: "Twas brillig and the slithy toves", homepage: nil, languagesURL: "https://api.github.com/repos/luxmentis/Banana/languages", contributorsURL: "https://api.github.com/repos/luxmentis/Banana/contributors"),
        ]))
    }
}
