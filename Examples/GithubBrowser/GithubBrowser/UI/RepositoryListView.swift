import SwiftUI
import Siesta
import SiestaExt
import Combine

@MainActor
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

    @ViewBuilder var body: some View {
        RV2(resource, statusDisplay: .noError, style: DumbResourceViewStyle()) { repositories in
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

struct DumbResourceViewStyle: ResourceViewStyle {
    @ViewBuilder
    func loadingView() -> some View {
        Text("LOADING").font(.title)
    }

    @ViewBuilder
    func errorView(error: RequestError, tryAgain: @escaping () -> Void) -> some View {
        Text("ERRRRRRRR").font(.title)

    }

}