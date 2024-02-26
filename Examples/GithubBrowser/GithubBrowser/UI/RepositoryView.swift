import SwiftUI
import Siesta
import SiestaExt

struct RepositoryView: View {
    let owner: String
    let name: String

    @State private var isStarAnimating = false {
        didSet {
            starRotation = isStarAnimating ? 360 : 0
        }
    }
    @State private var starRotation = 0.0

    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                ResourceView(GitHubAPI.repository(ownedBy: owner, named: name), statusDisplay: .standard) { (repository: Repository) in
                    VStack(alignment: .leading) {
                        ResourceView(GitHubAPI.currentUserStarred(repository), statusDisplay: .noError) { (isStarred: Bool) in
                            HStack {
                                Text(isStarred ? "★" : "☆")
                                .rotationEffect(.degrees(starRotation))
                                .animation(
                                    isStarAnimating ? .linear.speed(0.2).repeatForever(autoreverses: false) : .default,
                                    value: isStarAnimating
                                )

                                Button(isStarred ? "Unstar" : "Star") {
                                    isStarAnimating = true

                                    GitHubAPI.setStarred(!isStarred, repository: repository)
                                    .onCompletion { _ in
                                        isStarAnimating = false
                                    }
                                }

                                if let count = repository.starCount {
                                    Text("\(count)")
                                }
                            }
                        }
                        .padding(.bottom, 20)

                        if let description = repository.description {
                            Text(description)
                            .padding(.bottom, 20)
                        }


                        if let resource = GitHubAPI.languages(repository) {
                            Text("Languages").font(.title3).padding(.bottom, 5)

                            ResourceView(resource, statusDisplay: .noError) { (lang: [String: Int]) in
                                Text("\(lang.keys.joined(separator: " • "))")
                            }
                            .padding(.bottom, 20)
                        }


                        if let resource = GitHubAPI.contributors(repository) {
                            Text("Contributors").font(.title3).padding(.bottom, 5)

                            ResourceView(resource, statusDisplay: .noError) { (users: [User]) in
                                VStack(alignment: .leading, spacing: 5) {
                                    ForEach(users, id: \.login) {
                                        Text($0.login)
                                    }
                                }
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                Spacer()
            }
            .padding()
        }
        #if !os(macOS)
        .navigationBarTitle(name)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }
}

#Preview("Siesta") {
    NavigationStack {
        RepositoryView(owner: "bustoutsolutions", name: "Siesta")
    }
}

#Preview("Narrow") {
    NavigationStack {
        RepositoryView(owner: "KDE", name: "krdc")
    }
}
