import Foundation
import Siesta
import SiestaExt

class APIClient: ObservableObject {
    private let service = Service(
        baseURL: "https://jsonplaceholder.typicode.com",
        standardTransformers: [.text, .image]
    )

    init() {
        let jsonDecoder = JSONDecoder()

        service.configureTransformer("/posts") {
            try jsonDecoder.decode([Post].self, from: $0.content)
        }
        service.configureTransformer("/posts/*/comments") {
            try jsonDecoder.decode([Comment].self, from: $0.content)
        }
        service.configureTransformer("/users") {
            try jsonDecoder.decode([User].self, from: $0.content)
        }
    }

    func posts() -> TypedResource<[Post]> {
        service.resource("posts").typed()
    }

    func comments(postId: Int) -> TypedResource<[Comment]> {
        service.resource("posts/\(postId)/comments").typed()
    }

    func users() -> TypedResource<[User]> {
        service.resource("users").typed()
    }

    func user(id: Int) -> TypedResource<User> {
        users().transform {
            $0?.first { $0.id == id }
        }
    }
}
