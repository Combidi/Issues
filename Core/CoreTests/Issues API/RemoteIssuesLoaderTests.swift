//
//  Created by Peter Combee on 23/10/2022.
//

import XCTest
import Core

final class RemoteIssuesLoader {
    struct InvalidDataError: Swift.Error {}
        
    private let client: Client
    private let url: URL
    
    init(client: Client, url: URL) {
        self.client = client
        self.url = url
    }
    
    func loadIssues() throws -> [Issue] {
        let result = try client.get(from: url)
        if result.1.statusCode != 200 {
            throw InvalidDataError()
        }
        if result.0.isEmpty {
            throw InvalidDataError()
        } else {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let issues = try decoder.decode(Issues.self, from: result.0)
            return issues.toDomain()
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
                return Issue(
                    firstName: $0.customer.first_name,
                    surname: $0.customer.last_name,
                    submissionDate: $0.created_at,
                    subject: $0.message.subject
                )
            }
        }
    }
}

final class Client {
    var loadedURLs = [URL]()
    var stub: Result<(Data, HTTPURLResponse), Error> = .failure(NSError(domain: "any", code: 1))
        
    func get(from url: URL) throws -> (Data, HTTPURLResponse) {
        loadedURLs.append(url)
        switch stub {
        case let .success(data):
            return data
        case let .failure(error):
            throw error
        }
    }
}

class RemoteIssuesLoaderTests: XCTestCase {
    
    func test_loadIssues_requestsIssuesFromClient() {
        let url = URL(string: "https://a-url.com")!
        let (sut, client) = makeSUT(url: url)
        
        _ = try? sut.loadIssues()
        
        XCTAssertEqual(client.loadedURLs, [url])
    }
    
    func test_loadIssuesTwice_requestsIssuesFromClientTwice() {
        let url = URL(string: "https://a-url.com")!
        let (sut, client) = makeSUT(url: url)
        
        _ = try? sut.loadIssues()
        _ = try? sut.loadIssues()
        
        XCTAssertEqual(client.loadedURLs, [url, url])
    }
    
    func test_loadIssues_deliversErrorOnClientError() {
        let (sut, client) = makeSUT()
        let clientError = NSError(domain: "a domain", code: 1)
        client.stub = .failure(clientError)
            
        XCTAssertThrowsError(try sut.loadIssues())
    }
        
    func test_loadIssues_deliverErrorOnEmptyData() {
        let (sut, client) = makeSUT()
        let emptyData = Data()
        client.stub = success(emptyData)
    
        XCTAssertThrowsError(try sut.loadIssues())
    }

    func test_loadIssues_deliverEmptyListOnValidDataWithEmptyIssuesList() {
        let (sut, client) = makeSUT()
        client.stub = success(emptyListData())
    
        XCTAssertEqual(try sut.loadIssues(), [])
    }
    
    func test_loadIssues_deliversErrorOnInvalidJSON() {
        let (sut, client) = makeSUT()
        let invalidData = Data("non json data".utf8)
        client.stub = success(invalidData)

        XCTAssertThrowsError(try sut.loadIssues())
    }
    
    func test_loadIssues_throwsOnNon200HTTPStatusCodeWithValidData() throws {
        let (sut, client) = makeSUT()
        let samples = [199, 201, 300, 500]
        
        try samples.forEach { statusCode in
            client.stub = success(emptyListData(), statusCode: statusCode)
            
            XCTAssertThrowsError(try sut.loadIssues(), "for status code: \(statusCode)")
        }
    }
    
    func test_loadIssues_deliversIssuesOnValidNonEmptyIssuesList() {
        
        let validNonEmptyIssuesData = Data("""
        {
            "issues": [
                {
                    "customer": {
                        "first_name": "Peter",
                        "last_name": "Combee"
                    },
                    "created_at": "2020-08-28T15:07:02+00:00",
                    "message": {
                        "subject": "A subject"
                    }
                },
                {
                    "customer": {
                        "first_name": "Luna",
                        "last_name": "Combee"
                    },
                    "created_at": "2020-01-01T12:31:22+00:00",
                    "message": {
                        "subject": "Another subject"
                    }
                }
            ]
        }
        """.utf8)
        
        let expected = [
            Issue(firstName: "Peter", surname: "Combee", submissionDate: Date(timeIntervalSince1970: 1598627222), subject: "A subject"),
            Issue(firstName: "Luna", surname: "Combee", submissionDate: Date(timeIntervalSince1970: 1577881882), subject: "Another subject"),
        ]
        
        let (sut, client) = makeSUT()
        client.stub = success(validNonEmptyIssuesData)
        
        XCTAssertEqual(try sut.loadIssues(), expected)
    }

    // MARK: Helpers
    
    private func makeSUT(url: URL? = nil) -> (sut: RemoteIssuesLoader, client: Client) {
        let client = Client()
        let sut = RemoteIssuesLoader(client: client, url: url ?? anyURL())
        return (sut, client)
    }
    
    private func success(_ data: Data, statusCode: Int = 200) -> Result<(Data, HTTPURLResponse), Error> {
        return .success((data, HTTPURLResponse(url: anyURL(), statusCode: statusCode, httpVersion: nil, headerFields: nil)!))
    }
    
    private func anyURL() -> URL {
        URL(string: "http://any-url.com")!
    }
    
    private func emptyListData() -> Data {
        Data("""
        {
            "issues": []
        }
        """.utf8)
    }
}
