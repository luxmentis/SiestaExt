import Siesta
import Foundation

public protocol TypedResourceProtocol<T> {
    associatedtype T
    var resource: Resource { get }
    var content: T? { get }
}