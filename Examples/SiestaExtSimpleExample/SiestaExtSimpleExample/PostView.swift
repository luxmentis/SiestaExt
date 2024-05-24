import SwiftUI
import SiestaExt

struct PostView: View {
    let post: Post
    let fakeUser: TypedResource<User>?
    let fakeComments: TypedResource<[Comment]>?
    @EnvironmentObject var api: APIClient

    init(post: Post, fakeUser: TypedResource<User>? = nil, fakeComments: TypedResource<[Comment]>? = nil) {
        self.post = post
        self.fakeUser = fakeUser
        self.fakeComments = fakeComments
    }

    var body: some View {
        ResourceView(fakeUser ?? api.user(id: post.userId), displayRules: .standard) { (user: User) in
            VStack {
                VStack(alignment: .leading, spacing: 20) {
                    Text(post.title).font(.title)
                    Text(post.body).font(.body)
                    Text("– \(user.name) (\(user.email))").font(.footnote)
                }
                .padding()

                ResourceView(fakeComments ?? api.comments(postId: post.id), displayRules: .standard) {
                    List($0) { comment in
                        VStack(alignment: .leading) {
                            Text(comment.body)
                            Text("– \(comment.name) (\(comment.email))").font(.footnote)
                        }
                    }
                }

                Spacer()
            }
        }
    }
}

#Preview {
    PostView(post: Post.fakes[0], fakeUser: .fake(User.fake), fakeComments: .fake(Comment.fakes))
}

#Preview("Loading comments") {
    PostView(post: Post.fakes[0], fakeUser: .fake(User.fake), fakeComments: .fakeLoading())
}
