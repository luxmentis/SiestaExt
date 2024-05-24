import SwiftUI
import Siesta
import SiestaExt

/// These views are just copies of the code from the main README.

struct SimpleSampleView: View {
    let repoName: String
    let owner: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("\(owner)/\(repoName)")
            .font(.title)

            // Here's the good bit:
            ResourceView(GitHubAPI.repository(ownedBy: owner, named: repoName)) { (repo: Repository) in
                // This isn't rendered until content is loaded
                if let starCount = repo.starCount {
                    Text("★ \(starCount)")
                }
                if let desc = repo.description {
                    Text(desc)
                }
            }

            Spacer()
        }
        .padding()
    }
}

#Preview("Simple") {
    SimpleSampleView(repoName: "Siesta", owner: "bustoutsolutions")
}


// MARK: ------------  ------------

struct StatusSampleView: View {
    let repoName: String
    let owner: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("\(owner)/\(repoName)")
            .font(.title)

            ResourceView(GitHubAPI.repository(ownedBy: owner, named: repoName), displayRules: .standard) { (repo: Repository) in
                if let starCount = repo.starCount {
                    Text("★ \(starCount)")
                }
                if let desc = repo.description {
                    Text(desc)
                }
            }

            Spacer()
        }
        .padding()
    }
}

#Preview("Status") {
    StatusSampleView(repoName: "Siesta", owner: "bustoutsolutions")
}

#Preview("Status (error)") {
    StatusSampleView(repoName: "exist", owner: "idonot")
}


// MARK: ------------  ------------

struct OptionalSampleView: View {
    let repoName: String
    let owner: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("\(owner)/\(repoName)")
            .font(.title)

            ResourceView(GitHubAPI.repository(ownedBy: owner, named:
            repoName)) { (repo: Repository?) in
                if let repo {
                    if let starCount = repo.starCount {
                        Text("★ \(starCount)")
                    }
                    if let desc = repo.description {
                        Text(desc)
                    }
                }
                else {
                    Text("Waiting patiently for the internet...")
                }
            }

            Spacer()
        }
        .padding()
    }
}

#Preview("Optional") {
    OptionalSampleView(repoName: "Siesta", owner: "bustoutsolutions")
}


// MARK: ------------  ------------

struct MultipleSampleView: View {
    let repoName: String
    let owner: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("\(owner)/\(repoName)")
            .font(.title)

            ResourceView(
                GitHubAPI.repository(ownedBy: owner, named: repoName),
                GitHubAPI.activeRepositories
            ) { (repo: Repository, active: [Repository]) in
                if let starCount = repo.starCount {
                    Text("★ \(starCount)")
                }
                if let desc = repo.description {
                    Text(desc)
                }

                Text("In unrelated news, the first active repository is called \(active.first!.name).")
            }

            Spacer()
        }
        .padding()
    }
}

#Preview("Multiple") {
    MultipleSampleView(repoName: "Siesta", owner: "bustoutsolutions")
}

