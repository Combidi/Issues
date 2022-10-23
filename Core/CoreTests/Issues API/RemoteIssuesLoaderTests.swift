//
//  Created by Peter Combee on 23/10/2022.
//

import XCTest

final class RemoteIssuesLoader {
    private let client: Client
    private let url: URL
    
    init(client: Client, url: URL) {
        self.client = client
        self.url = url
    }
    
    func loadIssues() throws {
        try client.get(from: url)
    }
}

final class Client {
    var loadedURLs = [URL]()
    var stub: Error?
        
    func get(from url: URL) throws {
        loadedURLs.append(url)
        if let stub {
            throw stub
        }
    }
}

class RemoteIssuesLoaderTests: XCTestCase {
    
    func test_loadIssues_requestsIssuesFromClient() throws {
        let url = URL(string: "https://a-url.com")!
        let (sut, client) = makeSUT(url: url)
        
        try sut.loadIssues()
        
        XCTAssertEqual(client.loadedURLs, [url])
    }
    
    func test_loadIssuesTwice_requestsIssuesFromClientTwice() throws {
        let url = URL(string: "https://a-url.com")!
        let (sut, client) = makeSUT(url: url)
        
        try sut.loadIssues()
        try sut.loadIssues()
        
        XCTAssertEqual(client.loadedURLs, [url, url])
    }
    
    func test_loadIssues_deliversErrorOnClientError() {
        let (sut, client) = makeSUT()
        let clientError = NSError(domain: "any", code: 1)
        client.stub = clientError
    
        XCTAssertThrowsError(try sut.loadIssues())
    }
    
    // MARK: Helpers
    
    private func makeSUT(url: URL = URL(string: "https://any-url.com")!) -> (sut: RemoteIssuesLoader, client: Client) {
        let client = Client()
        let sut = RemoteIssuesLoader(client: client, url: url)
        return (sut, client)
    }
}
