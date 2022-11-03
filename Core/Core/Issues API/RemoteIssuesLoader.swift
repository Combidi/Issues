//
//  Created by Peter Combee on 23/10/2022.
//

import Foundation

public final class RemoteIssuesLoader: IssuesLoader {
    
    struct InvalidDataError: Swift.Error {}
        
    private let client: HTTPClient
    private let url: URL
    
    public init(client: HTTPClient, url: URL) {
        self.client = client
        self.url = url
    }
    
    typealias Result = LoadIssuesResult
    
    public func loadIssues(completion: @escaping Completion) {
        client.get(from: url) { result in
            switch result {
            case let .success((data, response)):
                completion(Self.map(data, from: response))

            case let .failure(error):
                completion(.failure(error))
            }
        }
    }
    
    static private func map(_ data: Data, from response: HTTPURLResponse) -> Result {
        guard response.statusCode == 200, !data.isEmpty else {
            return .failure(InvalidDataError())
        }
        return Result { try IssuesMapper.map(data: data, response: response) }
    }
}
