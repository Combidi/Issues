//
//  Created by Peter Combee on 23/10/2022.
//

import Foundation

enum IssuesMapper {
    static func map(data: Data, response: HTTPURLResponse) throws -> [Issue] {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(Issues.self, from: data).toDomain()
    }
}

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
