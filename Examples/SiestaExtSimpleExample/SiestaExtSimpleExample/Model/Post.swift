struct Post: Decodable, Identifiable {
    let id: Int
    let userId: Int
    let title: String
    let body: String

    static var fakes = [
        Post(id: 1, userId: 1, title: "Twas brillig and the slithy toves",
            body: """
                  Did gyre and gimble in the wabe:
                  All mimsy were the borogoves,
                  And the mome raths outgrabe.
                  """),
        Post(id: 2, userId: 1, title: "Beware the Jabberwock, my son!",
            body: """
                  The jaws that bite, the claws that catch!
                  Beware the Jubjub bird, and shun
                  The frumious Bandersnatch!
                  """),
        Post(id: 3, userId: 1, title: "He took his vorpal sword in hand",
            body: """
                  Long time the manxome foe he sought—
                  So rested he by the Tumtum tree
                  And stood awhile in thought.
                  """)
    ]
}
