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

private enum IssuesMapper {
    private struct Issues: Decodable {
        struct Customer: Decodable {
            let first_name: String
            let last_name: String
        }
        
        struct Message: Decodable {
            let subject: String
        }
        
        struct Item: Decodable {
            let customer: Customer
            let created_at: Date
            let message: Message
        }
        
        let issues: [Item]
        
        func toDomain() -> [Issue] {
            issues.map {
                Issue(
                    firstName: $0.customer.first_name,
                    surname: $0.customer.last_name,
                    submissionDate: $0.created_at,
                    subject: $0.message.subject
                )
            }
        }
    }

    static func map(data: Data, response: HTTPURLResponse) throws -> [Issue] {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(Issues.self, from: data).toDomain()
    }
}
