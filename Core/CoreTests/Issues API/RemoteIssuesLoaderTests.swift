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
    
    init(stub: Error? = nil) {
        self.stub = stub
    }
    
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
        let client = Client()
        let sut = RemoteIssuesLoader(client: client, url: url)
        
        try sut.loadIssues()
        
        XCTAssertEqual(client.loadedURLs, [url])
    }
    
    func test_loadIssuesTwice_requestsIssuesFromClientTwice() throws {
        let url = URL(string: "https://a-url.com")!
        let client = Client()
        let sut = RemoteIssuesLoader(client: client, url: url)
        
        try sut.loadIssues()
        try sut.loadIssues()
        
        XCTAssertEqual(client.loadedURLs, [url, url])
    }
    
    func test_loadIssues_deliversErrorOnClientError() {
        let anyURL = URL(string: "https://a-url.com")!
        let clientError = NSError(domain: "any", code: 1)
        let client = Client(stub: clientError)
        let sut = RemoteIssuesLoader(client: client, url: anyURL)
    
        XCTAssertThrowsError(try sut.loadIssues())
    }
}
