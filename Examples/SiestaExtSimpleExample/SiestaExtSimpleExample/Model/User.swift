struct User: Decodable {
    let id: Int
    let name: String
    let email: String
    
    static let fake = User(id: 1, name: "Tarquin", email: "t@where.com")
}
