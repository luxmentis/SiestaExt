import Siesta

public struct TransformedResource<FromType, ToType>: TypedResourceProtocol {
    public typealias T = ToType

    private let typedResource: any TypedResourceProtocol<FromType>
    private let transform: (FromType?) -> ToType?

    public init(resource: any TypedResourceProtocol<FromType>, transform: @escaping (FromType?) -> ToType?) {
        typedResource = resource
        self.transform = transform
    }

    public var resource: Resource { typedResource.resource }
    public var content: ToType? { transform(typedResource.content) }
}

