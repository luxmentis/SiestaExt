import Siesta
import Foundation

public extension Resource {

    // Request with a json request body. Nothing to do with Combine, but everyone needs this.
    func request<T>(_ method: Siesta.RequestMethod, json: T, jsonEncoder: JSONEncoder = JSONEncoder(), requestMutation: @escaping Siesta.Resource.RequestMutation = { _ in }) throws -> Request where T: Encodable {
        let data = try jsonEncoder.encode(json)
        return request(method, data: data, contentType: "application/json", requestMutation: requestMutation)
    }
}