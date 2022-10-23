//
//  Created by Peter Combee on 23/10/2022.
//

import XCTest
import Core

class RemoteIssuesLoaderTests: XCTestCase {
        
    func test_loadIssuesTwice_requestsIssuesFromClientTwice() {
        let url = URL(string: "https://a-url.com")!
        let (sut, client) = makeSUT(url: url)
        
        sut.loadIssues { _ in }
        sut.loadIssues { _ in }
        
        XCTAssertEqual(client.loadedURLs, [url, url])
    }
    
    func test_loadIssues_deliversErrorOnClientError() {
        let (sut, client) = makeSUT()
        let clientError = NSError(domain: "a domain", code: 1)

        assertThat(sut, completesWith: .failure(clientError), when: {
            client.complete(with: clientError)
        })        
    }

    func test_loadIssues_deliverErrorOnEmptyData() {
        let (sut, client) = makeSUT()
        let emptyData = Data()

        assertThat(sut, completesWithErrorWhen: {
            client.complete(with: success(emptyData))
        })
    }

    func test_loadIssues_deliverEmptyListOnValidDataWithEmptyIssuesList() {
        let (sut, client) = makeSUT()
        
        assertThat(sut, completesWith: .success([]), when: {
            client.complete(with: success(emptyListData()))
        })
    }
    
    func test_loadIssues_deliversErrorOnInvalidJSON() {
        let (sut, client) = makeSUT()
        let invalidData = Data("non json data".utf8)

        assertThat(sut, completesWithErrorWhen: {
            client.complete(with: success(invalidData))
        })
    }
    
    func test_loadIssues_deliversErrorOnNon200HTTPStatusCodeWithValidData() {
        let (sut, client) = makeSUT()
        
        let samples = [199, 201, 300, 500]
        samples.enumerated().forEach { index, statusCode in
            
            assertThat(sut, completesWithErrorWhen: {
                client.complete(with: success(emptyListData(), statusCode: statusCode), atIndex: index)
            })
        }
    }
    
    func test_loadIssues_deliversIssuesOnValidNonEmptyIssuesList() {
        let (sut, client) = makeSUT()
        
        let issue1 = makeIssue(
            firstName: "Peter",
            surname: "Combee",
            submissionDate: (date: Date(timeIntervalSince1970: 1598627222), iso8601String: "2020-08-28T15:07:02+00:00"),
            subject: "A subject"
        )
        
        let issue2 = makeIssue(
            firstName: "Luna",
            surname: "Combee",
            submissionDate: (date: Date(timeIntervalSince1970: 1577881882), iso8601String: "2020-01-01T12:31:22+00:00"),
            subject: "Another subject"
        )
        
        let jsonData = makeIssuesJSON(issues: [issue1.json, issue2.json])

        assertThat(sut, completesWith: .success([issue1.model, issue2.model]), when: {
            client.complete(with: success(jsonData))
        })
    }

    // MARK: Helpers
    
    final class ClientSpy: HTTPClient {
        typealias Result = HTTPClient.Result
        
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
    
    private func makeSUT(url: URL? = nil) -> (sut: RemoteIssuesLoader, client: ClientSpy) {
        let client = ClientSpy()
        let sut = RemoteIssuesLoader(client: client, url: url ?? anyURL())
        return (sut, client)
    }
    
    private func assertThat(
        _ sut: RemoteIssuesLoader,
        completesWith expectedResult: Result<[Issue], Error>,
        when action: () -> Void,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let receivedResult = loadResult(sut, action, file: file, line: line)
        
        switch (receivedResult, expectedResult) {
        case let (.success(receivedIssues), .success(expectedIssues)):
            XCTAssertEqual(receivedIssues, expectedIssues, file: file, line: line)
        
        case let (.failure(receivedError as NSError), .failure(expectedError as NSError)):
            XCTAssertEqual(receivedError, expectedError, file: file, line: line)
        
        default:
            XCTFail("Expected \(expectedResult), got \(String(describing: receivedResult)) instead", file: file, line: line)
            
        }
    }
    
    private func assertThat(
        _ sut: RemoteIssuesLoader,
        completesWithErrorWhen action: () -> Void,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let receivedResult = loadResult(sut, action, file: file, line: line)

        switch receivedResult {
        case .failure:
            return
            
        default:
            XCTFail("Expected to throw an error, got: \(String(describing: receivedResult)) instead", file: file, line: line)
        }
    }
    
    private func loadResult(
        _ sut: RemoteIssuesLoader,
        _ action: () -> Void,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> Result<[Issue], Error>? {
        var receivedResult: Result<[Issue], Error>?
        let exp = expectation(description: "Wait for load completion")
        sut.loadIssues { result in
            receivedResult = result
            exp.fulfill()
        }
        
        action()
        wait(for: [exp], timeout: 1.0)
        return receivedResult
    }
    
    private func makeIssuesJSON(issues: [[String: Any]]) -> Data {
        let json = ["issues": issues]
        return try! JSONSerialization.data(withJSONObject: json)
    }
    
    private func makeIssue(
        firstName: String,
        surname: String,
        submissionDate: (date: Date, iso8601String: String),
        subject: String
    ) -> (model: Issue, json: [String: Any]) {
        let model = Issue(
            firstName: firstName,
            surname: surname,
            submissionDate: submissionDate.date,
            subject: subject
        )
        
        let json: [String: Any] = [
            "customer": [
                "first_name": firstName,
                "last_name": surname
            ],
            "created_at": submissionDate.iso8601String,
            "message": [
                "subject": subject
            ]
        ]
        
        return (model, json)
    }
    
    private func success(_ data: Data, statusCode: Int = 200) -> Result<(Data, HTTPURLResponse), Error> {
        return .success((data, HTTPURLResponse(url: anyURL(), statusCode: statusCode, httpVersion: nil, headerFields: nil)!))
    }
    
    private func anyURL() -> URL {
        URL(string: "http://any-url.com")!
    }
    
    private func emptyListData() -> Data {
        makeIssuesJSON(issues: [])
    }
}
