import SwiftUI

struct AvatarView: View {
    let user: User

    var body: some View {
        AsyncImage(url: URL(string: user.avatarURL), content: {
            if let image = $0.image {
                image
                .resizable()
                .aspectRatio(contentMode: .fit)
            }
        })
        .frame(width: 50, height: 50)
    }
}