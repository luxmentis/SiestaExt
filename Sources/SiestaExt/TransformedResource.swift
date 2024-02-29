import Siesta

/**
 Lets you transform a resource's content to some other form. Because it's a TypedResourceProtocol, you can
 use it with ResourceView, ObservableResource, etc.

 Useful if your API class wants to present a particular resource to the rest of the app in multiple different
 ways (so you can't just use a normal Siesta transformer) - perhaps because the API isn't how you'd like it to be.

 You might consider this a dirty hack, in which case don't use it :-)
 */
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

