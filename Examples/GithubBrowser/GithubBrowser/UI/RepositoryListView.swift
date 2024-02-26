import SwiftUI
import Siesta
import SiestaExt
import Combine

struct RepositoryListView: View {
    let user: User?

    private var resource: TypedResource<[Repository]> {
        if let user {
            GitHubAPI.user(user.login)
            .resource
            .relative(user.repositoriesURL)
            .withParam("sort", "updated")
            .typed()
        }
        else {
            GitHubAPI.activeRepositories
        }
    }

    var body: some View {
        ResourceView(resource, statusDisplay: .noError) { (repositories: [Repository]) in
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
