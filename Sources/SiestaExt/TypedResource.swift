import Siesta

public extension Resource {
    /// A strongly typed wrapper.
    func typed<T>() -> TypedResource<T> {
        .init(self)
    }

    /// A strongly typed wrapper. This version is useful if type inference is failing you.
    func typed<T>(_ type: T.Type) -> TypedResource<T> {
        .init(self)
    }
}

/**
 A strongly typed wrapper around a Resource.
 */
public struct TypedResource<T>: TypedResourceProtocol {
    public let resource: Resource

    public init(_ resource: Resource) { self.resource = resource }

    public var content: T? { resource.typedContent() }
}
