//
//  Created by Peter Combee on 27/10/2022.
//

import Foundation

public final class URLSessionHTTPClient: HTTPClient {
    private let session: URLSession
    
    public init(session: URLSession) {
        self.session = session
    }
    
    private struct UnexpectedValuesRepresentation: Error {}
    
    public func get(from url: URL, completion: @escaping (HTTPClient.Result) -> Void) {
        session.dataTask(with: url) { data, response, error in
            completion(Result {
                if let error { throw error }
                if let data = data, let response = response as? HTTPURLResponse {
                    return (data, response)
                }
                throw UnexpectedValuesRepresentation()
            })
        }.resume()
    }
}
