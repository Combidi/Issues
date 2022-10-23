//
//  Created by Peter Combee on 23/10/2022.
//

import Foundation

public final class RemoteIssuesLoader {
    struct InvalidDataError: Swift.Error {}
        
    private let client: HTTPClient
    private let url: URL
    
    public init(client: HTTPClient, url: URL) {
        self.client = client
        self.url = url
    }
    
    public func loadIssues(completion: @escaping (Result<[Issue], Error>) -> Void) {
        client.get(from: url) { result in
            switch result {
            case let .success((data, response)):
                guard response.statusCode == 200, !data.isEmpty else {
                    return completion(.failure(InvalidDataError()))
                }
                completion(Result { try IssuesMapper.map(data: data, response: response) })

            case let .failure(error):
                completion(.failure(error))
            }
        }
    }
}
