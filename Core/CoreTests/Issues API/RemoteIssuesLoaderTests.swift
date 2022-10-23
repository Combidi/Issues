//
//  Created by Peter Combee on 23/10/2022.
//

import XCTest
import Core

final class RemoteIssuesLoader {
    struct InvalidDataError: Swift.Error {}
        
    private let client: HTTPClient
    private let url: URL
    
    init(client: HTTPClient, url: URL) {
        self.client = client
        self.url = url
    }
    
    func loadIssues(completion: @escaping (Result<[Issue], Error>) -> Void) {
        client.get(from: url) { result in
            switch result {
            case let .success((data, response)):
                guard response.statusCode == 200, !data.isEmpty else {
                    return completion(.failure(InvalidDataError()))
                }
                completion(Result { try Self.map(data: data, response: response) })

            case let .failure(error):
                completion(.failure(error))
            }
        }
    }

    private static func map(data: Data, response: HTTPURLResponse) throws -> [Issue] {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(Issues.self, from: data).toDomain()
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
}

protocol HTTPClient {
    typealias Result = Swift.Result<(Data, HTTPURLResponse), Error>

    func get(from url: URL, completion: @escaping (Result) -> Void)
}

final class ClientSpy: HTTPClient {
    typealias Result = Swift.Result<(Data, HTTPURLResponse), Error>
    
    private var messages = [(URL, (Result) -> Void)]()
    private var completions: [(Result) -> Void] { messages.map(\.1) }
    
    var loadedURLs: [URL] { messages.map(\.0) }
         
    func get(from url: URL, completion: @escaping (Result) -> Void) {
        messages.append((url, completion))
    }
    
    func complete(with error: NSError, atIndex index: Int = 0) {
        complete(with: .failure(error))
    }
    
    func complete(with result: Result, atIndex index: Int = 0) {
        completions[index](result)
    }
}

class RemoteIssuesLoaderTests: XCTestCase {
    
    func test_loadIssues_requestsIssuesFromClient() {
        let url = URL(string: "https://a-url.com")!
        let (sut, client) = makeSUT(url: url)
        
        sut.loadIssues { _ in }
        
        XCTAssertEqual(client.loadedURLs, [url])
    }
    
    func test_loadIssuesTwice_requestsIssuesFromClientTwice() {
        let url = URL(string: "https://a-url.com")!
        let (sut, client) = makeSUT(url: url)
        
        sut.loadIssues { _ in }
        sut.loadIssues { _ in }
        
        XCTAssertEqual(client.loadedURLs, [url, url])
    }
    
    func test_loadIssues_deliversErrorOnClientError() {
        let (sut, client) = makeSUT()
            
        var receivedError: NSError?
        let exp = expectation(description: "Wait for load completion")
        sut.loadIssues { result in
            if case let .failure(error) = result {
                receivedError = error as NSError
            }
            exp.fulfill()
        }
        
        let clientError = NSError(domain: "a domain", code: 1)
        client.complete(with: clientError)

        wait(for: [exp], timeout: 1.0)
        XCTAssertEqual(receivedError, clientError)
    }
        
    func test_loadIssues_deliverErrorOnEmptyData() {
        let (sut, client) = makeSUT()

        var receivedError: NSError?
        let exp = expectation(description: "Wait for load completion")
        sut.loadIssues { result in
            if case let .failure(error) = result {
                receivedError = error as NSError
            }
            exp.fulfill()
        }
        
        let emptyData = Data()
        client.complete(with: success(emptyData))
        
        wait(for: [exp], timeout: 1.0)
        XCTAssertNotNil(receivedError)
    }

    func test_loadIssues_deliverEmptyListOnValidDataWithEmptyIssuesList() {
        let (sut, client) = makeSUT()
    
        var receivedIssues: [Issue]?
        let exp = expectation(description: "Wait for load completion")
        sut.loadIssues { result in
            if case let .success(issues) = result {
                receivedIssues = issues
            }
            exp.fulfill()
        }
        
        client.complete(with: success(emptyListData()))
        
        wait(for: [exp], timeout: 1.0)
        XCTAssertEqual(receivedIssues, [])
    }
    
    func test_loadIssues_deliversErrorOnInvalidJSON() {
        let (sut, client) = makeSUT()
        let invalidData = Data("non json data".utf8)

        var receivedError: NSError?
        let exp = expectation(description: "Wait for load completion")
        sut.loadIssues { result in
            if case let .failure(error) = result {
                receivedError = error as NSError
            }
            exp.fulfill()
        }
        
        client.complete(with: success(invalidData))
        
        wait(for: [exp], timeout: 1.0)
        XCTAssertNotNil(receivedError)
    }
    
    func test_loadIssues_deliversErrorOnNon200HTTPStatusCodeWithValidData() {
        let (sut, client) = makeSUT()
        
        let samples = [199, 201, 300, 500]
        samples.enumerated().forEach { index, statusCode in
            
            var receivedError: NSError?
            let exp = expectation(description: "Wait for load completion")
            sut.loadIssues { result in
                if case let .failure(error) = result {
                    receivedError = error as NSError
                }
                exp.fulfill()
            }

            client.complete(with: success(emptyListData(), statusCode: statusCode), atIndex: index)
            
            wait(for: [exp], timeout: 1.0)
            XCTAssertNotNil(receivedError, "for status code: \(statusCode)")
        }
    }
    
    func test_loadIssues_deliversIssuesOnValidNonEmptyIssuesList() {
        let (sut, client) = makeSUT()
        
        var receivedIssues: [Issue]?
        let exp = expectation(description: "Wait for load completion")
        sut.loadIssues { result in
            if case let .success(issues) = result {
                receivedIssues = issues
            }
            exp.fulfill()
        }
        
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

        client.complete(with: success(validNonEmptyIssuesData))

        wait(for: [exp], timeout: 1.0)
        let expected = [
            Issue(firstName: "Peter", surname: "Combee", submissionDate: Date(timeIntervalSince1970: 1598627222), subject: "A subject"),
            Issue(firstName: "Luna", surname: "Combee", submissionDate: Date(timeIntervalSince1970: 1577881882), subject: "Another subject"),
        ]
        XCTAssertEqual(receivedIssues, expected)
    }

    // MARK: Helpers
    
    private func makeSUT(url: URL? = nil) -> (sut: RemoteIssuesLoader, client: ClientSpy) {
        let client = ClientSpy()
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
