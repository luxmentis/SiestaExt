import Siesta

public extension Resource {
    func typed<T>() -> TypedResource<T> {
        .init(self)
    }

    func typed<T>(_ type: T.Type) -> TypedResource<T> {
        .init(self)
    }
}

public struct TypedResource<T>: TypedResourceProtocol {
    public let resource: Resource

    public init(_ resource: Resource) { self.resource = resource }

    public var content: T? { resource.typedContent() }
}
