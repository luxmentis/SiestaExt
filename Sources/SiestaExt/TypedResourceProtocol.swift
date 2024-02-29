import Siesta
import Foundation

/**
 A strongly typed resource wrapper. Its most common manifestation is TypedResource, but you could define other
 implemtations of it (like TransformedResource) and still get the use of most things in this library,
 */
public protocol TypedResourceProtocol<T> {
    associatedtype T
    var resource: Resource { get }
    var content: T? { get }
}