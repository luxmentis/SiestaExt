struct Comment: Decodable, Identifiable {
    let id: Int
    let name: String
    let email: String
    let body: String

    static var fakes = [
        Comment(id: 1, name: "Persephone", email: "p@there.com", body: "Well, I'm not so sure."),
        Comment(id: 2, name: "Venetia", email: "v@here.com", body: "Well, I certainly am."),
    ]
}