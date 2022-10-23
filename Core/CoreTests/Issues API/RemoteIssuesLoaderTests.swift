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
        
        let expected = [
            Issue(firstName: "Peter", surname: "Combee", submissionDate: Date(timeIntervalSince1970: 1598627222), subject: "A subject"),
            Issue(firstName: "Luna", surname: "Combee", submissionDate: Date(timeIntervalSince1970: 1577881882), subject: "Another subject")
        ]

        assertThat(sut, completesWith: .success(expected), when: {
            
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
